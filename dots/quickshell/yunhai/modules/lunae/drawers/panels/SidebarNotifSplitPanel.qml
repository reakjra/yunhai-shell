pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae
import qs.modules.lunae.sidebarRight.notifications

Panel {
    id: root

    required property real frameInset
    required property real screenHeight

    readonly property real contentWidth: Appearance.sizes.sidebarWidth
    readonly property real armpitSize: LunaeAppearance.rounding.armpit
    readonly property real cornerSize: LunaeAppearance.rounding.panelSmall
    readonly property real naturalWidth: armpitSize + contentWidth

    readonly property real maxContentHeight: 560
    readonly property real rawContentHeight: armpitSize + 8 + controlsGroup.implicitHeight + 8 + Math.max(120, notifList.listContentHeight + 10) + 8 + armpitSize
    readonly property real naturalHeight: Math.min(rawContentHeight, maxContentHeight)

    property alias hoverHandler: hoverHandler

    axis: Panel.Axis.Horizontal
    shouldShow: (Config.options.lunae?.sidebar?.splitMode ?? false) && GlobalStates.sidebarNotifOpen
    naturalSize: naturalWidth
    deformAmount: 0.06

    anchors.right: parent.right
    anchors.rightMargin: root.frameInset - root.slideOffset
    anchors.top: parent.top
    anchors.topMargin: root.frameInset

    implicitHeight: naturalHeight

    Behavior on implicitHeight {
        NumberAnimation {
            duration: LunaeAppearance.notifExpansionDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: LunaeAppearance.notifExpansionCurve
        }
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.leftMargin: root.armpitSize + 12
        anchors.top: parent.top
        anchors.topMargin: root.armpitSize - 11
        width: root.contentWidth - 24
        height: root.height - (root.armpitSize + 26)
        spacing: 12

        ButtonGroup {
            id: controlsGroup
            Layout.fillWidth: true
            color: Appearance.colors.colLayer1
            spacing: 8
            padding: 6

            NotificationStatusButton {
                Layout.fillWidth: false
                buttonIcon: "notifications_paused"
                toggled: Notifications.silent
                onClicked: () => {
                    Notifications.silent = !Notifications.silent;
                }
            }
            NotificationStatusButton {
                enabled: false
                Layout.fillWidth: true
                buttonText: Translation.tr("%1 notifications").arg(Notifications.list.length)
                fontFamily: Appearance.font.family.monospace
            }
            NotificationStatusButton {
                Layout.fillWidth: false
                buttonIcon: "delete_sweep"
                onClicked: () => {
                    Notifications.discardAllNotifications()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: LunaeAppearance.rounding.panelSmall
            color: Appearance.colors.colLayer1

            NotificationList {
                id: notifList
                anchors.fill: parent
                anchors.margins: 10
                showStatusRow: false
                placeholderIconSize: 36
            }
        }
    }

    HoverHandler { id: hoverHandler; margin: root.frameInset + 2 }
}
