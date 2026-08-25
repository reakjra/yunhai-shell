pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Yunhai.Sys

Singleton {
    id: root

    function gpuIndex(card, integrated) {
        const byCard = card ? SysMon.gpuCards.indexOf(card) : -1;
        return byCard >= 0 ? byCard : SysMon.gpuIntegrated.indexOf(integrated);
    }

    function at(list, index) {
        return index >= 0 && index < list.length ? list[index] : 0;
    }

    readonly property int dIdx: root.gpuIndex(Config.options.resources.gpu.dgpuCard, false)
    readonly property int iIdx: root.gpuIndex(Config.options.resources.gpu.igpuCard, true)

    function toGb(bytes) {
        return bytes / (1024 * 1024 * 1024);
    }

    readonly property bool dGpuAvailable: root.dIdx >= 0
    readonly property string dGpuName: Config.options.resources.gpu.dgpuName || (root.dGpuAvailable ? SysMon.gpuNames[root.dIdx] : "dGPU")
    readonly property string dGpuVendor: root.dGpuAvailable ? SysMon.gpuVendors[root.dIdx] : ""
    readonly property double dGpuUsage: root.at(SysMon.gpuUsages, root.dIdx)
    readonly property double dGpuVramUsage: root.at(SysMon.gpuVramUsages, root.dIdx)
    readonly property double dGpuVramUsedGB: root.toGb(root.at(SysMon.gpuVramUsed, root.dIdx))
    readonly property double dGpuVramTotalGB: root.toGb(root.at(SysMon.gpuVramTotal, root.dIdx))
    readonly property double dGpuTemperature: root.at(SysMon.gpuTemperatures, root.dIdx)
    readonly property double dGpuTempJunction: root.at(SysMon.gpuTemperaturesJunction, root.dIdx)
    readonly property double dGpuTempMem: root.at(SysMon.gpuTemperaturesMemory, root.dIdx)
    readonly property double dGpuFanRpm: root.at(SysMon.gpuFanRpm, root.dIdx)
    readonly property double dGpuFanUsage: root.at(SysMon.gpuFanPercents, root.dIdx)
    readonly property double dGpuPower: root.at(SysMon.gpuPower, root.dIdx)
    readonly property double dGpuPowerLimit: root.at(SysMon.gpuPowerLimits, root.dIdx)
    property list<real> dGpuUsageHistory: []
    readonly property string maxAvailableDGpuString: "\n" + root.dGpuName

    readonly property bool iGpuAvailable: root.iIdx >= 0
    readonly property string iGpuName: Config.options.resources.gpu.igpuName || (root.iGpuAvailable ? SysMon.gpuNames[root.iIdx] : "iGPU")
    readonly property string iGpuVendor: root.iGpuAvailable ? SysMon.gpuVendors[root.iIdx] : ""
    readonly property double iGpuUsage: root.at(SysMon.gpuUsages, root.iIdx)
    readonly property double iGpuVramUsage: root.at(SysMon.gpuVramUsages, root.iIdx)
    readonly property double iGpuVramUsedGB: root.toGb(root.at(SysMon.gpuVramUsed, root.iIdx))
    readonly property double iGpuVramTotalGB: root.toGb(root.at(SysMon.gpuVramTotal, root.iIdx))
    readonly property double iGpuTemperature: root.at(SysMon.gpuTemperatures, root.iIdx)
    property list<real> iGpuUsageHistory: []
    readonly property string maxAvailableIGpuString: "\n" + root.iGpuName

    readonly property int historyLength: Config.options.resources.historyLength

    Connections {
        target: SysMon

        function onRefreshed() {
            root.dGpuUsageHistory = ResourceUsage.appended(root.dGpuUsageHistory, root.dGpuUsage);
            root.iGpuUsageHistory = ResourceUsage.appended(root.iGpuUsageHistory, root.iGpuUsage);
        }
    }
}
