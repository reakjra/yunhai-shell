pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Yunhai.Sys

Singleton {
    id: root

    readonly property real memoryTotal: SysMon.memory.total / 1024
    readonly property real memoryFree: SysMon.memory.free / 1024
    readonly property real memoryUsed: SysMon.memory.used / 1024
    readonly property real memoryUsedPercentage: SysMon.memory.usage
    readonly property real swapTotal: SysMon.memory.swapTotal / 1024
    readonly property real swapFree: SysMon.memory.swapFree / 1024
    readonly property real swapUsed: SysMon.memory.swapUsed / 1024
    readonly property real swapUsedPercentage: SysMon.memory.swapUsage

    readonly property real cpuUsage: SysMon.cpu.usage
    readonly property double cpuFrequency: SysMon.cpu.frequency
    readonly property double cpuTemperature: SysMon.cpu.temperature

    readonly property string maxAvailableMemoryString: kbToGbString(root.memoryTotal)
    readonly property string maxAvailableSwapString: kbToGbString(root.swapTotal)
    readonly property string maxAvailableCpuString: SysMon.cpu.maxFrequency > 0 ? `${SysMon.cpu.maxFrequency.toFixed(0)} GHz` : "--"

    readonly property int historyLength: Config.options.resources.historyLength
    readonly property list<real> cpuUsageHistory: SysMon.cpu.usageHistory
    readonly property list<real> memoryUsageHistory: SysMon.memory.usageHistory
    readonly property list<real> swapUsageHistory: SysMon.memory.swapUsageHistory

    function kbToGbString(kb) {
        return (kb / (1024 * 1024)).toFixed(1) + " GB";
    }

    Binding {
        target: SysMon
        property: "interval"
        value: Config.options.resources.updateInterval
    }
    Binding {
        target: SysMon
        property: "historyLength"
        value: Config.options.resources.historyLength
    }
    Binding {
        target: SysMon
        property: "running"
        value: Config.options.resources.enableCpu || Config.options.resources.enableRam
            || Config.options.resources.enableSwap || Config.options.resources.enableGpu
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
