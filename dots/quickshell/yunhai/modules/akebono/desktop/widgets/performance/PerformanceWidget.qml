pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono.desktop.widgets

WidgetCard {
    id: root
    minSize: 150

    readonly property bool isRings: root.styleId === "rings"
    readonly property bool isBars: root.styleId === "bars"
    readonly property bool isGraph: root.styleId === "graph"

    readonly property var metrics: [
        {
            "icon": "planner_review",
            "name": Translation.tr("CPU"),
            "polled": Config.options.resources.enableCpu,
            "value": ResourceUsage.cpuUsage,
            "detail": `${Math.round(ResourceUsage.cpuTemperature)} °C`,
            "history": ResourceUsage.cpuUsageHistory,
            "color": Appearance.colors.colPrimary
        },
        {
            "icon": "memory",
            "name": Translation.tr("RAM"),
            "polled": Config.options.resources.enableRam,
            "value": ResourceUsage.memoryUsedPercentage,
            "detail": ResourceUsage.kbToGbString(ResourceUsage.memoryUsed),
            "history": ResourceUsage.memoryUsageHistory,
            "color": Appearance.m3colors.m3secondary
        },
        {
            "icon": "swap_horiz",
            "name": Translation.tr("Swap"),
            "polled": Config.options.resources.enableSwap,
            "value": ResourceUsage.swapUsedPercentage,
            "detail": ResourceUsage.kbToGbString(ResourceUsage.swapUsed),
            "history": ResourceUsage.swapUsageHistory,
            "color": Appearance.m3colors.m3tertiary
        },
        {
            "icon": "monitor",
            "name": Translation.tr("GPU"),
            "polled": Config.options.resources.enableGpu && GpuUsage.dGpuAvailable,
            "value": GpuUsage.dGpuUsage,
            "detail": `${Math.round(GpuUsage.dGpuTemperature)} °C`,
            "history": GpuUsage.dGpuUsageHistory,
            "color": Appearance.colors.colSecondary
        }
    ]
    readonly property var shown: root.metrics.filter(m => m.polled)
    readonly property real ringSize: Math.max(44, Math.min(96, Math.round(Math.min(root.width / root.shown.length, root.height) * 0.62)))

    RowLayout {
        anchors.fill: parent
        visible: root.isRings
        spacing: 8

        Repeater {
            model: root.isRings ? root.shown : []

            ColumnLayout {
                id: ring
                required property var modelData
                Layout.fillWidth: true
                spacing: 2

                CircularProgress {
                    Layout.alignment: Qt.AlignHCenter
                    implicitSize: root.ringSize
                    lineWidth: Math.max(3, Math.round(root.ringSize * 0.1))
                    value: ring.modelData.value
                    colPrimary: ring.modelData.color
                    colSecondary: Appearance.colors.colLayer2

                    StyledText {
                        anchors.centerIn: parent
                        text: `${Math.round(ring.modelData.value * 100)}`
                        font.pixelSize: Math.round(root.ringSize * 0.26)
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                    }
                }
                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: ring.modelData.name
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: root.isBars
        spacing: 10

        Repeater {
            model: root.isBars ? root.shown : []

            ColumnLayout {
                id: bar
                required property var modelData
                Layout.fillWidth: true
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    MaterialSymbol {
                        text: bar.modelData.icon
                        iconSize: Appearance.font.pixelSize.large
                        color: bar.modelData.color
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: bar.modelData.name
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colOnLayer1
                        elide: Text.ElideRight
                    }
                    StyledText {
                        text: `${Math.round(bar.modelData.value * 100)}%`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colSubtext
                    }
                }

                StyledProgressBar {
                    Layout.fillWidth: true
                    valueBarWidth: bar.width
                    value: bar.modelData.value
                    highlightColor: bar.modelData.color
                    trackColor: Appearance.colors.colLayer2
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        visible: root.isGraph
        spacing: 8

        Repeater {
            model: root.isGraph ? root.shown : []

            ColumnLayout {
                id: plot
                required property var modelData
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    StyledText {
                        Layout.fillWidth: true
                        text: plot.modelData.name
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                    }
                    StyledText {
                        text: `${Math.round(plot.modelData.value * 100)}% · ${plot.modelData.detail}`
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }

                Graph {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 18
                    values: plot.modelData.history
                    points: ResourceUsage.historyLength
                    color: plot.modelData.color
                    alignment: Graph.Alignment.Right
                }
            }
        }
    }
}
