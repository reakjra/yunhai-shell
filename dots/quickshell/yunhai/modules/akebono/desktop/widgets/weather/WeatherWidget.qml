pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono.desktop.widgets

WidgetCard {
    id: root
    minSize: root.isDetailed ? 180 : 120

    readonly property var wd: Weather.data
    readonly property bool isGlance: root.styleId === "glance"
    readonly property bool isCompact: root.styleId === "compact"
    readonly property bool isDetailed: root.styleId === "detailed"

    readonly property var tempMetrics: ({
            "compact": { "scale": 0.34, "cap": 56 },
            "detailed": { "scale": 0.19, "cap": 44 }
        })
    readonly property var tempMetric: root.tempMetrics[root.styleId] ?? ({ "scale": 0.24, "cap": 64 })
    readonly property real tempBasis: root.isCompact ? root.height : Math.min(root.width, root.height)
    readonly property real tempFontSize: Math.max(Appearance.font.pixelSize.huge, Math.min(root.tempMetric.cap, Math.round(root.tempBasis * root.tempMetric.scale)))
    readonly property real chipSize: Math.max(38, Math.round(root.tempFontSize * 1.2))

    readonly property real compactFooterBudget: compactCol.height - compactHeader.implicitHeight - compactCol.spacing
    readonly property bool compactFooterFits: root.compactFooterBudget >= root.statRowHeight

    readonly property real arcReserve: root.isDetailed ? 54 : 0
    readonly property real statRowHeight: Appearance.font.pixelSize.normal + 4
    readonly property real statsBudget: mainCol.height - headerRow.implicitHeight - cityLabel.implicitHeight - root.arcReserve - 3 * mainCol.spacing
    readonly property int statRows: Math.max(0, Math.floor((root.statsBudget + statGrid.rowSpacing) / (root.statRowHeight + statGrid.rowSpacing)))
    readonly property int statColumns: root.isDetailed ? 2 : 3
    readonly property int statCount: Math.min(root.stats.length, root.statRows * root.statColumns)

    readonly property var stats: [
        { icon: "humidity_percentage", value: root.reading(root.wd.humidity, "--") },
        { icon: "air", value: `${root.reading(root.wd.wind, "--")} ${root.isDetailed ? root.reading(root.wd.windDir, "") : ""}` },
        { icon: "rainy", value: root.reading(root.wd.precip, "--") },
        { icon: "wb_sunny", value: Translation.tr("UV %1").arg(root.reading(String(root.wd.uv), "--")) },
        { icon: "visibility", value: root.reading(root.wd.visib, "--") },
        { icon: "compress", value: root.reading(root.wd.press, "--") }
    ]

    function reading(value: var, fallback: string): string {
        return typeof value === "string" && value.length > 0 ? value : fallback;
    }

    ColumnLayout {
        id: mainCol
        anchors.fill: parent
        visible: !root.isGlance && !root.isCompact
        spacing: 8

        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: root.reading(root.wd.temp, "--°")
                    font.pixelSize: root.tempFontSize
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Feels like %1").arg(root.reading(root.wd.tempFeelsLike, "--°"))
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }
            }

            ShapeSurface {
                baseSize: root.chipSize
                shape: root.chipShape
                color: Appearance.colors.colPrimaryContainer

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: Icons.getWeatherIcon(root.wd.wCode) ?? "cloud"
                    fill: 1
                    iconSize: Math.round(root.chipSize * 0.55)
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }
        }

        StyledText {
            id: cityLabel
            Layout.fillWidth: true
            text: root.reading(root.wd.city, "")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            elide: Text.ElideRight
        }

        SunArc {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: 0
            visible: root.isDetailed
            sunSize: 22
            progressWidth: 2.5
            labelSize: Appearance.font.pixelSize.smallest
            sunrise: root.wd.sunrise
            sunset: root.wd.sunset
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.isDetailed
        }

        GridLayout {
            id: statGrid
            Layout.fillWidth: true
            visible: root.statCount > 0
            columns: root.statColumns
            columnSpacing: 8
            rowSpacing: 4

            Repeater {
                model: root.stats.slice(0, root.statCount)

                WeatherStat {
                    required property var modelData
                    Layout.fillWidth: true
                    fillLabel: true
                    icon: modelData.icon
                    value: modelData.value
                }
            }
        }
    }

    ColumnLayout {
        id: compactCol
        anchors.fill: parent
        visible: root.isCompact
        spacing: 10

        RowLayout {
            id: compactHeader
            Layout.fillWidth: true
            spacing: 14

            StyledText {
                text: root.reading(root.wd.temp, "--°")
                font.pixelSize: root.tempFontSize
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer1
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: root.reading(root.wd.desc, Translation.tr("Weather"))
                    font.pixelSize: Appearance.font.pixelSize.large
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    text: root.reading(root.wd.city, "")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }
            }

            ShapeSurface {
                baseSize: root.chipSize
                shape: root.chipShape
                color: Appearance.colors.colPrimaryContainer

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: Icons.getWeatherIcon(root.wd.wCode) ?? "cloud"
                    fill: 1
                    iconSize: Math.round(root.chipSize * 0.55)
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.compactFooterFits
            spacing: 14

            Flow {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBottom
                spacing: 14

                Repeater {
                    model: root.stats.slice(0, 4)

                    WeatherStat {
                        required property var modelData
                        width: implicitWidth
                        height: implicitHeight
                        icon: modelData.icon
                        value: modelData.value
                    }
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignBottom
                spacing: 0

                WeatherStat {
                    Layout.alignment: Qt.AlignRight
                    icon: "wb_twilight"
                    value: root.reading(root.wd.sunrise, "--")
                }
                WeatherStat {
                    Layout.alignment: Qt.AlignRight
                    icon: "routine"
                    value: root.reading(root.wd.sunset, "--")
                }
            }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        visible: root.isGlance
        spacing: 2

        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            text: Icons.getWeatherIcon(root.wd.wCode) ?? "cloud"
            fill: 1
            iconSize: Math.round(Math.min(root.width, root.height) * 0.34)
            color: Appearance.colors.colOnLayer1
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.reading(root.wd.temp, "--°")
            font.pixelSize: root.tempFontSize
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
        }
    }

    component WeatherStat: RowLayout {
        id: stat
        property string icon: ""
        property string value: ""
        property bool fillLabel: false
        spacing: 3

        MaterialSymbol {
            text: stat.icon
            iconSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
        }
        StyledText {
            Layout.fillWidth: stat.fillLabel
            text: stat.value
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
        }
    }
}
