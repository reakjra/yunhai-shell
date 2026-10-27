import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono.shelf.widgets.controlPanel

HeroCard {
    id: root

    readonly property var network: Network.active
    readonly property bool connected: root.network !== null
    readonly property bool connecting: Network.wifiStatus === "connecting"
    readonly property bool showsBars: root.connected || root.connecting
    readonly property int bars: Network.strengthBars(Network.networkStrength)
    property int shownBars: 0
    property bool ipCopied: false

    signal forgetRequested(var network)
    signal dnsRequested()

    readonly property string dnsLabel: {
        if (Network.customDns.length === 0)
            return Translation.tr("Automatic");
        return Network.dnsPresetFor(Network.customDns)?.name ?? Translation.tr("Custom");
    }

    function sweep() {
        root.shownBars = 0;
        sweepTimer.restart();
    }

    Component.onCompleted: root.sweep()
    onConnectedChanged: root.sweep()
    onConnectingChanged: root.sweep()

    title: {
        if (!Network.wifiEnabled)
            return Translation.tr("Wi-Fi is off");
        if (root.connected)
            return root.network.name;
        if (root.connecting)
            return Translation.tr("Connecting...");
        return Translation.tr("Not connected");
    }
    subtitle: {
        if (!Network.wifiEnabled)
            return Translation.tr("Turn it on to look for networks");
        if (root.connected)
            return Network.wifiStatus === "limited" ? Translation.tr("Connected, limited connectivity") : Translation.tr("Connected");
        if (root.connecting)
            return Network.connectTarget?.name ?? "";
        return Translation.tr("Pick a network below");
    }
    switchChecked: Network.wifiEnabled
    onSwitchToggled: checked => Network.enableWifi(checked)

    glyph: [
        MaterialSymbol {
            anchors.centerIn: parent
            visible: root.showsBars
            text: "signal_wifi_4_bar"
            iconSize: root.glyphSize
            fill: 1
            color: Qt.alpha(Appearance.colors.colOnPrimaryContainer, 0.25)
        },
        MaterialSymbol {
            anchors.centerIn: parent
            text: root.showsBars ? Network.barsSymbol(sweepTimer.running ? root.shownBars : root.bars) : Network.materialSymbol
            iconSize: root.glyphSize
            fill: 1
            color: Appearance.colors.colOnPrimaryContainer
        }
    ]

    actions: [
        ActionButton {
            visible: root.connected
            size: Appearance.font.pixelSize.huge * 1.7
            icon: "link_off"
            tooltip: Translation.tr("Disconnect")
            onClicked: Network.disconnectWifiNetwork()
        },
        ActionButton {
            visible: root.connected
            size: Appearance.font.pixelSize.huge * 1.7
            icon: "delete"
            tooltip: Translation.tr("Forget this network")
            onClicked: root.forgetRequested(root.network)
        }
    ]

    Timer {
        id: ipCopiedTimer
        interval: 1500
        onTriggered: root.ipCopied = false
    }

    Timer {
        id: sweepTimer
        interval: 160
        repeat: true
        onTriggered: {
            if (root.shownBars < (root.connecting ? 4 : root.bars)) {
                root.shownBars++;
                return;
            }
            if (root.connecting) {
                root.shownBars = 0;
                return;
            }
            stop();
        }
    }

    Loader {
        Layout.fillWidth: true
        active: root.connected

        sourceComponent: Flow {
            spacing: 6

            Pill {
                icon: Network.isSecure(root.network) ? "lock" : "lock_open"
                text: Network.isSecure(root.network) ? Network.securityLabel(root.network) : Translation.tr("Open")
            }
            Pill {
                icon: "network_wifi"
                text: `${Network.networkStrength}%`
                sizingText: "100%"
            }
            Pill {
                visible: Network.ipAddress !== ""
                clickable: true
                icon: root.ipCopied ? "check" : "lan"
                text: Network.ipAddress
                tooltip: root.ipCopied ? Translation.tr("Copied") : Translation.tr("Copy to clipboard")
                onClicked: {
                    Quickshell.clipboardText = Network.ipAddress;
                    root.ipCopied = true;
                    ipCopiedTimer.restart();
                }
            }
            Pill {
                visible: Network.gateway !== ""
                clickable: true
                icon: "router"
                text: Network.gateway
                tooltip: Translation.tr("Open your router's admin page")
                onClicked: Qt.openUrlExternally(`http://${Network.gateway}`)
            }
            Pill {
                visible: Network.connectionName !== ""
                clickable: true
                icon: "dns"
                text: Translation.tr("DNS · %1").arg(root.dnsLabel)
                tooltip: Translation.tr("Change DNS servers")
                onClicked: root.dnsRequested()
            }
        }
    }
}
