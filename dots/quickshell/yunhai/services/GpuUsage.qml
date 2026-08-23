pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Yunhai.Sys

Singleton {
    id: root

    function pickGpu(card, integrated) {
        return (card ? SysMon.gpus.find(gpu => gpu.card === card) : null)
            ?? SysMon.gpus.find(gpu => gpu.integrated === integrated)
            ?? null;
    }

    readonly property var dGpu: root.pickGpu(Config.options.resources.gpu.dgpuCard, false)
    readonly property var iGpu: root.pickGpu(Config.options.resources.gpu.igpuCard, true)

    function vendorName(gpu) {
        if (!gpu) return "";
        switch (gpu.vendor) {
            case GpuDevice.Amd: return "amd";
            case GpuDevice.Intel: return "intel";
            case GpuDevice.Nvidia: return "nvidia";
            default: return "";
        }
    }

    function toGb(bytes) {
        return bytes / (1024 * 1024 * 1024);
    }

    readonly property bool dGpuAvailable: root.dGpu !== null
    readonly property string dGpuName: Config.options.resources.gpu.dgpuName || (root.dGpu?.name ?? "dGPU")
    readonly property string dGpuVendor: root.vendorName(root.dGpu)
    readonly property double dGpuUsage: root.dGpu?.usage ?? 0
    readonly property double dGpuVramUsage: root.dGpu?.vramUsage ?? 0
    readonly property double dGpuVramUsedGB: root.toGb(root.dGpu?.vramUsed ?? 0)
    readonly property double dGpuVramTotalGB: root.toGb(root.dGpu?.vramTotal ?? 0)
    readonly property double dGpuTemperature: root.dGpu?.temperature ?? 0
    readonly property double dGpuTempJunction: root.dGpu?.temperatureJunction ?? 0
    readonly property double dGpuTempMem: root.dGpu?.temperatureMemory ?? 0
    readonly property double dGpuFanRpm: root.dGpu?.fanRpm ?? 0
    readonly property double dGpuFanUsage: root.dGpu?.fanPercent ?? 0
    readonly property double dGpuPower: root.dGpu?.power ?? 0
    readonly property double dGpuPowerLimit: root.dGpu?.powerLimit ?? 0
    readonly property list<real> dGpuUsageHistory: root.dGpu?.usageHistory ?? []
    readonly property string maxAvailableDGpuString: "\n" + root.dGpuName

    readonly property bool iGpuAvailable: root.iGpu !== null
    readonly property string iGpuName: Config.options.resources.gpu.igpuName || (root.iGpu?.name ?? "iGPU")
    readonly property string iGpuVendor: root.vendorName(root.iGpu)
    readonly property double iGpuUsage: root.iGpu?.usage ?? 0
    readonly property double iGpuVramUsage: root.iGpu?.vramUsage ?? 0
    readonly property double iGpuVramUsedGB: root.toGb(root.iGpu?.vramUsed ?? 0)
    readonly property double iGpuVramTotalGB: root.toGb(root.iGpu?.vramTotal ?? 0)
    readonly property double iGpuTemperature: root.iGpu?.temperature ?? 0
    readonly property list<real> iGpuUsageHistory: root.iGpu?.usageHistory ?? []
    readonly property string maxAvailableIGpuString: "\n" + root.iGpuName

    readonly property int historyLength: Config.options.resources.historyLength
}
