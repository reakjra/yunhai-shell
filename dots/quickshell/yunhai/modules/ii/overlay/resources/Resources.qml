pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.overlay

StyledOverlayWidget {
    function getIGpuMetricData(metricId) {
        switch (metricId) {
            case "usage": return {
                icon: "bolt",
                label: Translation.tr("Load:"),
                value: (GpuUsage.iGpuUsage > 0.8 ? Translation.tr("High") : GpuUsage.iGpuUsage > 0.4 ? Translation.tr("Medium") : Translation.tr("Low")) + ` (${Math.round(GpuUsage.iGpuUsage * 100)}%)`
            }
            case "vram": return {
                icon: "clock_loader_60",
                label: Translation.tr("VRAM:"),
                value: ` ${Math.round(GpuUsage.iGpuVramUsedGB * 10) / 10} / ${Math.round(GpuUsage.iGpuVramTotalGB * 10) / 10} GB`
            }
            case "temp": return {
                icon: "thermometer",
                label: Translation.tr("Temperature:"),
                value: `${GpuUsage.iGpuTemperature} °C`
            }
            default: return null
        }
    }

    function getDGpuMetricData(metricId) {
        switch (metricId) {
            case "usage": return {
                icon: "bolt",
                label: Translation.tr("Load:"),
                value: (GpuUsage.dGpuUsage > 0.8 ? Translation.tr("High") : GpuUsage.dGpuUsage > 0.4 ? Translation.tr("Medium") : Translation.tr("Low")) + ` (${Math.round(GpuUsage.dGpuUsage * 100)}%)`
            }
            case "vram": return {
                icon: "clock_loader_60",
                label: Translation.tr("VRAM:"),
                value: ` ${Math.round(GpuUsage.dGpuVramUsedGB * 10) / 10} / ${Math.round(GpuUsage.dGpuVramTotalGB * 10) / 10} GB`
            }
            case "temp": return {
                icon: "thermometer",
                label: Translation.tr("Temperature:"),
                value: `${GpuUsage.dGpuTemperature} °C`
            }
            case "tempJunction": return GpuUsage.dGpuTempJunction > 0 ? {
                icon: "thermometer",
                label: Translation.tr("Junction:"),
                value: `${GpuUsage.dGpuTempJunction} °C`
            } : null
            case "tempMem": return GpuUsage.dGpuTempMem > 0 ? {
                icon: "thermometer",
                label: Translation.tr("Memory:"),
                value: `${GpuUsage.dGpuTempMem} °C`
            } : null
            case "fan": return {
                icon: "air",
                label: Translation.tr("Fan:"),
                value: GpuUsage.dGpuVendor === "nvidia" ? `${GpuUsage.dGpuFanUsage} %` :
                       GpuUsage.dGpuFanRpm > 0 ? `${GpuUsage.dGpuFanRpm} RPM` : "0"
            }
            case "power": return {
                icon: "power",
                label: Translation.tr("Power:"),
                value: `${GpuUsage.dGpuPower} W / ${GpuUsage.dGpuPowerLimit} W`
            }
            default: return null
        }
    }

    function buildIGpuProperties() {
        const metrics = Config.options?.resources?.gpu?.overlay?.iGpuMetrics ?? []
        let props = []
        for (let i = 0; i < metrics.length; i++) {
            const data = getIGpuMetricData(metrics[i].id)
            if (data) props.push(data)
        }
        return props
    }

    function buildDGpuProperties() {
        const metrics = Config.options?.resources?.gpu?.overlay?.dGpuMetrics ?? []
        let props = []
        for (let i = 0; i < metrics.length; i++) {
            const data = getDGpuMetricData(metrics[i].id)
            if (data) props.push(data)
        }
        return props
    }

   id: root
    minimumWidth: 300
    minimumHeight: 200
   property list<var> resources: [
       {
           icon: "planner_review",
           name: Translation.tr("CPU"),
           history: (Config.options?.resources?.enableCpu !== false) ? ResourceUsage.cpuUsageHistory : [],
           maxAvailableString: ResourceUsage.maxAvailableCpuString,
           available: Config.options?.resources?.enableCpu !== false,
           extraProperties: [
               {
                   icon: "bolt",
                   label: Translation.tr("Load:"),
                   value: (ResourceUsage.cpuUsage > 0.8 ? Translation.tr("High") : ResourceUsage.cpuUsage > 0.4 ? Translation.tr("Medium") : Translation.tr("Low")) + ` (${Math.round(ResourceUsage.cpuUsage * 100)}%)`
               },
               {
                   icon: "planner_review",
                   label: Translation.tr("Freq:"),
                   value: ` ${Math.round(ResourceUsage.cpuFrequency  * 100) / 100} GHz`
               },
               {
                   icon: "thermometer",
                   label: Translation.tr("Temperature:"),
                   value: ` ${Math.round(ResourceUsage.cpuTemperature)} °C`
               }
           ]
       },
        {
            icon: "memory",
            name: Translation.tr("RAM"),
            history: (Config.options?.resources?.enableRam !== false) ? ResourceUsage.memoryUsageHistory : [],
            maxAvailableString: ResourceUsage.maxAvailableMemoryString,
            available: Config.options?.resources?.enableRam !== false,
            extraProperties: [
                {
                    icon: "clock_loader_60",
                    label: Translation.tr("Used:"),
                    value: ResourceUsage.kbToGbString(ResourceUsage.memoryUsed)
                },
                {
                    icon: "check_circle",
                    label: Translation.tr("Free:"),
                    value: ResourceUsage.kbToGbString(ResourceUsage.memoryFree)
                },
                {
                    icon: "empty_dashboard",
                    label: Translation.tr("Total:"),
                    value: ResourceUsage.kbToGbString(ResourceUsage.memoryTotal)
                }
            ]
        },
        {
            icon: "swap_horiz",
            name: Translation.tr("Swap"),
            history: (Config.options?.resources?.enableSwap !== false) ? ResourceUsage.swapUsageHistory : [],
            maxAvailableString: ResourceUsage.maxAvailableSwapString,
            available: Config.options?.resources?.enableSwap !== false,
              extraProperties: [
                {
                    icon: "clock_loader_60",
                    label: Translation.tr("Used:"),
                    value: ResourceUsage.kbToGbString(ResourceUsage.swapUsed)
                },
                {
                    icon: "check_circle",
                    label: Translation.tr("Free:"),
                    value: ResourceUsage.kbToGbString(ResourceUsage.swapFree)
                },
                {
                    icon: "empty_dashboard",
                    label: Translation.tr("Total:"),
                    value: ResourceUsage.kbToGbString(ResourceUsage.swapTotal)
                }
            ]

        },
        {
            icon: "empty_dashboard",
            name: Translation.tr("IGPU"),
            history: (Config.options?.resources?.enableGpu !== false) ? GpuUsage.iGpuUsageHistory : [],
            maxAvailableString: GpuUsage.maxAvailableIGpuString,
            available: (Config.options?.resources?.enableGpu !== false) &&
                       GpuUsage.iGpuAvailable &&
                       (Config.options?.resources?.gpu?.overlay?.showIGpu !== false),
            extraProperties: root.buildIGpuProperties()
        },
        {
            icon: "empty_dashboard",
            name: Translation.tr("DGPU"),
            history: (Config.options?.resources?.enableGpu !== false) ? GpuUsage.dGpuUsageHistory : [],
            maxAvailableString: GpuUsage.maxAvailableDGpuString,
            available: (Config.options?.resources?.enableGpu !== false) &&
                       GpuUsage.dGpuAvailable &&
                       (Config.options?.resources?.gpu?.overlay?.showDGpu !== false),
            extraProperties: root.buildDGpuProperties()
        }
    ].filter(r => r.available) 


    contentItem: Rectangle {
        id: contentItem
        anchors.fill: parent
        color: (Config?.options.appearance.transparency.enable ?? false)
            ? Qt.rgba(
                Appearance.m3colors.m3surfaceContainer.r,
                Appearance.m3colors.m3surfaceContainer.g,
                Appearance.m3colors.m3surfaceContainer.b,
                Math.max(0.8, 1 - Config.options.appearance.transparency.backgroundTransparency)
            )
            : Appearance.colors.colSurfaceContainer
        radius: root.contentRadius
        property real padding: 8
        implicitWidth: 350
        implicitHeight: Math.max(300, contentColumn.implicitHeight + (padding * 2))
        ColumnLayout {
            id: contentColumn
            anchors {
                fill: parent
                margins: parent.padding
            }
            spacing: 16

            SecondaryTabBar {
                id: tabBar

                currentIndex: Persistent.states.overlay.resources.tabIndex
                onCurrentIndexChanged: {
                    Persistent.states.overlay.resources.tabIndex = tabBar.currentIndex;
                }

                Repeater {
                    model: root.resources.length
                    delegate: SecondaryTabButton {
                        required property int index
                        property var modelData: root.resources[index]
                        buttonIcon: modelData.icon
                        buttonText: modelData.name
                    }
                }
            }

            SwipeView {
                id: swipeView
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: tabBar.currentIndex
                onCurrentIndexChanged: {
                    Persistent.states.overlay.resources.tabIndex = swipeView.currentIndex;
                }
                clip: true

                Repeater {
                    model: root.resources.length
                    delegate: ResourcePage {
                        required property int index
                        resource: root.resources[index]
                    }
                }
            }
        }
    }

    component ResourcePage: Item {
        id: resourcePage
        required property var resource

        ColumnLayout {
            anchors {
                fill: parent
                margins: 8
            }
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                ColumnLayout {
                    spacing: 2
                    StyledText {
                        text: ((resourcePage.resource?.history?.[resourcePage.resource.history.length - 1] ?? 0) * 100).toFixed(1) + "%"
                        font {
                            family: Appearance.font.family.numbers
                            variableAxes: Appearance.font.variableAxes.numbers
                            pixelSize: Appearance.font.pixelSize.huge
                        }
                    }
                    StyledText {
                        text: Translation.tr("of %1").arg(resourcePage.resource?.maxAvailableString ?? "--")
                        font {
                            family: Appearance.font.family.numbers
                            variableAxes: Appearance.font.variableAxes.numbers
                            pixelSize: Appearance.font.pixelSize.smallie
                        }
                        color: Appearance.colors.colSubtext
                    }
                    Item {
                        Layout.fillHeight: true
                    }
                }
                Rectangle {
                    id: graphBg
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Appearance.rounding.small
                    color: Appearance.colors.colSecondaryContainer
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: graphBg.width
                            height: graphBg.height
                            radius: graphBg.radius
                        }
                    }
                    Graph {
                        anchors.fill: parent
                        values: resourcePage.resource?.history ?? []
                        points: ResourceUsage.historyLength
                        alignment: Graph.Alignment.Right
                    }
                }
            }

            ColumnLayout {
                spacing: 8
                Repeater {
                    model: resourcePage.resource?.extraProperties.length ?? 0
                    delegate: RowLayout {
                        required property int index
                        property var modelData: resourcePage.resource?.extraProperties[index]

                        spacing: 6
                        MaterialSymbol {
                            text: modelData.icon
                            color: Appearance.colors.colPrimary
                            iconSize: Appearance.font.pixelSize.large
                        }
                        StyledText {
                            text: modelData.label ?? ""
                            color: Appearance.colors.colOnSurface
                            font.weight: Font.Bold
                        }
                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            visible: modelData.value !== ""
                            color: Appearance.colors.colOnSurfaceVariant
                            text: modelData.value ?? ""
                            font {
                                family: Appearance.font.family.numbers
                                variableAxes: Appearance.font.variableAxes.numbers
                            }
                        }
                    }
                }
            }
        }
    }
}
