pragma Singleton

import Quickshell

Singleton {
    id: root

    readonly property var byType: ({
            "weather": [
                { value: "glance", displayName: "Glance", icon: "density_small" },
                { value: "compact", displayName: "Compact", icon: "density_medium" },
                { value: "full", displayName: "Full", icon: "dashboard" },
                { value: "detailed", displayName: "Detailed", icon: "wb_twilight" }
            ],
            "calendar": [
                { value: "month", displayName: "Month", icon: "calendar_month" },
                { value: "split", displayName: "Split", icon: "calendar_view_day" },
                { value: "day", displayName: "Day", icon: "calendar_today" }
            ],
            "user": [
                { value: "full", displayName: "Full", icon: "dashboard" },
                { value: "mini", displayName: "Mini", icon: "density_small" }
            ],
            "performance": [
                { value: "rings", displayName: "Rings", icon: "data_usage" },
                { value: "bars", displayName: "Bars", icon: "bar_chart" },
                { value: "graph", displayName: "Graph", icon: "show_chart" }
            ],
            "media": [
                { value: "cover", displayName: "Cover", icon: "album" },
                { value: "lyrics", displayName: "Lyrics", icon: "lyrics" }
            ]
        })

    readonly property var defaults: ({
            "weather": "full",
            "media": "cover",
            "calendar": "month",
            "user": "full",
            "performance": "rings"
        })

    function forType(type) {
        return root.byType[type] ?? [];
    }

    function defaultFor(type) {
        const styles = root.forType(type);
        return root.defaults[type] ?? (styles.length > 0 ? styles[0].value : "");
    }

    function has(type) {
        return root.forType(type).length > 0;
    }
}
