pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property real barHeight: 54
    property var shelf

    readonly property int gpuLayout: Config.options.bar.resources.gpuLayout
    readonly property bool gpuShown: (Config.options?.resources?.enableGpu !== false)
        && Config.options.bar.resources.alwaysShowGpu
        && ((GpuUsage.dGpuAvailable && (gpuLayout === 0 || gpuLayout === 2)) || (GpuUsage.iGpuAvailable && gpuLayout === 1))

    implicitWidth: pill.implicitWidth
    implicitHeight: barHeight * 0.7
    Layout.alignment: Qt.AlignVCenter

    component RingStat: RowLayout {
        id: stat
        property string icon
        property real percentage: 0
        property int warningThreshold: 100
        readonly property bool warning: percentage * 100 >= warningThreshold
        readonly property color ringColor: stat.warning ? Appearance.colors.colError : Appearance.colors.colPrimary
        spacing: 3

        CircularProgress {
            id: ring
            Layout.alignment: Qt.AlignVCenter
            lineWidth: 2
            implicitSize: 24
            value: stat.percentage
            colPrimary: stat.ringColor
            colSecondary: Qt.alpha(stat.ringColor, 0.3)
            enableAnimation: false

            MaterialSymbol {
                anchors.centerIn: parent
                font.weight: Font.DemiBold
                fill: 1
                text: stat.icon
                iconSize: Appearance.font.pixelSize.normal
                color: stat.warning ? Appearance.colors.colError : Appearance.colors.colOnLayer1
            }
        }
    }

    Squircle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: statRow.implicitWidth + 20
        implicitHeight: root.barHeight * 0.7
        radius: height / 2
        color: (resMouse.containsMouse || (root.shelf?.resourcesOpen ?? false)) ? AkebonoAppearance.shelfPillHoverColor : AkebonoAppearance.shelfPillColor

        Component.onCompleted: root.shelf.registerResourcesAnchor(pill)
        Component.onDestruction: root.shelf.unregisterResourcesAnchor(pill)
        onXChanged: root.shelf.publishResources()

        RowLayout {
            id: statRow
            anchors.centerIn: parent
            spacing: 6

            RingStat {
                visible: (Config.options?.resources?.enableRam !== false) && Config.options.bar.resources.alwaysShowRam
                icon: "memory"
                percentage: ResourceUsage.memoryUsedPercentage
                warningThreshold: Config.options.bar.resources.memoryWarningThreshold
            }
            RingStat {
                visible: (Config.options?.resources?.enableSwap !== false) && Config.options.bar.resources.alwaysShowSwap && percentage > 0
                icon: "swap_horiz"
                percentage: ResourceUsage.swapUsedPercentage
                warningThreshold: Config.options.bar.resources.swapWarningThreshold
            }
            RingStat {
                visible: (Config.options?.resources?.enableCpu !== false) && Config.options.bar.resources.alwaysShowCpu
                icon: "planner_review"
                percentage: ResourceUsage.cpuUsage
                warningThreshold: Config.options.bar.resources.cpuWarningThreshold
            }
            RingStat {
                visible: root.gpuShown
                icon: "empty_dashboard"
                percentage: (root.gpuLayout === 0 || root.gpuLayout === 2) ? GpuUsage.dGpuUsage : GpuUsage.iGpuUsage
                warningThreshold: Config.options.bar.resources.gpuWarningThreshold
            }
        }

        MouseArea {
            id: resMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.shelf.toggleResources()
        }
    }
}
