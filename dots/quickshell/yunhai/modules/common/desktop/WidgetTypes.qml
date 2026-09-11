pragma Singleton

import Quickshell

Singleton {
    id: root

    readonly property var list: [
        { value: "image", displayName: "Image", icon: "add_photo_alternate" },
        { value: "notes", displayName: "Notes", icon: "sticky_note_2" },
        { value: "calendar", displayName: "Calendar", icon: "calendar_month", chip: true },
        { value: "weather", displayName: "Weather", icon: "partly_cloudy_day", chip: true },
        { value: "media", displayName: "Media", icon: "music_note", chip: true },
        { value: "deviceBattery", displayName: "Device battery", icon: "battery_android_full" },
        { value: "user", displayName: "User", icon: "account_circle", chip: true },
        { value: "performance", displayName: "Performance", icon: "speed" }
    ]

    function metaFor(type) {
        return root.list.find(t => t.value === type) ?? ({ value: type, displayName: type, icon: "widgets" });
    }

    function hasChip(type) {
        return root.metaFor(type).chip === true;
    }

    function nameFor(type) {
        return root.metaFor(type).displayName;
    }

    function iconFor(type) {
        return root.metaFor(type).icon;
    }
}
