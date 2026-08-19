import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton {
    id: root
    property bool barOpen: true
    property string activeBarPopup: ""
    property real barPopupY: 0
    property var trayMenuHandle: null
    property string trayMenuItemId: ""
    property bool crosshairOpen: false
    property bool hubOpen: false
    property bool sidebarLeftOpen: false
    property bool sidebarRightOpen: false
    property bool sidebarRightPinned: false
    property bool sidebarNotifOpen: false
    property bool sidebarToggleOpen: false
    property bool mediaControlsOpen: false
    property bool osdBrightnessOpen: false
    property bool osdVolumeOpen: false
    property string osdCurrentIndicator: "volume"
    property bool osdHovered: false
    property bool oskOpen: false
    property bool overlayOpen: false
    property bool overviewOpen: false
    property bool desktopRunnerOpen: false
    property string desktopRunnerPendingQuery: ""
    property bool desktopGlyphPickerOpen: false
    property bool desktopIconRenaming: false
    property bool desktopIconDragActive: false
    property bool desktopOverviewOpen: false
    property bool desktopLockClockHidden: false
    property bool panelFamilyPickerOpen: false
    property bool regionSelectorOpen: false
    property bool searchOpen: false
    property bool screenLocked: false
    property bool screenLockContainsCharacters: false
    property bool screenUnlockFailed: false
    property bool sessionOpen: false
    property bool superDown: false
    property bool superReleaseMightTrigger: true
    property bool screenTranslatorOpen: false
    property bool wallpaperSelectorOpen: false
    property bool workspaceShowNumbers: false

    property string overlayScreen: ""
    Binding {
        target: root
        property: "overlayScreen"
        value: Hyprland.focusedMonitor?.name ?? Quickshell.screens[0]?.name ?? ""
        when: !root.desktopRunnerOpen && !root.regionSelectorOpen && !root.overviewOpen
        restoreMode: Binding.RestoreNone
    }

    onSidebarRightOpenChanged: {
        if (GlobalStates.sidebarRightOpen) {
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }

    onSidebarNotifOpenChanged: {
        if (GlobalStates.sidebarNotifOpen) {
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }

    GlobalShortcut {
        name: "workspaceNumber"
        description: "Hold to show workspace numbers, release to show icons"

        onPressed: {
            root.superDown = true
        }
        onReleased: {
            root.superDown = false
        }
    }
}
