pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Row {
    id: root

    property bool menuOpen: false
    property Item menuOverlay: null
    readonly property real pillHeight: 34
    readonly property real openRadius: Appearance.rounding.small / 2

    readonly property var activePlayer: MprisController.activePlayer
    readonly property var activeEntry: {
        DesktopEntries.applications.values;
        const id = activePlayer?.desktopEntry ?? "";
        return id ? DesktopEntries.byId(id) : null;
    }

    readonly property real closedWidth: pillRow.implicitWidth + 20
    readonly property real menuMaxWidth: {
        let maxW = 0;
        for (let i = 0; i < Mpris.players.values.length; i++) {
            const player = Mpris.players.values[i];
            const entry = player.desktopEntry ? DesktopEntries.byId(player.desktopEntry) : null;
            const name = entry?.name ?? player.identity ?? "Player";
            maxW = Math.max(maxW, name.length * 8 + 56);
        }
        return Math.min(Math.max(maxW, root.closedWidth), 220);
    }
    readonly property real openWidth: Math.max(closedWidth, menuMaxWidth)

    signal playerSelected(player: var)

    spacing: 2

    Rectangle {
        id: leftPill

        height: root.pillHeight
        width: root.menuOpen ? root.openWidth : root.closedWidth
        radius: root.pillHeight / 2
        topLeftRadius: root.menuOpen ? root.openRadius : radius
        topRightRadius: root.menuOpen ? root.openRadius : radius

        color: leftMa.containsMouse || root.menuOpen
            ? Appearance.colors.colSecondaryContainerHover
            : Appearance.colors.colSecondaryContainer

        Behavior on width { NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on topLeftRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on topRightRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 6

            IconImage {
                anchors.verticalCenter: parent.verticalCenter
                source: root.activeEntry?.icon ? Quickshell.iconPath(root.activeEntry.icon) : ""
                implicitSize: 16
                visible: status === Image.Ready
            }

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: "animated_images"
                iconSize: 16
                color: Appearance.colors.colOnSecondaryContainer
                visible: !root.activeEntry?.icon && root.activePlayer !== null
            }

            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: root.activeEntry?.name ?? root.activePlayer?.identity ?? Translation.tr("No player")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnSecondaryContainer
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        MouseArea {
            id: leftMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.menuOpen = !root.menuOpen
        }
    }

    Rectangle {
        id: rightPill

        height: root.pillHeight
        width: root.pillHeight
        radius: root.pillHeight / 2
        topLeftRadius: root.menuOpen ? root.openRadius : radius
        topRightRadius: root.menuOpen ? root.openRadius : radius

        color: rightMa.containsMouse || root.menuOpen
            ? Appearance.colors.colSecondaryContainerHover
            : Appearance.colors.colSecondaryContainer

        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on topLeftRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on topRightRadius { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        MaterialSymbol {
            anchors.centerIn: parent
            text: "expand_more"
            iconSize: 18
            color: Appearance.colors.colOnSecondaryContainer
            rotation: root.menuOpen ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            id: rightMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.menuOpen = !root.menuOpen
        }
    }

    Loader {
        parent: root.menuOverlay
        active: root.menuOpen && root.menuOverlay !== null

        sourceComponent: Item {
            anchors.fill: parent

            MouseArea {
                anchors.fill: parent
                onClicked: root.menuOpen = false
            }

            Rectangle {
                id: panel

                readonly property point pillPos: {
                    root.x;
                    root.y;
                    root.width;
                    leftPill.width;
                    return leftPill.mapToItem(root.menuOverlay, 0, 0);
                }
                property bool shown: false
                Component.onCompleted: shown = true

                width: leftPill.width
                x: pillPos.x
                height: shown ? menuCol.implicitHeight + 8 : 0
                y: pillPos.y - height + 4
                clip: true

                color: root.menuOpen ? Appearance.colors.colSecondaryContainerHover : Appearance.colors.colSecondaryContainer
                radius: root.openRadius
                bottomLeftRadius: 0
                bottomRightRadius: 0

                Behavior on height { NumberAnimation { duration: Appearance.animation.elementMoveFast.duration; easing.type: Easing.OutCubic } }

                Column {
                    id: menuCol
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 8
                    spacing: 2
                    opacity: panel.shown ? 1 : 0

                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Repeater {
                        model: Mpris.players.values

                        delegate: Rectangle {
                            id: menuItem
                            required property var modelData
                            required property int index

                            readonly property bool isActive: modelData === MprisController.activePlayer
                            readonly property var entry: {
                                DesktopEntries.applications.values;
                                const id = menuItem.modelData.desktopEntry ?? "";
                                return id ? DesktopEntries.byId(id) : null;
                            }

                            width: parent.width
                            height: 28
                            radius: root.openRadius
                            color: menuItemMa.containsMouse
                                ? Appearance.colors.colLayer1Hover
                                : menuItem.isActive
                                    ? Appearance.colors.colPrimaryContainer
                                    : "transparent"

                            Behavior on color { ColorAnimation { duration: 100 } }

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                IconImage {
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: menuItem.entry?.icon ? Quickshell.iconPath(menuItem.entry.icon) : ""
                                    implicitSize: 16
                                    visible: status === Image.Ready
                                }

                                MaterialSymbol {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "audio_file"
                                    iconSize: 16
                                    color: menuItem.isActive
                                        ? Appearance.colors.colOnPrimaryContainer
                                        : Appearance.colors.colOnSecondaryContainer
                                    visible: !menuItem.entry?.icon
                                }

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: menuItem.entry?.name ?? menuItem.modelData.identity ?? "Player"
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: menuItem.isActive
                                        ? Appearance.colors.colOnPrimaryContainer
                                        : Appearance.colors.colOnSecondaryContainer
                                    elide: Text.ElideRight
                                    width: Math.min(implicitWidth, menuItem.width - 50)
                                }
                            }

                            MaterialSymbol {
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: "check"
                                iconSize: 14
                                color: Appearance.colors.colOnPrimaryContainer
                                visible: menuItem.isActive
                            }

                            MouseArea {
                                id: menuItemMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    MprisController.setActivePlayer(menuItem.modelData);
                                    root.menuOpen = false;
                                    root.playerSelected(menuItem.modelData);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
