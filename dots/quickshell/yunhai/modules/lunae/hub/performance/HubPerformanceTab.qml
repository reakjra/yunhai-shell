pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae
import qs.modules.lunae.widgets

Item {
    id: root

    readonly property real cardSpacing: 10
    readonly property real cardPadding: 14
    readonly property bool popupOpen: storageCombo.popup.visible

    RowLayout {
        anchors.fill: parent
        spacing: root.cardSpacing

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: root.cardSpacing

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: false
                Layout.preferredHeight: Math.round((root.height - root.cardSpacing) * 0.42)
                Layout.maximumHeight: Layout.preferredHeight
                spacing: root.cardSpacing

                LoadCard {
                    title: Translation.tr("CPU")
                    subtitle: ResourceUsage.cpuModel
                    glyph: "memory_alt"
                    usage: ResourceUsage.cpuUsage
                    temperature: ResourceUsage.cpuTemperature
                    hasTemperature: true
                }
                LoadCard {
                    title: Translation.tr("GPU")
                    subtitle: GpuUsage.dGpuName
                    glyph: "monitor"
                    usage: GpuUsage.dGpuUsage
                    temperature: GpuUsage.dGpuTemperature
                    hasTemperature: GpuUsage.dGpuAvailable
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: root.cardSpacing

                StatCard {
                    Layout.preferredWidth: 1
                    Layout.fillWidth: true
                    Layout.horizontalStretchFactor: 32

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: root.cardPadding
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 10

                            Gauge {
                                Layout.alignment: Qt.AlignVCenter
                                size: 106
                                value: StorageUsage.selected?.usage ?? 0
                                glyph: "hard_drive_2"
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    text: Translation.tr("Storage")
                                    font.pixelSize: Appearance.font.pixelSize.larger
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colOnLayer1
                                    elide: Text.ElideRight
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    text: StorageUsage.selected ? `${StorageUsage.formatGiB(StorageUsage.selected.used)} / ${StorageUsage.formatGiB(StorageUsage.selected.total)} GiB` : "--"
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        StyledComboBox {
                            id: storageCombo
                            Layout.fillWidth: true
                            model: StorageUsage.devices.map(d => d.device)
                            currentIndex: Math.max(0, StorageUsage.devices.findIndex(d => d.device === StorageUsage.selectedDevice))
                            onActivated: index => StorageUsage.selectedDevice = StorageUsage.devices[index]?.device ?? ""
                        }
                    }
                }

                StatCard {
                    Layout.preferredWidth: 1
                    Layout.fillWidth: true
                    Layout.horizontalStretchFactor: 34

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: root.cardPadding
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            MaterialSymbol {
                                text: "swap_vert"
                                iconSize: Appearance.font.pixelSize.huge
                                color: Appearance.colors.colOnLayer1
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: Translation.tr("Network")
                                font.pixelSize: Appearance.font.pixelSize.larger
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                            }
                            Graph {
                                Layout.preferredWidth: 74
                                Layout.preferredHeight: 34
                                values: NetworkUsage.downHistory.map(v => v / NetworkUsage.peakRate)
                                points: NetworkUsage.historyLength
                                color: Appearance.colors.colPrimary
                                alignment: Graph.Alignment.Right
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        NetRow {
                            glyph: "download"
                            label: Translation.tr("Download")
                            value: NetworkUsage.formatRate(NetworkUsage.downRate)
                        }
                        NetRow {
                            glyph: "upload"
                            label: Translation.tr("Upload")
                            value: NetworkUsage.formatRate(NetworkUsage.upRate)
                        }
                        NetRow {
                            glyph: "history"
                            label: Translation.tr("Total")
                            value: `↓${NetworkUsage.formatBytes(NetworkUsage.downTotal)} ↑${NetworkUsage.formatBytes(NetworkUsage.upTotal)}`
                        }
                    }
                }

                StatCard {
                    Layout.preferredWidth: 1
                    Layout.fillWidth: true
                    Layout.horizontalStretchFactor: 20

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: root.cardPadding
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            MaterialSymbol {
                                text: "memory"
                                iconSize: Appearance.font.pixelSize.huge
                                color: Appearance.m3colors.m3tertiary
                            }
                            StyledText {
                                Layout.fillWidth: true
                                text: Translation.tr("Memory")
                                font.pixelSize: Appearance.font.pixelSize.larger
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnLayer1
                                elide: Text.ElideRight
                            }
                        }

                        Gauge {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.fillHeight: true
                            size: 106
                            value: ResourceUsage.memoryUsedPercentage
                            arcColor: Appearance.m3colors.m3tertiary
                        }

                        StyledText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            text: `${ResourceUsage.kbToGbString(ResourceUsage.memoryUsed)} / ${ResourceUsage.kbToGbString(ResourceUsage.memoryTotal)}`
                            font.pixelSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colSubtext
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        StatCard {
            id: batteryCard
            Layout.preferredWidth: 118
            Layout.fillHeight: true
            visible: Battery.available

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: batteryCard.height * Math.max(0, Math.min(1, Battery.percentage))
                color: Appearance.colors.colPrimary
                bottomLeftRadius: batteryCard.radius
                bottomRightRadius: batteryCard.radius
                topLeftRadius: height >= batteryCard.height - 1 ? batteryCard.radius : 0
                topRightRadius: height >= batteryCard.height - 1 ? batteryCard.radius : 0

                MotionBehavior on height {}
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.cardPadding
                spacing: 6

                MaterialSymbol {
                    text: Battery.isCharging ? "battery_charging_full" : "battery_full"
                    iconSize: Appearance.font.pixelSize.huge
                    color: Appearance.colors.colPrimary
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Battery")
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    visible: text !== ""
                    text: {
                        const seconds = Battery.isCharging ? Battery.timeToFull : Battery.timeToEmpty;
                        if (!(seconds > 0))
                            return "";
                        const hours = Math.floor(seconds / 3600);
                        const minutes = Math.floor((seconds % 3600) / 60);
                        return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
                    }
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.m3colors.m3onPrimary
                }
                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: `${Math.round(Battery.percentage * 100)}%`
                    font.pixelSize: Appearance.font.pixelSize.hugeass
                    font.weight: Font.DemiBold
                    color: Appearance.m3colors.m3onPrimary
                }
            }
        }
    }

    component StatCard: LunaeCard {
        Layout.fillHeight: true
    }

    component NetRow: RowLayout {
        id: netRow
        property string glyph: ""
        property string label: ""
        property string value: ""
        Layout.fillWidth: true
        spacing: 8

        MaterialSymbol {
            text: netRow.glyph
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colSubtext
        }
        StyledText {
            Layout.fillWidth: true
            text: netRow.label
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            elide: Text.ElideRight
        }
        StyledText {
            text: netRow.value
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.DemiBold
            color: Appearance.colors.colPrimary
        }
    }

    component Gauge: Item {
        id: gauge
        property real size: 86
        property real value: 0
        property string glyph: ""
        property color arcColor: Appearance.colors.colPrimary
        property real lineWidth: Math.max(3, Math.round(gauge.size * 0.065))

        implicitWidth: gauge.size
        implicitHeight: gauge.size

        WavyArc {
            anchors.fill: parent
            value: gauge.value
            sweepDeg: 290
            thickness: gauge.lineWidth
            playing: false
            waveAmpTarget: 0
            fgColor: gauge.arcColor
            trackColor: Appearance.colors.colLayer2
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: -2

            MaterialSymbol {
                Layout.alignment: Qt.AlignHCenter
                visible: gauge.glyph !== ""
                text: gauge.glyph
                iconSize: Math.round(gauge.size * 0.15)
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: `${Math.round(gauge.value * 100)}%`
                font.pixelSize: Math.round(gauge.size * 0.2)
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Translation.tr("Used")
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }

    component LoadCard: LunaeCard {
        id: loadCard
        property string title: ""
        property string subtitle: ""
        property string glyph: ""
        property real usage: 0
        property real temperature: 0
        property bool hasTemperature: true

        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.cardPadding
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item {
                    implicitWidth: 54
                    implicitHeight: 54

                    CircularProgress {
                        anchors.centerIn: parent
                        implicitSize: 54
                        lineWidth: 4
                        value: loadCard.usage
                        colPrimary: Appearance.colors.colPrimary
                        colSecondary: Appearance.colors.colLayer2
                        gapAngle: 70
                    }
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: loadCard.glyph
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnLayer1
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: loadCard.title
                        font.pixelSize: Appearance.font.pixelSize.hugeass
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer1
                        elide: Text.ElideRight
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: loadCard.subtitle
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                        elide: Text.ElideRight
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Translation.tr("Usage")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }

                    CookieShape {
                        Layout.alignment: Qt.AlignHCenter
                        implicitWidth: 62
                        implicitHeight: 62
                        lobes: 9
                        scallop: 0.07
                        color: Appearance.colors.colSecondaryContainer

                        StyledText {
                            anchors.centerIn: parent
                            text: `${Math.round(loadCard.usage * 100)}%`
                            font.pixelSize: Appearance.font.pixelSize.larger
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnSecondaryContainer
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }

            RowLayout {
                Layout.fillWidth: true
                visible: loadCard.hasTemperature
                spacing: 6

                MaterialSymbol {
                    text: "thermometer"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colSubtext
                }
                StyledText {
                    Layout.fillWidth: true
                    text: `${Math.round(loadCard.temperature)}°C`
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                }
            }

            StyledProgressBar {
                Layout.fillWidth: true
                visible: loadCard.hasTemperature
                valueBarWidth: loadCard.width - root.cardPadding * 2
                valueBarHeight: 8
                value: Math.max(0, Math.min(1, loadCard.temperature / 100))
                highlightColor: Appearance.colors.colPrimary
                trackColor: Appearance.colors.colLayer2
            }
        }
    }
}
