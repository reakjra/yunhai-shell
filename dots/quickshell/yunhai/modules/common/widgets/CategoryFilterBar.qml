pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property color backgroundColor: Appearance.colors.colSurfaceContainerHigh
    property color indicatorColor: Appearance.colors.colPrimaryContainer
    property color indicatorTextColor: Appearance.colors.colOnPrimaryContainer
    property color textColor: Appearance.m3colors.m3onSurface
    property real radius: Appearance.rounding.small
    property real smoothing: 2
    property real chipHeight: 36

    readonly property var sections: LauncherSearch.sections.filter(section => section.key !== LauncherSearch.pinnedSection)
    readonly property int selectedIndex: Math.max(0, root.sections.findIndex(section => LauncherSearch.categoryForSection(section.key) === LauncherSearch.activeCategory))

    implicitHeight: root.chipHeight + 8

    Squircle {
        anchors.fill: parent
        radius: root.radius
        smoothing: root.smoothing
        color: root.backgroundColor
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 4
        anchors.rightMargin: 4
        spacing: 0

        ScrollChevron {
            glyph: "chevron_left"
            atEnd: chipRow.atXBeginning
            onClicked: chipRow.flick(600, 0)
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Squircle {
                id: activeIndicator
                parent: chipRow.contentItem
                z: -1
                color: root.indicatorColor
                radius: root.radius
                smoothing: root.smoothing
                height: root.chipHeight

                property Item targetItem: null
                property bool placed: false
                x: targetItem ? targetItem.x : 0
                y: targetItem ? targetItem.y : 0
                width: targetItem ? targetItem.width : 0
                visible: targetItem !== null

                Timer {
                    interval: 0
                    running: true
                    onTriggered: {
                        activeIndicator.targetItem = Qt.binding(() => chipRow.itemAtIndex(root.selectedIndex));
                        activeIndicator.placed = true;
                    }
                }

                Behavior on x {
                    enabled: activeIndicator.placed
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on width {
                    enabled: activeIndicator.placed
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            ListView {
                id: chipRow
                z: 1
                anchors.fill: parent
                orientation: Qt.Horizontal
                spacing: 4
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.sections

                delegate: Item {
                    id: chip
                    required property var modelData
                    required property int index
                    readonly property bool selected: chip.index === root.selectedIndex

                    implicitWidth: chipContent.implicitWidth + 24
                    height: root.chipHeight
                    anchors.verticalCenter: parent?.verticalCenter ?? undefined

                    RowLayout {
                        id: chipContent
                        anchors.centerIn: parent
                        spacing: 6

                        MaterialSymbol {
                            text: chip.modelData.icon
                            iconSize: Appearance.font.pixelSize.large
                            color: chip.selected ? root.indicatorTextColor : root.textColor

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }
                        }

                        StyledText {
                            text: chip.modelData.label
                            font.pixelSize: Appearance.font.pixelSize.normal
                            color: chip.selected ? root.indicatorTextColor : root.textColor

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: LauncherSearch.activeCategory = LauncherSearch.categoryForSection(chip.modelData.key)
                    }
                }
            }

            HorizontalWheelArea {
                z: 2
                anchors.fill: chipRow
                flickable: chipRow
            }
        }

        ScrollChevron {
            glyph: "chevron_right"
            atEnd: chipRow.atXEnd
            onClicked: chipRow.flick(-600, 0)
        }
    }

    component ScrollChevron: MaterialSymbol {
        id: chevron
        property string glyph: ""
        property bool atEnd: false
        signal clicked()

        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        text: chevron.glyph
        iconSize: Appearance.font.pixelSize.hugeass
        color: root.textColor
        opacity: chevron.atEnd ? 0.3 : 1
        horizontalAlignment: Text.AlignHCenter

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: chevron.clicked()
        }
    }
}
