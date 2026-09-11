pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property var shelf
    signal closeRequested()

    readonly property var wd: Weather.data

    implicitWidth: 350
    implicitHeight: col.implicitHeight + 36

    component InfoChip: Squircle {
        id: chip
        property string icon
        property string label
        property string value
        Layout.fillWidth: true
        implicitHeight: 54
        radius: 16
        color: Appearance.colors.colLayer1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: chip.icon
                iconSize: 22
                color: Appearance.colors.colPrimary
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: chip.value
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    text: chip.label
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }
            }
        }
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: root.wd?.temp ?? "--°"
                    font.pixelSize: 42
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                }
                StyledText {
                    Layout.fillWidth: true
                    text: `${root.wd?.city ?? ""} • ${Translation.tr("Feels like %1").arg(root.wd?.tempFeelsLike ?? "--°")}`
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }
            }

            Squircle {
                implicitWidth: 50
                implicitHeight: 50
                radius: 17
                color: Appearance.colors.colPrimaryContainer

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: Icons.getWeatherIcon(root.wd?.wCode) ?? "cloud"
                    fill: 1
                    iconSize: 27
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }
        }

        Squircle {
            Layout.fillWidth: true
            implicitHeight: 118
            radius: 20
            color: Appearance.colors.colLayer1

            SunArc {
                anchors.fill: parent
                anchors.margins: 12
                sunrise: root.wd.sunrise
                sunset: root.wd.sunset
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8
            rowSpacing: 8

            InfoChip {
                icon: "air"
                label: Translation.tr("Wind")
                value: `${root.wd?.wind ?? "--"} ${root.wd?.windDir ?? ""}`
            }
            InfoChip {
                icon: "humidity_percentage"
                label: Translation.tr("Humidity")
                value: String(root.wd?.humidity ?? "--")
            }
            InfoChip {
                icon: "rainy"
                label: Translation.tr("Precipitation")
                value: String(root.wd?.precip ?? "--")
            }
            InfoChip {
                icon: "wb_sunny"
                label: Translation.tr("UV index")
                value: String(root.wd?.uv ?? "--")
            }
            InfoChip {
                icon: "visibility"
                label: Translation.tr("Visibility")
                value: String(root.wd?.visib ?? "--")
            }
            InfoChip {
                icon: "compress"
                label: Translation.tr("Pressure")
                value: String(root.wd?.press ?? "--")
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Translation.tr("Updated %1").arg(root.wd?.lastRefresh ?? "--")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }
    }
}
