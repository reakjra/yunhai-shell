pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.ii.bar.weather
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitHeight: weatherColumn.implicitHeight
    implicitWidth: Appearance.sizes.verticalBarWidth

    ColumnLayout {
        id: weatherColumn
        anchors.centerIn: parent
        spacing: 2

        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            fill: 0
            text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
            iconSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colOnLayer1
            text: Weather.data?.temp ?? "--°"
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPressed: mouse => {
            if (mouse.button === Qt.RightButton) {
                Weather.getData();
                Quickshell.execDetached(["notify-send",
                    Translation.tr("Weather"),
                    Translation.tr("Refreshing (manually triggered)")
                    , "-a", "Shell"
                ])
                mouse.accepted = false
            }
        }

        WeatherPopup {
            id: weatherPopup
            hoverTarget: mouseArea
        }
    }
}
