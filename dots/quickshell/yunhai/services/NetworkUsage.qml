pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Yunhai

Singleton {
    id: root

    readonly property real downRate: SysMon.netDownRate
    readonly property real upRate: SysMon.netUpRate
    readonly property real downTotal: SysMon.netDownTotal
    readonly property real upTotal: SysMon.netUpTotal

    readonly property int historyLength: Config.options.resources.historyLength
    property list<real> downHistory: []
    property list<real> upHistory: []
    readonly property real peakRate: Math.max(1, ...root.downHistory, ...root.upHistory)

    function appended(history, value) {
        const next = history.slice(Math.max(0, history.length - root.historyLength + 1));
        next.push(value);
        return next;
    }

    function formatBytes(bytes: real): string {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let value = Math.max(0, bytes);
        let unit = 0;
        while (value >= 1024 && unit < units.length - 1) {
            value /= 1024;
            unit++;
        }
        return `${value.toFixed(value >= 100 || unit === 0 ? 0 : 1)} ${units[unit]}`;
    }

    function formatRate(bytesPerSecond: real): string {
        return `${root.formatBytes(bytesPerSecond)}/s`;
    }

    Connections {
        target: SysMon

        function onRefreshed() {
            root.downHistory = root.appended(root.downHistory, SysMon.netDownRate);
            root.upHistory = root.appended(root.upHistory, SysMon.netUpRate);
        }
    }

    Binding {
        target: SysMon
        property: "pollNetwork"
        value: true
    }
}
