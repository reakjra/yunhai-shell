pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae
import qs.modules.lunae.bar

ColumnLayout {
    id: root
    spacing: 5

    component WeatherCard: Rectangle {
        radius: LunaeAppearance.rounding.panelSmall
        color: Appearance.colors.colSurfaceContainerHigh
        implicitWidth: cardLayout.implicitWidth + 14 * 2
        implicitHeight: cardLayout.implicitHeight + 14 * 2
        Layout.fillWidth: true

        property alias title: cardTitle.text
        property alias value: cardValue.text
        property alias symbol: cardSymbol.text

        ColumnLayout {
            id: cardLayout
            anchors.fill: parent
            spacing: -10
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                MaterialSymbol {
                    id: cardSymbol
                    fill: 0
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnSurfaceVariant
                }
                StyledText {
                    id: cardTitle
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSurfaceVariant
                }
            }
            StyledText {
                id: cardValue
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSurfaceVariant
            }
        }
    }

    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 2

        StyledPopupHeaderRow {
            Layout.alignment: Qt.AlignHCenter
            icon: "location_on"
            label: Weather.data.city
        }
        StyledText {
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnSurfaceVariant
            text: Weather.data.temp + " • " + Translation.tr("Feels like %1").arg(Weather.data.tempFeelsLike)
        }
    }

    GridLayout {
        columns: 2
        rowSpacing: 5
        columnSpacing: 5
        uniformCellWidths: true

        WeatherCard {
            title: Translation.tr("UV Index")
            symbol: "wb_sunny"
            value: Weather.data.uv
        }
        WeatherCard {
            title: Translation.tr("Wind")
            symbol: "air"
            value: `(${Weather.data.windDir}) ${Weather.data.wind}`
        }
        WeatherCard {
            title: Translation.tr("Precipitation")
            symbol: "rainy_light"
            value: Weather.data.precip
        }
        WeatherCard {
            title: Translation.tr("Humidity")
            symbol: "humidity_low"
            value: Weather.data.humidity
        }
        WeatherCard {
            title: Translation.tr("Visibility")
            symbol: "visibility"
            value: Weather.data.visib
        }
        WeatherCard {
            title: Translation.tr("Pressure")
            symbol: "readiness_score"
            value: Weather.data.press
        }
        WeatherCard {
            title: Translation.tr("Sunrise")
            symbol: "wb_twilight"
            value: Weather.data.sunrise
        }
        WeatherCard {
            title: Translation.tr("Sunset")
            symbol: "bedtime"
            value: Weather.data.sunset
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Translation.tr("Last refresh: %1").arg(Weather.data.lastRefresh)
        font {
            weight: Font.Medium
            pixelSize: Appearance.font.pixelSize.smaller
        }
        color: Appearance.colors.colOnSurfaceVariant
    }
}
