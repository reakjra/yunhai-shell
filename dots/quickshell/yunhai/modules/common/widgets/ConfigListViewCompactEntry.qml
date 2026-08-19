import QtQuick
import QtQuick.Layouts

import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: wrapper

    required property var modelData

    property color colBackground: visualIndex % 2 == 0 ? Appearance.colors.colLayer3 : Appearance.colors.colLayer2
    property color colActive: visualIndex % 2 == 0 ? Appearance.colors.colLayer3Active : Appearance.colors.colLayer2Active

    anchors {
        right: parent?.right
        left: parent?.left
    }
    height: content.height
    property int visualIndex: DelegateModel.itemsIndex

    Behavior on y {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    function getOrderedList() {
        var ordered = []
        for (var i = 0; i < visualModel.items.count; i++) {
            ordered.push(visualModel.items.get(i).model.modelData)
        }
        return ordered
    }

    property real bottomRadius: {
        if (listModel.length == 1 || visualIndex == listModel.length - 1) return Appearance.rounding.full
        return Appearance.rounding.verysmall
    }
    property real topRadius: {
        if (listModel.length == 1 || visualIndex == 0) return Appearance.rounding.full
        return Appearance.rounding.verysmall
    }

    Rectangle {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
        }

        scale: dragArea.held ? 1.02 : 1
        opacity: dragArea.held ? 0.8 : 1

        Behavior on scale {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }
        Behavior on opacity {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }

        topLeftRadius: topRadius
        topRightRadius: topRadius
        bottomLeftRadius: bottomRadius
        bottomRightRadius: bottomRadius

        height: 36

        color: dragArea.held ? colActive : colBackground
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        Drag.active: dragArea.held
        Drag.source: dragArea
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        states: State {
            when: dragArea.held
            ParentChange {
                target: content
                parent: root
            }
            AnchorChanges {
                target: content
                anchors {
                    left: undefined
                    right: undefined
                    verticalCenter: undefined
                }
            }
        }

        RowLayout {
            id: contentRow
            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 8
                rightMargin: 8
            }
            spacing: 6

            MaterialSymbol {
                text: "drag_indicator"
                iconSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOutline
            }

            MaterialSymbol {
                text: modelData.icon
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colPrimary
                fill: 1
            }

            StyledText {
                text: modelData.title
                color: Appearance.colors.colOnLayer0
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.small
            }

            RippleButton {
                implicitWidth: 24
                implicitHeight: 24
                buttonRadius: Appearance.rounding.full
                onClicked: {
                    if (modelData != null) {
                        root.sourceListModel.push(modelData)
                        root.sourceUpdated(root.sourceListModel)
                    }
                    let arr = wrapper.getOrderedList()
                    arr.splice(visualIndex, 1)
                    root.updated(arr)
                }

                MaterialSymbol {
                    text: "close"
                    anchors.centerIn: parent
                    color: Appearance.colors.colPrimary
                    iconSize: Appearance.font.pixelSize.normal
                }
            }
        }
    }

    DropArea {
        anchors {
            fill: parent
            margins: 4
        }
        onEntered: (drag) => {
            visualModel.items.move(drag.source.parent.visualIndex, wrapper.visualIndex)
        }
    }

    MouseArea {
        id: dragArea
        property bool held: false
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        width: 30
        pressAndHoldInterval: 200
        drag.target: held ? content : undefined
        drag.axis: Drag.YAxis
        drag.minimumY: 0
        drag.maximumY: root.listModel.length * 36 + (root.listModel.length - 1) * 2

        onPressAndHold: held = true
        onReleased: {
            root.updated(wrapper.getOrderedList())
            held = false
        }
    }
}
