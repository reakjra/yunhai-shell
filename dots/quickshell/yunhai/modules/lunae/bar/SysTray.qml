import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root
    property var rootItem: null
    implicitWidth: gridLayout.implicitWidth
    implicitHeight: gridLayout.implicitHeight
    property bool vertical: false
    property bool showSeparator: true
    property bool showOverflowMenu: true
    property var activeMenu: null

    property list<var> pinnedItems: TrayService.pinnedItems
    property list<var> unpinnedItems: TrayService.unpinnedItems
    onUnpinnedItemsChanged: {
        if (unpinnedItems.length == 0 && GlobalStates.activeBarPopup === "tray")
            GlobalStates.activeBarPopup = ""
        if (rootItem) rootItem.toggleVisible(pinnedItems.length > 0 || unpinnedItems.length > 0);
    }
    onPinnedItemsChanged: {
        if (rootItem) rootItem.toggleVisible(pinnedItems.length > 0 || unpinnedItems.length > 0);
    }

    function grabFocus() {
        focusGrab.active = true;
    }

    function setExtraWindowAndGrabFocus(window) {
        root.activeMenu = window;
        root.grabFocus();
    }

    function releaseFocus() {
        focusGrab.active = false;
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: false
        windows: [root.activeMenu]
        onCleared: {
            if (root.activeMenu) {
                root.activeMenu.close();
                root.activeMenu = null;
            }
        }
    }

    GridLayout {
        id: gridLayout
        columns: root.vertical ? 1 : -1
        anchors.fill: parent
        rowSpacing: 8
        columnSpacing: 15

        MouseArea {
            id: trayOverflowButton
            visible: root.showOverflowMenu && root.unpinnedItems.length > 0

            Layout.fillHeight: !root.vertical
            Layout.fillWidth: root.vertical
            implicitWidth: 28
            implicitHeight: 28

            readonly property bool trayOpen: GlobalStates.activeBarPopup === "tray"

            onClicked: {
                if (trayOpen)
                    GlobalStates.activeBarPopup = ""
                else {
                    const pos = trayOverflowButton.mapToItem(null, 0, trayOverflowButton.height / 2)
                    GlobalStates.barPopupY = pos.y
                    GlobalStates.activeBarPopup = "tray"
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: Appearance.rounding.full
                color: trayOverflowButton.trayOpen ? Appearance.colors.colSecondaryContainer : Appearance.colors.colLayer1Hover

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }

            MaterialSymbol {
                anchors.centerIn: parent
                iconSize: Appearance.font.pixelSize.larger
                text: "expand_less"
                horizontalAlignment: Text.AlignHCenter
                color: trayOverflowButton.trayOpen ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer2
                rotation: trayOverflowButton.trayOpen ? 180 : 0
                Behavior on rotation {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }

        Repeater {
            model: ScriptModel {
                values: root.pinnedItems
            }

            delegate: SysTrayItem {
                required property SystemTrayItem modelData
                item: modelData
                Layout.fillHeight: !root.vertical
                Layout.fillWidth: root.vertical
                onMenuClosed: root.releaseFocus();
                onMenuOpened: (qsWindow) => {
                    root.setExtraWindowAndGrabFocus(qsWindow);
                }
            }
        }
    }
}
