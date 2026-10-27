import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell.Services.Notifications
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Item {
    id: root

    property bool clearAllDialogOpen: false

    Component.onCompleted: Notifications.markAllRead()

    StyledFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.implicitHeight
        clip: true

        ColumnLayout {
            id: column
            width: flickable.width
            spacing: 16

            NotificationsHero {
                Layout.fillWidth: true
                onClearAllRequested: root.clearAllDialogOpen = true
            }

            ListCard {
                visible: Notifications.list.length === 0
                emptyText: Translation.tr("No notifications")
            }

            Repeater {
                model: Notifications.appNameList
                delegate: ColumnLayout {
                    id: appSection
                    required property string modelData
                    readonly property var group: Notifications.groupsByAppName[modelData]

                    Layout.fillWidth: true
                    Layout.bottomMargin: 8
                    spacing: 16

                    SectionHeader {
                        title: appSection.modelData || Translation.tr("Unknown app")

                        Pill {
                            clickable: true
                            icon: "clear_all"
                            text: Translation.tr("Clear")
                            onClicked: Notifications.discardAppNotifications(appSection.modelData)
                        }
                    }

                    ListCard {
                        values: appSection.group?.notifications.slice().reverse() ?? []
                        delegate: ListRow {
                            id: row
                            required property var modelData
                            readonly property bool hasDefaultAction: modelData.actions.some(action => action.identifier === "default")

                            Layout.fillWidth: true
                            leading: NotificationAppIcon {
                                implicitSize: Appearance.font.pixelSize.huge * 1.8
                                appIcon: row.modelData.appIcon
                                image: row.modelData.image
                                summary: row.modelData.summary
                                urgency: row.modelData.urgency === NotificationUrgency.Critical.toString() ? NotificationUrgency.Critical : NotificationUrgency.Normal
                            }
                            title: modelData.summary
                            subtitle: NotificationUtils.plainNotificationBody(modelData.body, modelData.appName)
                            trailingText: NotificationUtils.getFriendlyNotifTimeString(modelData.time)
                            hoverActionAvailable: true
                            hoverActionIcon: "close"
                            hoverActionTooltip: Translation.tr("Dismiss")
                            onHoverActionClicked: Notifications.discardNotification(modelData.notificationId)
                            onClicked: if (row.hasDefaultAction) Notifications.attemptInvokeAction(modelData.notificationId, "default")
                        }
                    }
                }
            }
        }
    }

    Item {
        parent: root.Window.window?.contentItem ?? root
        anchors.fill: parent
        z: 1

        WindowDialogLoader {
            shown: root.clearAllDialogOpen
            onDismissed: root.clearAllDialogOpen = false
            dialog: ConfirmDialog {
                title: Translation.tr("Clear all notifications?")
                body: Translation.tr("This removes the whole history.")
                confirmText: Translation.tr("Clear all")
                onConfirmed: Notifications.discardAllNotifications()
            }
        }
    }
}
