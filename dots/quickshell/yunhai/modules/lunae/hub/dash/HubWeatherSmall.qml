import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - 24
        spacing: 4

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            MaterialSymbol {
                text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
                iconSize: 42
                color: Appearance.m3colors.m3secondary
            }

            StyledText {
                text: Weather.data.temp || "--"
                font.pixelSize: Appearance.font.pixelSize.hugeass
                font.family: Appearance.font.family.numbers
                color: Appearance.colors.colPrimary
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Weather.data.city || Translation.tr("Weather")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            elide: Text.ElideRight
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Translation.tr("Feels like %1").arg(Weather.data.tempFeelsLike || "--")
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: Appearance.m3colors.m3outline
            visible: Weather.data.tempFeelsLike !== undefined
        }
    }
}
