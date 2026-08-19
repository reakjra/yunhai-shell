pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.modules.common
import qs.modules.lunae.drawers.panels
import qs.modules.lunae.overview

Item {
    id: root

    required property bool searchShowWorkspaces
    required property bool searchDontAutoCancelSearch
    required property var screen
    required property real barWidth
    required property bool barVisible

    readonly property real frameInset: barVisible && Config.options.screen.fakeScreenRounding === 3
        ? Config.options.screen.wrappedFrameThickness : 0

    readonly property bool splitMode: Config.options.lunae?.sidebar?.splitMode ?? false

    property alias hubPanel: hubPanel
    property alias sidebarPanel: sidebarPanel
    property alias sidebarNotifSplitPanel: sidebarNotifSplitPanel
    property alias sidebarToggleSplitPanel: sidebarToggleSplitPanel
    property alias notifPanel: notifPanel
    property alias searchPanel: searchPanel
    property alias barPopupPanel: barPopupPanel
    property alias osdTopPanel: osdTopPanel
    property alias osdRightPanel: osdRightPanel
    property alias wallpaperPanel: wallpaperPanel
    property alias workspaceLoader: workspaceLoader

    HubPanel {
        id: hubPanel
        frameInset: root.frameInset
    }

    SidebarPanel {
        id: sidebarPanel
        frameInset: root.frameInset
    }

    SidebarNotifSplitPanel {
        id: sidebarNotifSplitPanel
        frameInset: root.frameInset
        screenHeight: root.height
    }

    SidebarToggleSplitPanel {
        id: sidebarToggleSplitPanel
        frameInset: root.frameInset
    }

    NotifPanel {
        id: notifPanel
        frameInset: root.frameInset
        screenHeight: root.height
    }

    SearchPanel {
        id: searchPanel
        frameInset: root.frameInset
        searchShowWorkspaces: root.searchShowWorkspaces
        dontAutoCancelSearch: root.searchDontAutoCancelSearch
        screen: root.screen
    }

    BarPopupPanel {
        id: barPopupPanel
        frameInset: root.frameInset
        barWidth: root.barWidth
    }

    OsdTopPanel {
        id: osdTopPanel
        frameInset: root.frameInset
        hubBottom: hubPanel.y + hubPanel.height
    }

    OsdRightPanel {
        id: osdRightPanel
        frameInset: root.frameInset
        sidebarWidth: sidebarPanel.width - Math.min(sidebarPanel.armpitSize, sidebarPanel.width)
    }

    WallpaperPanel {
        id: wallpaperPanel
        frameInset: root.frameInset
    }

    Loader {
        id: workspaceLoader
        active: GlobalStates.overviewOpen && root.searchShowWorkspaces && Config.options.overview.enable
        x: (root.width - width) / 2
        y: (root.height - height) / 2 - 50

        sourceComponent: OverviewWidget {
            screen: root.screen
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape)
                    GlobalStates.overviewOpen = false
            }
        }
    }
}
