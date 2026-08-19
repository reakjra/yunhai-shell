pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Item {
    id: root

    property int currentTab: 0
    property real targetWidth: width
    signal tabClicked(int index)

    implicitHeight: tabRow.height + 3 + 1

    Row {
        id: tabRow
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 8
            rightMargin: 8
        }

        Repeater {
            id: tabRepeater
            model: HubContext.availableTabs

            Item {
                id: tabBtn
                required property var modelData
                required property int index

                readonly property bool current: index === root.currentTab
                readonly property real contentWidth: tabContent.implicitWidth

                width: tabRow.width / Math.max(1, HubContext.tabCount)
                implicitHeight: tabContent.implicitHeight + 16

                Rectangle {
                    anchors.fill: parent
                    radius: Appearance.rounding.small
                    color: tabBtn.current ? Appearance.m3colors.m3primary : Appearance.colors.colOnLayer1
                    opacity: tabMouseArea.pressed ? 0.1 : tabMouseArea.containsMouse ? 0.08 : 0
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }

                MouseArea {
                    id: tabMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.tabClicked(tabBtn.index)
                }

                Column {
                    id: tabContent
                    anchors.centerIn: parent
                    spacing: 2

                    MaterialSymbol {
                        id: tabIcon
                        anchors.horizontalCenter: parent.horizontalCenter
                        iconSize: 24
                        text: tabBtn.modelData.icon
                        fill: tabBtn.current ? 1 : 0
                        color: tabBtn.current ? Appearance.m3colors.m3primary : Appearance.colors.colOnLayer1
                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }
                    }

                    StyledText {
                        id: tabLabel
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tabBtn.modelData.label
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: tabBtn.current ? Appearance.m3colors.m3primary : Appearance.colors.colOnLayer1
                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: indicator
        anchors.bottom: separator.top
        height: 3

        property real rowPadding: 8
        property real cellWidth: (root.targetWidth - rowPadding * 2) / Math.max(1, HubContext.tabCount)
        property real contentW: {
            const n = tabRepeater.count
            const item = n > 0 ? tabRepeater.itemAt(root.currentTab) : null
            return item && item.contentWidth > 0 ? item.contentWidth : cellWidth
        }

        x: rowPadding + root.currentTab * cellWidth + (cellWidth - contentW) / 2
        width: contentW

        Behavior on x {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
        Behavior on width {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        topLeftRadius: height
        topRightRadius: height
        bottomLeftRadius: 0
        bottomRightRadius: 0
        color: Appearance.colors.colPrimary
    }

    Rectangle {
        id: separator
        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            leftMargin: 12
            rightMargin: 12
        }
        height: 1
        color: Appearance.colors.colOutlineVariant
    }

    WheelHandler {
        onWheel: (event) => {
            const maxTab = HubContext.tabCount - 1;
            if (event.angleDelta.y < 0)
                root.tabClicked(Math.min(root.currentTab + 1, maxTab));
            else if (event.angleDelta.y > 0)
                root.tabClicked(Math.max(root.currentTab - 1, 0));
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }
}
