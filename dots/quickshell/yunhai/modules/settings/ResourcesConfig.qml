import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    id: page
    forceWidth: true

    ContentSection {
        icon: "tune"
        title: Translation.tr("Polling")

        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Update interval (ms)")
            value: Config.options.resources.updateInterval
            from: 100
            to: 10000
            stepSize: 100
            onValueChanged: {
                Config.options.resources.updateInterval = value;
            }
        }

        ConfigSpinBox {
            icon: "chart_data"
            text: Translation.tr("History length (data points)")
            value: Config.options.resources.historyLength
            from: 10
            to: 300
            stepSize: 10
            onValueChanged: {
                Config.options.resources.historyLength = value;
            }
        }
    }

    ContentSection {
        icon: "toggle_on"
        title: Translation.tr("Enable monitoring")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "memory"
                text: Translation.tr("CPU")
                checked: Config.options.resources.enableCpu
                onCheckedChanged: {
                    Config.options.resources.enableCpu = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "deployed_code"
                text: Translation.tr("RAM")
                checked: Config.options.resources.enableRam
                onCheckedChanged: {
                    Config.options.resources.enableRam = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "swap_horiz"
                text: Translation.tr("Swap")
                checked: Config.options.resources.enableSwap
                onCheckedChanged: {
                    Config.options.resources.enableSwap = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "airwave"
                text: Translation.tr("GPU")
                checked: Config.options.resources.enableGpu
                onCheckedChanged: {
                    Config.options.resources.enableGpu = checked;
                }
            }
        }
    }

    ContentSection {
        icon: "airwave"
        title: Translation.tr("GPU Configuration")
        enabled: Config.options.resources.enableGpu
        opacity: enabled ? 1.0 : 0.4

        // Detected GPU info
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            visible: GpuUsage.dGpuAvailable || GpuUsage.iGpuAvailable

            StyledText {
                visible: GpuUsage.dGpuAvailable
                text: Translation.tr("Detected dGPU: %1 (%2)").arg(GpuUsage.dGpuName).arg(GpuUsage.dGpuVendor)
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallie
                Layout.leftMargin: 8
            }
            StyledText {
                visible: GpuUsage.iGpuAvailable
                text: Translation.tr("Detected iGPU: %1 (%2)").arg(GpuUsage.iGpuName).arg(GpuUsage.iGpuVendor)
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.smallie
                Layout.leftMargin: 8
            }
        }

        ConfigRow {
            uniform: true
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("dGPU card (e.g., card0, leave empty for auto)")
                text: Config.options.resources.gpu.dgpuCard
                wrapMode: TextEdit.Wrap
                onTextChanged: Config.options.resources.gpu.dgpuCard = text
            }
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("dGPU name override (leave empty for auto)")
                text: Config.options.resources.gpu.dgpuName
                wrapMode: TextEdit.Wrap
                onTextChanged: Config.options.resources.gpu.dgpuName = text
            }
        }

        ConfigRow {
            uniform: true
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("iGPU card (e.g., card1, leave empty for auto)")
                text: Config.options.resources.gpu.igpuCard
                wrapMode: TextEdit.Wrap
                onTextChanged: Config.options.resources.gpu.igpuCard = text
            }
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("iGPU name override (leave empty for auto)")
                text: Config.options.resources.gpu.igpuName
                wrapMode: TextEdit.Wrap
                onTextChanged: Config.options.resources.gpu.igpuName = text
            }
        }
    }

    ContentSection {
        icon: "layers"
        title: Translation.tr("Overlay GPU Display")
        enabled: Config.options.resources.enableGpu
        opacity: enabled ? 1.0 : 0.4

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "device_thermostat"
                text: Translation.tr("Show dGPU")
                checked: Config.options.resources.gpu.overlay.showDGpu
                onCheckedChanged: {
                    Config.options.resources.gpu.overlay.showDGpu = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "memory"
                text: Translation.tr("Show iGPU")
                checked: Config.options.resources.gpu.overlay.showIGpu
                onCheckedChanged: {
                    Config.options.resources.gpu.overlay.showIGpu = checked;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("dGPU metrics")
            opacity: Config.options.resources.gpu.overlay.showDGpu ? 1.0 : 0.4

            ConfigListViewCompact {
                enabled: Config.options.resources.gpu.overlay.showDGpu
                opacity: enabled ? 1.0 : 0.4
                listModel: Config.options.resources.gpu.overlay.dGpuMetrics
                sourceListModel: Config.options.resources.gpu.overlay.dGpuAvailableMetrics
                onUpdated: (newList) => {
                    Config.options.resources.gpu.overlay.dGpuMetrics = newList;
                }
                onSourceUpdated: (newList) => {
                    Config.options.resources.gpu.overlay.dGpuAvailableMetrics = newList;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("iGPU metrics")
            opacity: Config.options.resources.gpu.overlay.showIGpu ? 1.0 : 0.4

            ConfigListViewCompact {
                enabled: Config.options.resources.gpu.overlay.showIGpu
                opacity: enabled ? 1.0 : 0.4
                listModel: Config.options.resources.gpu.overlay.iGpuMetrics
                sourceListModel: Config.options.resources.gpu.overlay.iGpuAvailableMetrics
                onUpdated: (newList) => {
                    Config.options.resources.gpu.overlay.iGpuMetrics = newList;
                }
                onSourceUpdated: (newList) => {
                    Config.options.resources.gpu.overlay.iGpuAvailableMetrics = newList;
                }
            }
        }
    }

    ContentSection {
        icon: "dock_to_bottom"
        title: Translation.tr("Bar Popup GPU Display")
        enabled: Config.options.resources.enableGpu
        opacity: enabled ? 1.0 : 0.4

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "device_thermostat"
                text: Translation.tr("Show dGPU")
                checked: Config.options.resources.gpu.bar.showDGpu
                onCheckedChanged: {
                    Config.options.resources.gpu.bar.showDGpu = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "memory"
                text: Translation.tr("Show iGPU")
                checked: Config.options.resources.gpu.bar.showIGpu
                onCheckedChanged: {
                    Config.options.resources.gpu.bar.showIGpu = checked;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("dGPU metrics")
            opacity: Config.options.resources.gpu.bar.showDGpu ? 1.0 : 0.4

            ConfigListViewCompact {
                enabled: Config.options.resources.gpu.bar.showDGpu
                opacity: enabled ? 1.0 : 0.4
                listModel: Config.options.resources.gpu.bar.dGpuMetrics
                sourceListModel: Config.options.resources.gpu.bar.dGpuAvailableMetrics
                onUpdated: (newList) => {
                    Config.options.resources.gpu.bar.dGpuMetrics = newList;
                }
                onSourceUpdated: (newList) => {
                    Config.options.resources.gpu.bar.dGpuAvailableMetrics = newList;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("iGPU metrics")
            opacity: Config.options.resources.gpu.bar.showIGpu ? 1.0 : 0.4

            ConfigListViewCompact {
                enabled: Config.options.resources.gpu.bar.showIGpu
                opacity: enabled ? 1.0 : 0.4
                listModel: Config.options.resources.gpu.bar.iGpuMetrics
                sourceListModel: Config.options.resources.gpu.bar.iGpuAvailableMetrics
                onUpdated: (newList) => {
                    Config.options.resources.gpu.bar.iGpuMetrics = newList;
                }
                onSourceUpdated: (newList) => {
                    Config.options.resources.gpu.bar.iGpuAvailableMetrics = newList;
                }
            }
        }
    }

    ContentSection {
        icon: "monitor_heart"
        title: Translation.tr("Bar Resources Display")

        ContentSubsection {
            title: Translation.tr("Always show in bar")

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "deployed_code"
                    text: Translation.tr("RAM")
                    checked: Config.options.bar.resources.alwaysShowRam
                    onCheckedChanged: {
                        Config.options.bar.resources.alwaysShowRam = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "swap_horiz"
                    text: Translation.tr("Swap")
                    checked: Config.options.bar.resources.alwaysShowSwap
                    onCheckedChanged: {
                        Config.options.bar.resources.alwaysShowSwap = checked;
                    }
                }
            }

            ConfigRow {
                uniform: true
                ConfigSwitch {
                    buttonIcon: "memory"
                    text: Translation.tr("CPU")
                    checked: Config.options.bar.resources.alwaysShowCpu
                    onCheckedChanged: {
                        Config.options.bar.resources.alwaysShowCpu = checked;
                    }
                }
                ConfigSwitch {
                    buttonIcon: "airwave"
                    text: Translation.tr("GPU")
                    checked: Config.options.bar.resources.alwaysShowGpu
                    onCheckedChanged: {
                        Config.options.bar.resources.alwaysShowGpu = checked;
                    }
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("GPU layout in bar")

            ConfigSelectionArray {
                currentValue: Config.options.bar.resources.gpuLayout
                onSelected: newValue => {
                    Config.options.bar.resources.gpuLayout = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("dGPU only"),
                        icon: "device_thermostat",
                        value: 0
                    },
                    {
                        displayName: Translation.tr("iGPU only"),
                        icon: "memory",
                        value: 1
                    },
                    {
                        displayName: Translation.tr("Both GPUs"),
                        icon: "grid_view",
                        value: 2
                    }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Warning thresholds (%)")

            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    icon: "deployed_code"
                    text: Translation.tr("Memory")
                    value: Config.options.bar.resources.memoryWarningThreshold
                    from: 50
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.bar.resources.memoryWarningThreshold = value;
                    }
                }
                ConfigSpinBox {
                    icon: "swap_horiz"
                    text: Translation.tr("Swap")
                    value: Config.options.bar.resources.swapWarningThreshold
                    from: 50
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.bar.resources.swapWarningThreshold = value;
                    }
                }
            }

            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    icon: "memory"
                    text: Translation.tr("CPU")
                    value: Config.options.bar.resources.cpuWarningThreshold
                    from: 50
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.bar.resources.cpuWarningThreshold = value;
                    }
                }
                ConfigSpinBox {
                    icon: "airwave"
                    text: Translation.tr("GPU")
                    value: Config.options.bar.resources.gpuWarningThreshold
                    from: 50
                    to: 100
                    stepSize: 5
                    onValueChanged: {
                        Config.options.bar.resources.gpuWarningThreshold = value;
                    }
                }
            }
        }
    }
}
