pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

MouseArea {
    id: root

    required property var notification

    readonly property real padding: 12
    readonly property real cardSpacing: 10
    readonly property real imageSize: Appearance.font.pixelSize.huge * 2.4
    readonly property real appIconSize: Appearance.font.pixelSize.normal
    readonly property real headerIconSize: Appearance.font.pixelSize.large
    readonly property real dragDismissThreshold: 100

    hoverEnabled: true
    implicitHeight: card.implicitHeight

    onContainsMouseChanged: {
        if (root.containsMouse)
            Notifications.cancelTimeout(root.notification.notificationId);
        else
            Notifications.timeoutNotification(root.notification.notificationId);
    }

    drag.target: card
    drag.axis: Drag.XAxis
    drag.minimumX: 0
    drag.onActiveChanged: {
        if (drag.active)
            return;
        if (card.x > root.dragDismissThreshold)
            slideOut.start();
        else
            card.x = 0;
    }

    function dismiss() {
        Notifications.discardNotification(root.notification.notificationId);
    }

    component HeaderButton: MouseArea {
        id: headerButton
        property string icon: ""
        implicitWidth: root.headerIconSize + 6
        implicitHeight: root.headerIconSize + 6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        MaterialSymbol {
            anchors.centerIn: parent
            iconSize: root.headerIconSize
            text: headerButton.icon
            color: headerButton.containsMouse ? Appearance.colors.colOnLayer2 : Appearance.colors.colSubtext
            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }

    NumberAnimation {
        id: slideOut
        target: card
        property: "x"
        to: root.width
        duration: Appearance.animation.elementMove.duration
        easing.type: Appearance.animation.elementMove.type
        easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        onFinished: root.dismiss()
    }

    Rectangle {
        id: card
        width: parent.width
        implicitHeight: content.implicitHeight + root.padding * 2
        radius: Appearance.rounding.small
        color: Appearance.colors.colLayer1
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        Behavior on x {
            enabled: !root.drag.active
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: root.padding
            spacing: root.cardSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                IconImage {
                    visible: root.notification.appIcon !== ""
                    implicitSize: root.appIconSize
                    asynchronous: true
                    source: Quickshell.iconPath(root.notification.appIcon, "image-missing")
                }

                StyledText {
                    Layout.fillWidth: true
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer2
                    elide: Text.ElideRight
                    text: root.notification.appName
                }

                HeaderButton {
                    icon: "settings"
                    onClicked: Quickshell.execDetached(["env", "YUNHAI_SETTINGS_PAGE=modules/settings/InterfaceConfig.qml", "YUNHAI_SETTINGS_SECTION=notifications", "qs", "-p", Quickshell.shellPath("settings.qml")])
                }

                HeaderButton {
                    icon: "close"
                    onClicked: root.dismiss()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: root.cardSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 2

                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.small
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer2
                        wrapMode: Text.Wrap
                        text: root.notification.summary
                    }

                    StyledText {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                        wrapMode: Text.Wrap
                        textFormat: Text.RichText
                        text: `<style>img{max-width:${width}px;}</style>` + NotificationUtils.processNotificationBody(root.notification.body, root.notification.appName).replace(/\n/g, "<br/>")
                        onLinkActivated: link => Qt.openUrlExternally(link)

                        PointingHandLinkHover {}
                    }
                }

                Item {
                    visible: root.notification.image !== ""
                    Layout.alignment: Qt.AlignVCenter
                    implicitWidth: root.imageSize
                    implicitHeight: root.imageSize

                    Image {
                        id: notificationImage
                        anchors.fill: parent
                        source: root.notification.image
                        fillMode: Image.PreserveAspectCrop
                        cache: false
                        antialiasing: true
                        asynchronous: true
                        sourceSize.width: root.imageSize
                        sourceSize.height: root.imageSize

                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: notificationImage.width
                                height: notificationImage.height
                                radius: Appearance.rounding.full
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: root.cardSpacing / 2
                visible: root.notification.actions.length > 0
                spacing: 6

                Repeater {
                    model: root.notification.actions

                    NotificationActionButton {
                        required property var modelData
                        Layout.fillWidth: true
                        buttonText: modelData.text
                        urgency: root.notification.urgency
                        onClicked: Notifications.attemptInvokeAction(root.notification.notificationId, modelData.identifier)
                    }
                }
            }
        }
    }
}
