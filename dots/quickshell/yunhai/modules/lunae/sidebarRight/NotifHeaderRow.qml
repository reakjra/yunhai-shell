import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae.sidebarRight.notifications

ButtonGroup {
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
