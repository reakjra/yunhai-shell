import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

MouseArea {
    id: root
    readonly property bool isCharging: Battery.isCharging
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= Config.options.battery.low / 100
    readonly property color accentColor: (isLow && !isCharging)
        ? Appearance.m3colors.m3error
        : Appearance.colors.colOnSecondaryContainer

    implicitHeight: pill.implicitHeight
    implicitWidth: Appearance.sizes.verticalBarWidth
    hoverEnabled: !Config.options.bar.tooltips.clickToShow

    onClicked: {
        if (hoverEnabled) return
        if (GlobalStates.activeBarPopup === "battery")
            GlobalStates.activeBarPopup = ""
        else {
            const pos = root.mapToItem(null, 0, root.height / 2)
            GlobalStates.barPopupY = pos.y
            GlobalStates.activeBarPopup = "battery"
        }
    }

    onContainsMouseChanged: {
        if (!hoverEnabled) return
        if (containsMouse) {
            const pos = root.mapToItem(null, 0, root.height / 2)
            GlobalStates.barPopupY = pos.y
            GlobalStates.activeBarPopup = "battery"
        } else {
            GlobalStates.activeBarPopup = ""
        }
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        implicitWidth: col.implicitWidth + 4 * 2
        implicitHeight: col.implicitHeight + 4 * 2
        radius: Appearance.rounding.full
        color: Appearance.colors.colLayer1Hover

        ColumnLayout {
            id: col
            anchors.centerIn: parent
            spacing: 4

            CircularProgress {
                Layout.alignment: Qt.AlignHCenter
                implicitSize: 26
                lineWidth: 3
                value: root.percentage
                colPrimary: root.accentColor
                colSecondary: Qt.alpha(root.accentColor, 0.3)
                enableAnimation: false

                MaterialSymbol {
                    anchors.centerIn: parent
                    fill: 1
                    text: root.isCharging ? "bolt" : "battery_android_6"
                    iconSize: 14
                    color: root.accentColor
                    rotation: -90
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.small
                color: Config.options.lunae.colorful ? Appearance.colors.colSecondary : Appearance.colors.colOnLayer1
                text: Math.round(root.percentage * 100)
            }
        }
    }
}
