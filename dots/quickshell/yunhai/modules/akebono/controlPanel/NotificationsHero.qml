import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

HeroCard {
    id: root

    readonly property int count: Notifications.list.length
    readonly property int appCount: Notifications.appNameList.length

    signal clearAllRequested()

    title: Translation.tr("Notifications")
    subtitle: {
        if (root.count === 0)
            return Translation.tr("You're all caught up");
        if (root.count === 1)
            return Translation.tr("1 notification");
        if (root.appCount === 1)
            return Translation.tr("%1 notifications").arg(root.count);
        return Translation.tr("%1 notifications from %2 apps").arg(root.count).arg(root.appCount);
    }
    switchChecked: !Notifications.silent
    onSwitchToggled: checked => Notifications.silent = !checked

    glyph: MaterialSymbol {
        anchors.centerIn: parent
        text: Notifications.silent ? "notifications_paused" : "notifications"
        iconSize: root.glyphSize
        fill: 1
        color: Appearance.colors.colOnPrimaryContainer
    }

    Flow {
        Layout.fillWidth: true
        visible: Notifications.silent || root.count > 0
        spacing: 6

        Pill {
            visible: Notifications.silent
            icon: "do_not_disturb_on"
            text: Translation.tr("Do not disturb")
        }
        Pill {
            visible: root.count > 0
            clickable: true
            icon: "clear_all"
            text: Translation.tr("Clear all")
            onClicked: root.clearAllRequested()
        }
    }
}
