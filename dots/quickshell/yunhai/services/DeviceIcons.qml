pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var modelOverrides: [
        {
            pattern: /charging\s*case/i,
            icon: "earbuds-case"
        },
        {
            pattern: /airpod|earbud|\bbuds\b|\bpods\b/i,
            icon: "earbuds"
        },
        {
            pattern: /\bmouse\b|\bmice\b/i,
            icon: "mouse"
        },
        {
            pattern: /\bkeyboard\b|\bkeeb\b/i,
            icon: "keyboard"
        },
        {
            pattern: /controller|gamepad|dualsense|dualshock|joy-?con|\bxbox\b/i,
            icon: "controller"
        },
        {
            pattern: /headset|headphone|\bcans\b/i,
            icon: "headphones"
        },
        {
            pattern: /stylus|\bpen\b|pencil/i,
            icon: "pen"
        }
    ]

    readonly property string folder: Qt.resolvedUrl(Quickshell.shellPath("assets/icons/devices"))

    function pathForName(iconName) {
        return Quickshell.shellPath(`assets/icons/devices/${iconName}.svg`);
    }

    function fileForDevice(device) {
        return `${root.nameForDevice(device)}.svg`;
    }

    function symbolForLevel(percentage, charging, low) {
        if (charging && percentage < 1)
            return "battery_android_bolt";
        if (low)
            return "battery_android_alert";
        const level = Math.round(percentage * 6);
        return level >= 6 ? "battery_android_full" : `battery_android_${level}`;
    }

    function nameForType(type) {
        switch (type) {
        case UPowerDeviceType.Mouse:
        case UPowerDeviceType.Touchpad:
            return "mouse";
        case UPowerDeviceType.Keyboard:
            return "keyboard";
        case UPowerDeviceType.GamingInput:
            return "controller";
        case UPowerDeviceType.Phone:
        case UPowerDeviceType.Pda:
            return "phone";
        case UPowerDeviceType.Tablet:
            return "tablet";
        case UPowerDeviceType.Wearable:
            return "watch";
        case UPowerDeviceType.Pen:
            return "pen";
        case UPowerDeviceType.Headset:
        case UPowerDeviceType.Headphones:
        case UPowerDeviceType.Speakers:
        case UPowerDeviceType.OtherAudio:
        case UPowerDeviceType.MediaPlayer:
            return "headphones";
        default:
            return "device";
        }
    }

    function nameForDevice(device) {
        const model = device.model;
        for (let i = 0; i < root.modelOverrides.length; ++i) {
            const override = root.modelOverrides[i];
            if (override.pattern.test(model))
                return override.icon;
        }
        return root.nameForType(device.type);
    }

    function pathForDevice(device) {
        return root.pathForName(root.nameForDevice(device));
    }
}
