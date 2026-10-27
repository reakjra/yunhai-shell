pragma Singleton
pragma ComponentBehavior: Bound

// Took many bits from https://github.com/caelestia-dots/shell (GPLv3)

import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick

Singleton {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property WifiDevice wifiDevice: root.devices.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property WiredDevice wiredDevice: root.devices.find(d => d.type === DeviceType.Wired) ?? null

    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool ethernet: root.wiredDevice?.connected ?? false

    readonly property list<WifiNetwork> wifiNetworks: root.wifiDevice?.networks.values ?? []
    readonly property WifiNetwork active: root.wifiNetworks.find(n => n.connected) ?? null
    readonly property var friendlyWifiNetworks: [...root.wifiNetworks].sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength) || a.name.localeCompare(b.name))
    readonly property bool wifiScanPending: (root.wifiDevice?.scannerEnabled ?? false) && !root.wifiNetworks.some(n => !n.connected)

    property WifiNetwork passwordTarget: null
    property WifiNetwork connectTarget: null
    property string connectError: ""

    readonly property bool hiddenConnecting: hiddenConnectProc.running

    property string ipAddress: ""
    property string gateway: ""
    property string connectionName: ""
    property var dnsServers: []
    property var customDns: []
    property bool ipv6Enabled: false
    property string dnsError: ""
    readonly property bool dnsApplying: dnsApplyProc.running
    readonly property var dnsPresets: [
        { name: "Cloudflare", servers: ["1.1.1.1", "1.0.0.1", "2606:4700:4700::1111", "2606:4700:4700::1001"] },
        { name: "Quad9", servers: ["9.9.9.9", "149.112.112.112", "2620:fe::fe", "2620:fe::9"] },
        { name: "Google", servers: ["8.8.8.8", "8.8.4.4", "2001:4860:4860::8888", "2001:4860:4860::8844"] }
    ]

    signal hiddenConnectFinished(bool succeeded)
    signal dnsApplyFinished(bool succeeded)

    readonly property int networkStrength: root.strengthPercent(root.active)
    readonly property string networkName: root.ethernet ? (root.wiredDevice.network?.name ?? "") : (root.active?.name ?? "")

    readonly property string wifiStatus: {
        if (!root.wifiEnabled)
            return "disabled";
        if (root.wifiNetworks.some(n => n.state === ConnectionState.Connecting))
            return "connecting";
        if (!root.active)
            return "disconnected";
        if (Networking.connectivity === NetworkConnectivity.Limited || Networking.connectivity === NetworkConnectivity.Portal)
            return "limited";
        return "connected";
    }

    readonly property string materialSymbol: {
        if (root.ethernet)
            return "lan";
        switch (root.wifiStatus) {
        case "connected":
            return root.strengthSymbol(root.networkStrength);
        case "connecting":
            return "signal_wifi_statusbar_not_connected";
        case "disconnected":
            return "wifi_find";
        case "disabled":
            return "signal_wifi_off";
        default:
            return "signal_wifi_bad";
        }
    }

    property var _scanConsumers: new Set()
    property int _scanDemand: 0

    function strengthPercent(network): int {
        return Math.round((network?.signalStrength ?? 0) * 100);
    }

    function strengthBars(percent: int): int {
        return percent > 80 ? 4 : percent > 60 ? 3 : percent > 40 ? 2 : percent > 20 ? 1 : 0;
    }

    function barsSymbol(bars: int): string {
        return ["signal_wifi_0_bar", "network_wifi_1_bar", "network_wifi_2_bar", "network_wifi_3_bar", "signal_wifi_4_bar"][bars];
    }

    function strengthSymbol(percent: int): string {
        return root.barsSymbol(root.strengthBars(percent));
    }

    function isSecure(network): bool {
        return network.security !== WifiSecurityType.Open;
    }

    function securityLabel(network): string {
        return WifiSecurityType.toString(network.security);
    }

    function setScanWanted(obj, on): void {
        if (on)
            root._scanConsumers.add(obj);
        else
            root._scanConsumers.delete(obj);
        root._scanDemand = root._scanConsumers.size;
    }

    function enableWifi(enabled = true): void {
        Networking.wifiEnabled = enabled;
    }

    function toggleWifi(): void {
        root.enableWifi(!root.wifiEnabled);
    }

    function connectToWifiNetwork(network: WifiNetwork): void {
        root.connectError = "";
        if (!network.known && root.isSecure(network)) {
            root.passwordTarget = network;
            return;
        }
        root.connectTarget = network;
        network.connect();
    }

    function connectWithPassword(network: WifiNetwork, password: string): void {
        root.connectError = "";
        root.passwordTarget = null;
        root.connectTarget = network;
        network.connectWithPsk(password);
    }

    function connectToHiddenNetwork(ssid: string, password: string): void {
        root.connectError = "";
        hiddenConnectProc.exec(["nmcli", "device", "wifi", "connect", ssid, "hidden", "yes", ...(password ? ["password", password] : [])]);
    }

    function forgetWifiNetwork(network: WifiNetwork): void {
        network.forget();
    }

    function nmcliFields(text: string): list<string> {
        return text.replace(/\n$/, "").replace(/\\:/g, ":").split("\n");
    }

    function isIpv6(server: string): bool {
        return server.includes(":");
    }

    function applicableDns(servers) {
        return root.ipv6Enabled ? servers : servers.filter(server => !root.isIpv6(server));
    }

    function dnsPresetFor(servers) {
        return root.dnsPresets.find(preset => root.applicableDns(preset.servers).join(",") === servers.join(",")) ?? null;
    }

    function setDns(servers): void {
        const device = root.ethernet ? root.wiredDevice : root.wifiDevice;
        if (!device || !root.connectionName)
            return;
        root.dnsError = "";
        const ignoreAuto = servers.length > 0 ? "yes" : "no";
        const settings = ["ipv4.dns", servers.filter(server => !root.isIpv6(server)).join(","), "ipv4.ignore-auto-dns", ignoreAuto];
        if (root.ipv6Enabled)
            settings.push("ipv6.dns", servers.filter(root.isIpv6).join(","), "ipv6.ignore-auto-dns", ignoreAuto);
        dnsApplyProc.exec(["sh", "-c", 'device="$1"; shift; nmcli connection modify "$@" && nmcli device reapply "$device"', "sh", device.name, root.connectionName, ...settings]);
    }

    function refreshAddresses(): void {
        const device = root.ethernet ? root.wiredDevice : root.wifiDevice;
        if (!device || !root.networkName) {
            root.ipAddress = "";
            root.gateway = "";
            root.connectionName = "";
            root.dnsServers = [];
            root.customDns = [];
            return;
        }
        addressProc.exec(["nmcli", "-g", "IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.DNS,GENERAL.CONNECTION", "device", "show", device.name]);
    }

    function cancelPassword(): void {
        root.passwordTarget = null;
    }

    function disconnectWifiNetwork(): void {
        root.active?.disconnect();
    }

    function openPublicWifiPortal() {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]) // From some StackExchange thread, seems to work
    }

    onNetworkNameChanged: root.refreshAddresses()

    Process {
        id: addressProc
        stdout: StdioCollector {
            onStreamFinished: {
                const [addresses = "", gateway = "", dns4 = "", dns6 = "", connection = ""] = root.nmcliFields(text);
                root.ipAddress = addresses.split(" | ")[0].split("/")[0];
                root.gateway = gateway;
                root.dnsServers = [...dns4.split(" | "), ...dns6.split(" | ")].filter(server => server !== "");
                root.connectionName = connection;
                if (connection)
                    dnsConfigProc.exec(["nmcli", "-g", "ipv4.dns,ipv6.dns,ipv6.method", "connection", "show", connection]);
            }
        }
    }

    Process {
        id: dnsConfigProc
        stdout: StdioCollector {
            onStreamFinished: {
                const [dns4 = "", dns6 = "", method6 = ""] = root.nmcliFields(text);
                root.ipv6Enabled = method6 !== "disabled" && method6 !== "ignore";
                root.customDns = [...dns4.split(","), ...dns6.split(",")].filter(server => server !== "");
            }
        }
    }

    Process {
        id: dnsApplyProc
        stderr: StdioCollector {
            onStreamFinished: root.dnsError = text.trim()
        }
        onExited: exitCode => {
            root.refreshAddresses();
            root.dnsApplyFinished(exitCode === 0);
        }
    }

    Process {
        id: hiddenConnectProc
        stderr: StdioCollector {
            onStreamFinished: root.connectError = text.trim()
        }
        onExited: exitCode => root.hiddenConnectFinished(exitCode === 0)
    }

    Binding {
        target: root.wifiDevice
        property: "scannerEnabled"
        value: root._scanDemand > 0
        when: root.wifiDevice !== null
    }

    Connections {
        target: root.connectTarget

        function onConnectionFailed(reason) {
            root.connectError = ConnectionFailReason.toString(reason);
            if (reason === ConnectionFailReason.NoSecrets)
                root.passwordTarget = root.connectTarget;
            root.connectTarget = null;
        }

        function onConnectedChanged() {
            if (root.connectTarget.connected)
                root.connectTarget = null;
        }
    }
}
