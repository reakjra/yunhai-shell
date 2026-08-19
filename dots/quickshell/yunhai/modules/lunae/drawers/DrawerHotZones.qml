pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.modules.lunae

Scope {
    id: root

    required property Item panels
    required property var targetScreen
    required property bool barVisible
    required property bool splitMode
    required property real frameInset

    property bool hubShortcutActive: false
    property bool sidebarShortcutActive: false
    property bool sidebarNotifShortcutActive: false
    property bool sidebarToggleShortcutActive: false

    Timer {
        id: hubOpenTimer
        interval: 200
        onTriggered: GlobalStates.hubOpen = true
    }

    Timer {
        id: hubCloseTimer
        interval: 400
        onTriggered: {
            if (!root.panels.hubPanel.hoverHandler.hovered && !hubHotZone.containsMouse)
                GlobalStates.hubOpen = false
        }
    }

    Timer {
        id: sidebarOpenTimer
        interval: 200
        onTriggered: GlobalStates.sidebarRightOpen = true
    }

    Timer {
        id: sidebarCloseTimer
        interval: 400
        onTriggered: {
            if (!root.panels.sidebarPanel.hoverHandler.hovered && !sidebarHotZone.containsMouse && !GlobalStates.sidebarRightPinned)
                GlobalStates.sidebarRightOpen = false
        }
    }

    Timer {
        id: splitNotifOpenTimer
        interval: 200
        onTriggered: GlobalStates.sidebarNotifOpen = true
    }

    Timer {
        id: splitNotifCloseTimer
        interval: 400
        onTriggered: {
            if (!root.panels.sidebarNotifSplitPanel.hoverHandler.hovered && !splitNotifHotZone.containsMouse)
                GlobalStates.sidebarNotifOpen = false
        }
    }

    Timer {
        id: splitToggleOpenTimer
        interval: 200
        onTriggered: GlobalStates.sidebarToggleOpen = true
    }

    Timer {
        id: splitToggleCloseTimer
        interval: 400
        onTriggered: {
            if (!root.panels.sidebarToggleSplitPanel.hoverHandler.hovered && !splitToggleHotZone.containsMouse && !GlobalStates.sidebarRightPinned)
                GlobalStates.sidebarToggleOpen = false
        }
    }

    Connections {
        target: root.panels.hubPanel.hoverHandler
        function onHoveredChanged() {
            if (root.panels.hubPanel.hoverHandler.hovered) {
                hubCloseTimer.stop()
            } else if (GlobalStates.hubOpen && !hubHotZone.containsMouse
                && !root.hubShortcutActive) {
                hubCloseTimer.restart()
            }
        }
    }

    Connections {
        target: root.panels.sidebarPanel.hoverHandler
        function onHoveredChanged() {
            if (root.panels.sidebarPanel.hoverHandler.hovered) {
                sidebarCloseTimer.stop()
            } else if (GlobalStates.sidebarRightOpen && !sidebarHotZone.containsMouse
                && !root.sidebarShortcutActive && !GlobalStates.sidebarRightPinned) {
                sidebarCloseTimer.restart()
            }
        }
    }

    Connections {
        target: root.panels.sidebarNotifSplitPanel.hoverHandler
        function onHoveredChanged() {
            if (root.panels.sidebarNotifSplitPanel.hoverHandler.hovered) {
                splitNotifCloseTimer.stop()
            } else if (GlobalStates.sidebarNotifOpen && !splitNotifHotZone.containsMouse
                && !root.sidebarNotifShortcutActive) {
                splitNotifCloseTimer.restart()
            }
        }
    }

    Connections {
        target: root.panels.sidebarToggleSplitPanel.hoverHandler
        function onHoveredChanged() {
            if (root.panels.sidebarToggleSplitPanel.hoverHandler.hovered) {
                splitToggleCloseTimer.stop()
            } else if (GlobalStates.sidebarToggleOpen && !splitToggleHotZone.containsMouse
                && !root.sidebarToggleShortcutActive && !GlobalStates.sidebarRightPinned) {
                splitToggleCloseTimer.restart()
            }
        }
    }

    PanelWindow {
        id: hubHotZoneWindow
        screen: root.targetScreen
        visible: root.barVisible
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:lunaeHubHotZone"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            left: true
            right: true
        }
        implicitHeight: 6

        mask: Region { item: hubHotZoneMask }

        Item {
            id: hubHotZoneMask
            x: (hubHotZoneWindow.width - root.panels.hubPanel.implicitWidth) / 2
            y: 0
            width: root.panels.hubPanel.implicitWidth
            height: 6
        }

        MouseArea {
            id: hubHotZone
            x: hubHotZoneMask.x
            y: 0
            width: hubHotZoneMask.width
            height: 6
            hoverEnabled: true
            acceptedButtons: Qt.NoButton

            onContainsMouseChanged: {
                if (containsMouse) {
                    hubCloseTimer.stop()
                    hubOpenTimer.restart()
                } else {
                    hubOpenTimer.stop()
                    if (GlobalStates.hubOpen && !root.panels.hubPanel.hoverHandler.hovered
                        && !root.hubShortcutActive)
                        hubCloseTimer.restart()
                }
            }
        }
    }

    PanelWindow {
        id: sidebarHotZoneWindow
        screen: root.targetScreen
        visible: root.barVisible
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:lunaeSidebarHotZone"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors {
            top: true
            right: true
            bottom: true
        }
        implicitWidth: 6

        MouseArea {
            id: sidebarHotZone
            anchors.fill: parent
            hoverEnabled: true
            visible: !root.splitMode
            acceptedButtons: Qt.NoButton

            onContainsMouseChanged: {
                if (containsMouse) {
                    sidebarCloseTimer.stop()
                    sidebarOpenTimer.restart()
                } else {
                    sidebarOpenTimer.stop()
                    if (GlobalStates.sidebarRightOpen && !root.panels.sidebarPanel.hoverHandler.hovered
                        && !root.sidebarShortcutActive)
                        sidebarCloseTimer.restart()
                }
            }
        }

        MouseArea {
            id: splitNotifHotZone
            x: 0
            y: root.frameInset
            width: parent.width
            height: root.panels.sidebarNotifSplitPanel.naturalHeight
            hoverEnabled: true
            visible: root.splitMode
            acceptedButtons: Qt.NoButton

            onContainsMouseChanged: {
                if (containsMouse) {
                    splitNotifCloseTimer.stop()
                    splitNotifOpenTimer.restart()
                } else {
                    splitNotifOpenTimer.stop()
                    if (GlobalStates.sidebarNotifOpen && !root.panels.sidebarNotifSplitPanel.hoverHandler.hovered
                        && !root.sidebarNotifShortcutActive)
                        splitNotifCloseTimer.restart()
                }
            }
        }

        MouseArea {
            id: splitToggleHotZone
            x: 0
            y: parent.height - root.frameInset - root.panels.sidebarToggleSplitPanel.naturalHeight * 2
            width: parent.width
            height: root.panels.sidebarToggleSplitPanel.naturalHeight * 2
            hoverEnabled: true
            visible: root.splitMode
            acceptedButtons: Qt.NoButton

            onContainsMouseChanged: {
                if (containsMouse) {
                    splitToggleCloseTimer.stop()
                    splitToggleOpenTimer.restart()
                } else {
                    splitToggleOpenTimer.stop()
                    if (GlobalStates.sidebarToggleOpen && !root.panels.sidebarToggleSplitPanel.hoverHandler.hovered
                        && !root.sidebarToggleShortcutActive && !GlobalStates.sidebarRightPinned)
                        splitToggleCloseTimer.restart()
                }
            }
        }
    }
}
