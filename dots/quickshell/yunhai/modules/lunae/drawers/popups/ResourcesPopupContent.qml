pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae.bar

Row {
    id: root
    spacing: 12

    function formatKB(kb) { return (kb / (1024 * 1024)).toFixed(1) + " GB" }

    function getIGpuMetricData(metricId) {
        switch (metricId) {
        case "usage": return { icon: "bolt", label: Translation.tr("Load:"), value: `${Math.round(GpuUsage.iGpuUsage * 100)}%` }
        case "vram": return { icon: "clock_loader_60", label: Translation.tr("VRAM:"), value: `${Math.round(GpuUsage.iGpuVramUsedGB * 10) / 10} / ${Math.round(GpuUsage.iGpuVramTotalGB * 10) / 10} GB` }
        case "temp": return { icon: "thermometer", label: Translation.tr("Temperature:"), value: `${GpuUsage.iGpuTemperature} °C` }
        default: return null
        }
    }

    function getDGpuMetricData(metricId) {
        switch (metricId) {
        case "usage": return { icon: "bolt", label: Translation.tr("Load:"), value: `${Math.round(GpuUsage.dGpuUsage * 100)}%` }
        case "vram": return { icon: "clock_loader_60", label: Translation.tr("VRAM:"), value: `${Math.round(GpuUsage.dGpuVramUsedGB * 10) / 10} / ${Math.round(GpuUsage.dGpuVramTotalGB * 10) / 10} GB` }
        case "temp": return { icon: "thermometer", label: Translation.tr("Temperature:"), value: `${GpuUsage.dGpuTemperature} °C` }
        case "tempJunction": return GpuUsage.dGpuTempJunction > 0 ? { icon: "thermometer", label: Translation.tr("Junction:"), value: `${GpuUsage.dGpuTempJunction} °C` } : null
        case "tempMem": return GpuUsage.dGpuTempMem > 0 ? { icon: "thermometer", label: Translation.tr("Memory:"), value: `${GpuUsage.dGpuTempMem} °C` } : null
        case "fan": return { icon: "air", label: Translation.tr("Fan:"), value: GpuUsage.dGpuVendor === "nvidia" ? `${GpuUsage.dGpuFanUsage} %` : GpuUsage.dGpuFanRpm > 0 ? `${GpuUsage.dGpuFanRpm} RPM` : "0" }
        case "power": return { icon: "power", label: Translation.tr("Power:"), value: `${GpuUsage.dGpuPower} W / ${GpuUsage.dGpuPowerLimit} W` }
        default: return null
        }
    }

    Column {
        visible: Config.options?.resources?.enableRam !== false
        spacing: 4
        StyledPopupHeaderRow { icon: "memory"; label: "RAM" }
        StyledPopupValueRow { icon: "clock_loader_60"; label: Translation.tr("Used:"); value: root.formatKB(ResourceUsage.memoryUsed) }
        StyledPopupValueRow { icon: "check_circle"; label: Translation.tr("Free:"); value: root.formatKB(ResourceUsage.memoryFree) }
        StyledPopupValueRow { icon: "empty_dashboard"; label: Translation.tr("Total:"); value: root.formatKB(ResourceUsage.memoryTotal) }
    }

    Column {
        visible: (Config.options?.resources?.enableSwap !== false) && (ResourceUsage.swapTotal > 0)
        spacing: 4
        StyledPopupHeaderRow { icon: "swap_horiz"; label: "Swap" }
        StyledPopupValueRow { icon: "clock_loader_60"; label: Translation.tr("Used:"); value: root.formatKB(ResourceUsage.swapUsed) }
        StyledPopupValueRow { icon: "check_circle"; label: Translation.tr("Free:"); value: root.formatKB(ResourceUsage.swapFree) }
        StyledPopupValueRow { icon: "empty_dashboard"; label: Translation.tr("Total:"); value: root.formatKB(ResourceUsage.swapTotal) }
    }

    Column {
        visible: Config.options?.resources?.enableCpu !== false
        spacing: 4
        StyledPopupHeaderRow { icon: "planner_review"; label: "CPU" }
        StyledPopupValueRow {
            icon: "bolt"; label: Translation.tr("Load:")
            value: (ResourceUsage.cpuUsage > 0.8 ? Translation.tr("High") : ResourceUsage.cpuUsage > 0.4 ? Translation.tr("Medium") : Translation.tr("Low")) + ` (${Math.round(ResourceUsage.cpuUsage * 100)}%)`
        }
        StyledPopupValueRow { icon: "planner_review"; label: Translation.tr("Freq:"); value: `${Math.round(ResourceUsage.cpuFrequency * 100) / 100} GHz` }
        StyledPopupValueRow { icon: "thermometer"; label: Translation.tr("Temperature:"); value: `${Math.round(ResourceUsage.cpuTemperature)} °C` }
    }

    ColumnLayout {
        visible: (Config.options?.resources?.enableGpu !== false)
            && (Config.options?.resources?.gpu?.bar?.showIGpu !== false)
            && GpuUsage.iGpuAvailable
            && (Config.options.bar.resources.gpuLayout == 1 || Config.options.bar.resources.gpuLayout == 2)
        spacing: 4
        StyledPopupHeaderRow { icon: "empty_dashboard"; label: "IGPU" }
        Repeater {
            model: Config.options?.resources?.gpu?.bar?.iGpuMetrics ?? []
            delegate: StyledPopupValueRow {
                required property var modelData
                property var metricData: root.getIGpuMetricData(modelData.id)
                icon: metricData?.icon ?? ""
                label: metricData?.label ?? ""
                value: metricData?.value ?? ""
                visible: metricData !== null
            }
        }
    }

    ColumnLayout {
        visible: (Config.options?.resources?.enableGpu !== false)
            && (Config.options?.resources?.gpu?.bar?.showDGpu !== false)
            && GpuUsage.dGpuAvailable
            && (Config.options.bar.resources.gpuLayout == 0 || Config.options.bar.resources.gpuLayout == 2)
        spacing: 4
        StyledPopupHeaderRow { icon: "empty_dashboard"; label: "DGPU" }
        Repeater {
            model: Config.options?.resources?.gpu?.bar?.dGpuMetrics ?? []
            delegate: StyledPopupValueRow {
                required property var modelData
                property var metricData: root.getDGpuMetricData(modelData.id)
                icon: metricData?.icon ?? ""
                label: metricData?.label ?? ""
                value: metricData?.value ?? ""
                visible: metricData !== null
            }
        }
    }
}
