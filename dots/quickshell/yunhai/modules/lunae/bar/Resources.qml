import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    property bool borderless: Config.options.bar.borderless
    implicitWidth: rowLayout.implicitWidth + rowLayout.anchors.leftMargin + rowLayout.anchors.rightMargin
    implicitHeight: Appearance.sizes.barHeight
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    RowLayout {
        id: rowLayout

        spacing: 0
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4

        Resource {
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            shown: (Config.options?.resources?.enableRam !== false) &&
                Config.options.bar.resources.alwaysShowRam
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
        }

        Resource {
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            shown: (Config.options?.resources?.enableSwap !== false) &&
                Config.options.bar.resources.alwaysShowSwap && percentage > 0
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
        }

        Resource {
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            shown: (Config.options?.resources?.enableCpu !== false) &&
                Config.options.bar.resources.alwaysShowCpu
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

        Resource {
            iconName: "empty_dashboard"
            percentage: (Config.options.bar.resources.gpuLayout == 0 || Config.options.bar.resources.gpuLayout == 2) ?
                GpuUsage.dGpuUsage : GpuUsage.iGpuUsage
            shown: (Config.options?.resources?.enableGpu !== false) &&
                Config.options.bar.resources.alwaysShowGpu &&
                ((GpuUsage.dGpuAvailable && (Config.options.bar.resources.gpuLayout == 0 || Config.options.bar.resources.gpuLayout == 2)) ||
                (GpuUsage.iGpuAvailable && (Config.options.bar.resources.gpuLayout == 1)))
            Layout.leftMargin: shown ? 6 : 0
            warningThreshold: Config.options.bar.resources.gpuWarningThreshold
        }

    }

    ResourcesPopup {
        hoverTarget: root
    }
}
