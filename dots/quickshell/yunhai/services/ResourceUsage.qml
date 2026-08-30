pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Yunhai.Sys

Singleton {
    id: root

    readonly property real memoryTotal: SysMon.memoryTotal
    readonly property real memoryFree: SysMon.memoryFree
    readonly property real memoryUsed: SysMon.memoryUsed
    readonly property real memoryUsedPercentage: SysMon.memoryUsage
    readonly property real swapTotal: SysMon.swapTotal
    readonly property real swapFree: SysMon.swapFree
    readonly property real swapUsed: SysMon.swapUsed
    readonly property real swapUsedPercentage: SysMon.swapUsage

    readonly property real cpuUsage: SysMon.cpuUsage
    readonly property double cpuFrequency: SysMon.cpuFrequency
    readonly property double cpuTemperature: SysMon.cpuTemperature

    readonly property string maxAvailableMemoryString: kbToGbString(root.memoryTotal)
    readonly property string maxAvailableSwapString: kbToGbString(root.swapTotal)
    readonly property string maxAvailableCpuString: SysMon.cpuMaxFrequency > 0 ? `${SysMon.cpuMaxFrequency.toFixed(0)} GHz` : "--"

    readonly property int historyLength: Config.options.resources.historyLength
    property list<real> cpuUsageHistory: []
    property list<real> memoryUsageHistory: []
    property list<real> swapUsageHistory: []

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    function appended(history, value) {
        const next = history.slice(Math.max(0, history.length - root.historyLength + 1));
        next.push(value);
        return next;
    }

    Timer {
        running: Config.options.resources.enableCpu || Config.options.resources.enableRam
            || Config.options.resources.enableSwap || Config.options.resources.enableGpu
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: SysMon.refresh()
    }

    Connections {
        target: SysMon

        function onRefreshed() {
            root.cpuUsageHistory = root.appended(root.cpuUsageHistory, SysMon.cpuUsage);
            root.memoryUsageHistory = root.appended(root.memoryUsageHistory, SysMon.memoryUsage);
            root.swapUsageHistory = root.appended(root.swapUsageHistory, SysMon.swapUsage);
        }
    }

    Binding {
        target: SysMon
        property: "pollCpu"
        value: Config.options.resources.enableCpu
    }
    Binding {
        target: SysMon
        property: "pollMemory"
        value: Config.options.resources.enableRam || Config.options.resources.enableSwap
    }
    Binding {
        target: SysMon
        property: "pollGpu"
        value: Config.options.resources.enableGpu
    }
}
