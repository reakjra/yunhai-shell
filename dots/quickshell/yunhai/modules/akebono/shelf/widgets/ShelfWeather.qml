import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root
    property real barHeight: 54
    property var shelf
    readonly property real iconSize: Math.round(barHeight * 0.38)

    implicitWidth: pill.implicitWidth
    implicitHeight: barHeight * 0.7
    Layout.alignment: Qt.AlignVCenter

    Squircle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: weatherRow.implicitWidth + 20
        implicitHeight: root.barHeight * 0.7
        radius: height / 2
        color: (weatherMouse.containsMouse || (root.shelf?.weatherOpen ?? false)) ? AkebonoAppearance.shelfPillHoverColor : AkebonoAppearance.shelfPillColor
        readonly property bool hovered: weatherMouse.containsMouse

        Component.onCompleted: root.shelf.registerWeatherAnchor(pill)
        Component.onDestruction: root.shelf.unregisterWeatherAnchor(pill)
        onXChanged: root.shelf.publishWeather()

        RowLayout {
            id: weatherRow
            anchors.centerIn: parent
            spacing: 6

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: Icons.getWeatherIcon(Weather.data?.wCode) ?? "cloud"
                iconSize: root.iconSize
                color: Appearance.colors.colOnLayer1
            }
            StyledText {
                Layout.alignment: Qt.AlignVCenter
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                text: Weather.data?.temp ?? "--°"
            }
        }

        MouseArea {
            id: weatherMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    Weather.getData();
                    Quickshell.execDetached(["notify-send",
                        Translation.tr("Weather"),
                        Translation.tr("Refreshing (manually triggered)"),
                        "-a", "Shell"
                    ]);
                } else {
                    root.shelf.toggleWeather();
                }
            }
        }

        StyledToolTip {
            extraVisibleCondition: (Weather.data?.city ?? "") !== "" && !(root.shelf?.weatherOpen ?? false)
            text: `${Weather.data?.city ?? ""} • ${Translation.tr("Feels like %1").arg(Weather.data?.tempFeelsLike ?? "--°")}`
        }
    }
}
