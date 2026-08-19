import qs.services
import qs.modules.common
import QtQuick
import QtQuick.Layouts
import qs.modules.ii.bar as Bar

MouseArea {
    id: root
    implicitHeight: columnLayout.implicitHeight + 15
    implicitWidth: columnLayout.implicitWidth
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    ColumnLayout {
        id: columnLayout
        spacing: 10
        anchors.centerIn: parent

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "memory"
            percentage: ResourceUsage.memoryUsedPercentage
            visible: (Config.options?.resources?.enableRam !== false) &&
                Config.options.bar.resources.alwaysShowRam
            warningThreshold: Config.options.bar.resources.memoryWarningThreshold
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "swap_horiz"
            percentage: ResourceUsage.swapUsedPercentage
            visible: (Config.options?.resources?.enableSwap !== false) &&
                Config.options.bar.resources.alwaysShowSwap && percentage > 0
            warningThreshold: Config.options.bar.resources.swapWarningThreshold
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "planner_review"
            percentage: ResourceUsage.cpuUsage
            visible: (Config.options?.resources?.enableCpu !== false) &&
                Config.options.bar.resources.alwaysShowCpu
            warningThreshold: Config.options.bar.resources.cpuWarningThreshold
        }

        Resource {
            Layout.alignment: Qt.AlignHCenter
            iconName: "empty_dashboard"
            percentage: (Config.options.bar.resources.gpuLayout == 0 || Config.options.bar.resources.gpuLayout == 2) ?
                GpuUsage.dGpuUsage : GpuUsage.iGpuUsage
            visible: (Config.options?.resources?.enableGpu !== false) &&
                Config.options.bar.resources.alwaysShowGpu &&
                ((GpuUsage.dGpuAvailable && (Config.options.bar.resources.gpuLayout == 0 || Config.options.bar.resources.gpuLayout == 2)) ||
                (GpuUsage.iGpuAvailable && (Config.options.bar.resources.gpuLayout == 1)))
            warningThreshold: Config.options.bar.resources.gpuWarningThreshold
        }

    }

    Bar.ResourcesPopup {
        hoverTarget: root
    }
}
