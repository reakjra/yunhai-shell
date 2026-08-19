pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae

Item {
    id: root

    readonly property var categoryIcons: ({
        "AudioVideo": "headphones",
        "Development": "code",
        "Education": "school",
        "Game": "sports_esports",
        "Graphics": "palette",
        "Network": "language",
        "Office": "description",
        "Science": "science",
        "Settings": "settings",
        "System": "computer",
        "Utility": "build"
    })

    readonly property var categoryLabels: ({
        "AudioVideo": "Media",
        "Development": "Dev",
        "Education": "Edu",
        "Game": "Games",
        "Graphics": "Graphics",
        "Network": "Internet",
        "Office": "Office",
        "Science": "Science",
        "Settings": "Settings",
        "System": "System",
        "Utility": "Utility"
    })

    readonly property int selectedIndex: {
        const cat = LauncherSearch.activeCategory;
        if (cat === "") return 0;
        const cats = LauncherSearch.appCategories;
        for (let i = 0; i < cats.length; i++) {
            if (cats[i] === cat) return i + 1;
        }
        return 0;
    }

    implicitHeight: 44
    implicitWidth: parent?.width ?? 0

    Rectangle {
        anchors.fill: parent
        radius: Appearance.rounding.small
        color: Appearance.colors.colSurfaceContainerHigh

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 0

            MaterialSymbol {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                text: "chevron_left"
                iconSize: Appearance.font.pixelSize.hugeass
                color: Appearance.m3colors.m3onSurface
                opacity: chipRow.atXBeginning ? 0.3 : 1
                horizontalAlignment: Text.AlignHCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: chipRow.flick(600, 0)
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Rectangle {
                    id: activeIndicator
                    z: 0
                    color: Appearance.colors.colPrimaryContainer
                    radius: Appearance.rounding.small
                    height: 36
                    y: (parent.height - height) / 2

                    property Item targetItem: null
                    x: targetItem ? targetItem.x - chipRow.contentX + chipRow.x : 0
                    width: targetItem ? targetItem.width : 0
                    visible: targetItem !== null

                    Timer {
                        interval: 0
                        running: true
                        onTriggered: activeIndicator.targetItem = Qt.binding(() => chipRow.itemAtIndex(root.selectedIndex))
                    }

                    Behavior on x {
                        enabled: !chipRow.moving
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    Behavior on width {
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

                    model: ["All", ...LauncherSearch.appCategories]

                    delegate: Item {
                        id: chip
                        required property string modelData
                        required property int index

                        readonly property bool selected: modelData === "All"
                            ? LauncherSearch.activeCategory === ""
                            : LauncherSearch.activeCategory === modelData

                        implicitWidth: chipContent.implicitWidth + 24
                        height: 36
                        anchors.verticalCenter: parent?.verticalCenter ?? undefined

                        RowLayout {
                            id: chipContent
                            anchors.centerIn: parent
                            spacing: 6

                            MaterialSymbol {
                                text: chip.modelData === "All" ? "apps" : (root.categoryIcons[chip.modelData] ?? "category")
                                iconSize: Appearance.font.pixelSize.large
                                color: chip.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.m3colors.m3onSurface

                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }
                            }

                            StyledText {
                                text: chip.modelData === "All" ? "All" : (root.categoryLabels[chip.modelData] ?? chip.modelData)
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: chip.selected ? Appearance.colors.colOnPrimaryContainer : Appearance.m3colors.m3onSurface

                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: LauncherSearch.activeCategory = chip.modelData === "All" ? "" : chip.modelData
                        }
                    }
                }
            }

            MaterialSymbol {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                text: "chevron_right"
                iconSize: Appearance.font.pixelSize.hugeass
                color: Appearance.m3colors.m3onSurface
                opacity: chipRow.atXEnd ? 0.3 : 1
                horizontalAlignment: Text.AlignHCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: chipRow.flick(-600, 0)
                }
            }
        }
    }
}
