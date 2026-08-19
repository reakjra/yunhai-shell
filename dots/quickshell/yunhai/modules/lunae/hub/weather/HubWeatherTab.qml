import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                text: Weather.data.city || Translation.tr("Weather")
                font.pixelSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnLayer1
            }
            Item { Layout.fillWidth: true }
            StyledText {
                text: DateTime.longDate
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.m3colors.m3outline
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            MaterialSymbol {
                text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
                iconSize: 56
                color: Appearance.m3colors.m3secondary
            }

            ColumnLayout {
                spacing: 4

                StyledText {
                    text: Weather.data.temp || "--"
                    font.pixelSize: 40
                    font.family: Appearance.font.family.numbers
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    text: Translation.tr("Feels like %1").arg(Weather.data.tempFeelsLike || "--")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.m3colors.m3outline
                }
            }

            Item { Layout.fillWidth: true }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            WeatherCard {
                Layout.fillWidth: true
                icon: "humidity_percentage"
                label: Translation.tr("Humidity")
                value: Weather.data.humidity || "--"
                colour: Appearance.colors.colPrimary
            }

            WeatherCard {
                Layout.fillWidth: true
                icon: "air"
                label: Translation.tr("Wind")
                value: Weather.data.wind || "--"
                colour: Appearance.m3colors.m3secondary
            }

            WeatherCard {
                Layout.fillWidth: true
                icon: "visibility"
                label: Translation.tr("Visibility")
                value: Weather.data.visib || "--"
                colour: Appearance.m3colors.m3tertiary
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            WeatherCard {
                Layout.fillWidth: true
                icon: "sunny"
                label: "UV"
                value: String(Weather.data.uv || 0)
                colour: Appearance.colors.colPrimary
            }

            WeatherCard {
                Layout.fillWidth: true
                icon: "compress"
                label: Translation.tr("Pressure")
                value: Weather.data.press || "--"
                colour: Appearance.m3colors.m3secondary
            }

            WeatherCard {
                Layout.fillWidth: true
                icon: "water_drop"
                label: Translation.tr("Precip")
                value: Weather.data.precip || "--"
                colour: Appearance.m3colors.m3tertiary
            }
        }

        Item { Layout.fillHeight: true }

        StyledText {
            Layout.alignment: Qt.AlignRight
            text: Weather.data.lastRefresh ? Translation.tr("Updated: %1").arg(Weather.data.lastRefresh) : ""
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: Appearance.m3colors.m3outline
        }
    }

    component WeatherCard: Rectangle {
        id: card
        required property string icon
        required property string label
        required property string value
        required property color colour

        implicitHeight: 64
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 4

            RowLayout {
                spacing: 4
                MaterialSymbol {
                    text: card.icon
                    iconSize: 16
                    color: card.colour
                }
                StyledText {
                    text: card.label
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.m3colors.m3outline
                }
            }

            StyledText {
                text: card.value
                font.pixelSize: Appearance.font.pixelSize.large
                font.family: Appearance.font.family.numbers
                color: card.colour
            }
        }
    }
}
