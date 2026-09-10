pragma Singleton

import qs.services
import qs.modules.common
import Quickshell
import Quickshell.Services.UPower
import QtQuick
import Quickshell.Io

Singleton {
    id: root
    property bool available: UPower.displayDevice.isLaptopBattery
    property var chargeState: UPower.displayDevice.state
    property bool isCharging: chargeState == UPowerDeviceState.Charging
    property bool isPluggedIn: isCharging || chargeState == UPowerDeviceState.PendingCharge
    property real percentage: UPower.displayDevice?.percentage ?? 1
    readonly property bool allowAutomaticSuspend: Config.options.battery.automaticSuspend
    readonly property bool soundEnabled: Config.options.sounds.battery

    property bool isLow: available && (percentage <= Config.options.battery.low / 100)
    property bool isCritical: available && (percentage <= Config.options.battery.critical / 100)
    property bool isSuspending: available && (percentage <= Config.options.battery.suspend / 100)
    property bool isFull: available && (percentage >= Config.options.battery.full / 100)

    property bool isLowAndNotCharging: isLow && !isCharging
    property bool isCriticalAndNotCharging: isCritical && !isCharging
    property bool isSuspendingAndNotCharging: allowAutomaticSuspend && isSuspending && !isCharging
    property bool isFullAndCharging: isFull && isCharging

    property real energyRate: UPower.displayDevice.changeRate
    property real timeToEmpty: UPower.displayDevice.timeToEmpty
    property real timeToFull: UPower.displayDevice.timeToFull

    property real health: (function() {
        const devList = UPower.devices.values;
        for (let i = 0; i < devList.length; ++i) {
            const dev = devList[i];
            if (dev.isLaptopBattery && dev.healthSupported) {
                const health = dev.healthPercentage;
                if (health === 0) {
                    return 0.01;
                } else if (health < 1) {
                    return health * 100;
                } else {
                    return health;
                }
            }
        }
        return 0;
    })()

    function isUsable(device) {
        return device.ready && device.isPresent && device.type !== UPowerDeviceType.LinePower;
    }

    readonly property list<var> devices: UPower.devices.values.filter(device => root.isUsable(device) && !device.isLaptopBattery)
    readonly property list<var> batteries: UPower.devices.values.filter(device => root.isUsable(device))

    property var serials: ({})
    property var notified: ({})

    function notify(title, body, urgent) {
        const args = ["notify-send", title, body, "-a", "Shell", "--hint=int:transient:1"];
        if (urgent)
            args.push("-u", "critical");
        Quickshell.execDetached(args);
    }

    function keyFor(device) {
        const native = device.nativePath;
        const marker = "/power_supply/";
        const at = native.lastIndexOf(marker);
        const serial = root.serials[at >= 0 ? native.substring(at + marker.length) : native];
        return serial ? serial : native;
    }

    function labelFor(device) {
        return device.model.length > 0 ? device.model : Translation.tr("Unknown device");
    }

    function thresholdFor(key) {
        const entries = Config.options.deviceBattery.thresholds;
        for (let i = 0; i < entries.length; ++i) {
            if (entries[i].key === key)
                return entries[i].limit;
        }
        return Config.options.deviceBattery.defaultLow;
    }

    function setThresholdFor(device, limit) {
        const key = root.keyFor(device);
        const entries = Config.options.deviceBattery.thresholds.filter(entry => entry.key !== key);
        entries.push({
            key: key,
            model: root.labelFor(device),
            limit: limit
        });
        Config.options.deviceBattery.thresholds = entries;
        if (device.percentage > limit / 100)
            root.notified[key] = false;
        root.evaluateDevice(device);
    }

    function isDeviceCharging(device) {
        return device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge;
    }

    function evaluateDevice(device) {
        if (!Config.options.deviceBattery.notifyLow)
            return;
        const key = root.keyFor(device);
        const limit = root.thresholdFor(key);
        if (limit <= 0)
            return;
        if (root.isDeviceCharging(device)) {
            root.notified[key] = false;
            return;
        }
        if (device.percentage > limit / 100 || root.notified[key])
            return;
        root.notified[key] = true;
        root.notify(Translation.tr("%1 battery low").arg(root.labelFor(device)), Translation.tr("%1% remaining").arg(Math.round(device.percentage * 100)), true);
        if (root.soundEnabled)
            Audio.playSystemSound("dialog-warning");
    }

    function armDevice(device) {
        const key = root.keyFor(device);
        root.notified[key] = device.percentage <= root.thresholdFor(key) / 100;
    }

    onDevicesChanged: readSerials.running = true

    Process {
        id: readSerials
        running: true
        command: ["bash", "-c", "for dir in /sys/class/power_supply/*/; do name=${dir%/}; printf '%s=%s\\n' \"${name##*/}\" \"$(cat \"$dir/serial_number\" 2>/dev/null)\"; done"]
        stdout: StdioCollector {
            id: serialCollector
            onStreamFinished: {
                const map = {};
                const lines = serialCollector.text.trim().split("\n");
                for (let i = 0; i < lines.length; ++i) {
                    const at = lines[i].indexOf("=");
                    if (at > 0 && at < lines[i].length - 1)
                        map[lines[i].substring(0, at)] = lines[i].substring(at + 1);
                }
                root.serials = map;
            }
        }
    }

    Variants {
        model: root.devices
        Scope {
            id: deviceScope
            required property var modelData
            readonly property real percentage: deviceScope.modelData.percentage
            readonly property var chargeState: deviceScope.modelData.state
            onPercentageChanged: root.evaluateDevice(deviceScope.modelData)
            onChargeStateChanged: root.evaluateDevice(deviceScope.modelData)
            Component.onCompleted: root.armDevice(deviceScope.modelData)
        }
    }

    onIsLowAndNotChargingChanged: {
        if (!root.available || !isLowAndNotCharging) return;
        root.notify(Translation.tr("Low battery"), Translation.tr("Consider plugging in your device"), true);

        if (root.soundEnabled) Audio.playSystemSound("dialog-warning");
    }

    onIsCriticalAndNotChargingChanged: {
        if (!root.available || !isCriticalAndNotCharging) return;
        root.notify(Translation.tr("Critically low battery"), Translation.tr("Please charge!\nAutomatic suspend triggers at %1%").arg(Config.options.battery.suspend), true);

        if (root.soundEnabled) Audio.playSystemSound("suspend-error");
    }

    onIsSuspendingAndNotChargingChanged: {
        if (root.available && isSuspendingAndNotCharging) {
            Quickshell.execDetached(["bash", "-c", `systemctl suspend || loginctl suspend`]);
        }
    }

    onIsFullAndChargingChanged: {
        if (!root.available || !isFullAndCharging) return;
        root.notify(Translation.tr("Battery full"), Translation.tr("Please unplug the charger"), false);

        if (root.soundEnabled) Audio.playSystemSound("complete");
    }

    onIsPluggedInChanged: {
        if (!root.available || !root.soundEnabled) return;
        if (isPluggedIn) {
            Audio.playSystemSound("power-plug")
        } else {
            Audio.playSystemSound("power-unplug")
        }
    }
}
