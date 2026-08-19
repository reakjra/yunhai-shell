import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.lunae
import qs.modules.lunae.drawers.panels
import qs.modules.lunae.verticalBar
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    property bool hubShortcutActive: false
    property bool sidebarShortcutActive: false
    property bool sidebarNotifShortcutActive: false
    property bool sidebarToggleShortcutActive: false

    property bool searchDontAutoCancelSearch: false
    property bool searchShowWorkspaces: false

    readonly property bool splitMode: Config.options.lunae?.sidebar?.splitMode ?? false

    readonly property var targetScreen: Quickshell.screens.find(monitor => monitor.name === Config.options.lunae.monitor) ?? Quickshell.screens[0]

    readonly property bool anyPanelOpen: GlobalStates.hubOpen || GlobalStates.sidebarRightOpen || GlobalStates.sidebarNotifOpen || GlobalStates.sidebarToggleOpen || GlobalStates.overviewOpen || GlobalStates.activeBarPopup !== "" || GlobalStates.wallpaperSelectorOpen

    readonly property HyprlandMonitor targetMonitor: Hyprland.monitorFor(root.targetScreen)
    readonly property bool targetFullscreen: (root.targetMonitor?.activeWorkspace?.toplevels.values ?? [])
        .some(window => window.wayland?.fullscreen)
    readonly property bool barVisible: GlobalStates.barOpen && !targetFullscreen && !GlobalStates.screenLocked
    readonly property real barWidth: Appearance.sizes.baseVerticalBarWidth

    property real barProgress: barVisible ? 1 : 0
    Behavior on barProgress {
        NumberAnimation {
            duration: root.barVisible ? LunaeAppearance.drawerOpenDuration : LunaeAppearance.drawerCloseDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.barVisible ? LunaeAppearance.drawerOpenCurve : LunaeAppearance.closeCurve
        }
    }

    Connections {
        target: Config.options.appearance.transparency
        function onEnableChanged() {
            console.log("[Lunae] transparency toggled:", Config.options.appearance.transparency.enable)
            const on = Config.options.appearance.transparency.enable
            const hyprDir = FileUtils.trimFileProtocol(`${Directories.home}/.config/hypr`)
            const rulesConf = `${hyprDir}/hyprland/rules.conf`
            const rulesLua  = `${hyprDir}/hyprland/rules.lua`
            const fromConf = on ? "blur off"   : "blur on"
            const toConf   = on ? "blur on"    : "blur off"
            const fromLua  = on ? "blur = false" : "blur = true"
            const toLua    = on ? "blur = true"  : "blur = false"
            blurToggle.command = ["bash", "-c",
                `sed -i '/# LUNAE_BLUR/s/${fromConf}/${toConf}/' '${rulesConf}' 2>/dev/null; ` +
                `sed -i '/-- LUNAE_BLUR/s/${fromLua}/${toLua}/' '${rulesLua}' 2>/dev/null; ` +
                `hyprctl reload`
            ]
            blurToggle.startDetached()
        }
    }

    Process {
        id: blurToggle
    }

    PanelWindow {
        id: win

        screen: root.targetScreen
        visible: true
        color: "transparent"

        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:lunaeDrawers"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: {
            if (GlobalStates.overviewOpen || root.anyPanelOpen)
                return WlrKeyboardFocus.OnDemand
            return WlrKeyboardFocus.None
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        HyprlandFocusGrab {
            windows: [win]
            active: (GlobalStates.overviewOpen && !root.searchShowWorkspaces) || GlobalStates.wallpaperSelectorOpen
        }

        mask: Region {
            item: root.anyPanelOpen ? fullMask : barMask

            Region {
                x: panels.notifPanel.visible ? panels.notifPanel.x : 0
                y: 0
                width: panels.notifPanel.visible ? win.width - panels.notifPanel.x : 0
                height: panels.notifPanel.visible ? panels.notifPanel.y + panels.notifPanel.height : 0
                intersection: Intersection.Combine
            }

            Region {
                readonly property Item osd: panels.osdTopPanel.visible ? panels.osdTopPanel : panels.osdRightPanel
                x: osd.visible ? osd.x : 0
                y: osd.visible ? osd.y : 0
                width: osd.visible ? osd.width : 0
                height: osd.visible ? osd.height : 0
                intersection: Intersection.Combine
            }
        }

        Item {
            id: fullMask
            anchors.fill: parent
        }

        Item {
            id: barMask
            x: 0; y: 0
            width: root.barVisible ? root.barWidth : 0
            height: win.height
        }

        MouseArea {
            id: dismissArea
            anchors.fill: parent
            visible: root.anyPanelOpen
            onClicked: {
                GlobalStates.hubOpen = false
                GlobalStates.sidebarRightOpen = false
                GlobalStates.sidebarNotifOpen = false
                GlobalStates.sidebarToggleOpen = false
                GlobalStates.overviewOpen = false
                GlobalStates.activeBarPopup = ""
                GlobalStates.wallpaperSelectorOpen = false
            }
        }

        MouseArea {
            id: barMouseArea
            x: 0; y: 0
            width: root.barWidth
            height: win.height
            hoverEnabled: true
            visible: root.barVisible

            onContainsMouseChanged: {
                if (!containsMouse && GlobalStates.activeBarPopup === "tray_menu"
                    && !panels.barPopupPanel.hoverHandler.hovered) {
                    trayMenuCloseTimer.restart()
                }
            }
        }

        Item {
            id: barProxy
            x: -root.barWidth * (1 - root.barProgress)
            width: root.barWidth
            height: win.height
            visible: root.barProgress > 0.004
        }

        DeformTracker {
            id: barDeform
            target: barProxy
            amount: 0.08
        }

        VerticalBarContent {
            id: barContent
            visible: root.barProgress > 0.004
            opacity: root.barProgress
            x: barProxy.x
            anchors {
                top: parent.top
                bottom: parent.bottom
            }
            implicitWidth: root.barWidth
            transform: Matrix4x4 { matrix: barDeform.matrix }
        }

        Repeater {
            model: [panels.hubPanel, panels.sidebarPanel, panels.sidebarNotifSplitPanel, panels.sidebarToggleSplitPanel, panels.searchPanel, panels.barPopupPanel, panels.osdTopPanel, panels.osdRightPanel, panels.wallpaperPanel, panels.workspaceLoader]

            MouseArea {
                required property Item modelData
                x: modelData.x
                y: modelData.y
                width: modelData.width
                height: modelData.height
                visible: modelData.visible
            }
        }

        MouseArea {
            id: notifHoverArea
            x: panels.notifPanel.x
            y: 0
            width: win.width - panels.notifPanel.x
            height: panels.notifPanel.y + panels.notifPanel.height
            visible: panels.notifPanel.visible
            hoverEnabled: true
        }

        LiquidSurface {
            id: surface
            z: -1
            anchors.fill: parent
            panels: panels
            barWidth: root.barWidth
            barVisible: root.barVisible
            barProgress: root.barProgress
            barDeformX: barDeform.sx
            barDeformY: barDeform.sy
        }

        Panels {
            id: panels
            anchors.fill: parent
            searchShowWorkspaces: root.searchShowWorkspaces
            searchDontAutoCancelSearch: root.searchDontAutoCancelSearch
            screen: win.screen
            barWidth: root.barWidth
            barVisible: root.barVisible
        }

        Connections {
            target: panels.barPopupPanel.hoverHandler
            function onHoveredChanged() {
                if (panels.barPopupPanel.hoverHandler.hovered) {
                    trayMenuCloseTimer.stop()
                } else if (GlobalStates.activeBarPopup === "tray_menu"
                    && !barMouseArea.containsMouse) {
                    trayMenuCloseTimer.restart()
                }
            }
        }

        property bool notifHovered: panels.notifPanel.hoverHandler.hovered || notifHoverArea.containsMouse

        onNotifHoveredChanged: {
            if (notifHovered) {
                Notifications.popupList.forEach(n => Notifications.cancelTimeout(n.notificationId))
            } else {
                Notifications.popupList.forEach(n => Notifications.timeoutNotification(n.notificationId))
            }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                if (GlobalStates.activeBarPopup !== "")
                    GlobalStates.activeBarPopup = ""
                else if (GlobalStates.hubOpen)
                    GlobalStates.hubOpen = false
                else if (GlobalStates.overviewOpen)
                    GlobalStates.overviewOpen = false
                else if (GlobalStates.sidebarNotifOpen)
                    GlobalStates.sidebarNotifOpen = false
                else if (GlobalStates.sidebarToggleOpen)
                    GlobalStates.sidebarToggleOpen = false
                else if (GlobalStates.wallpaperSelectorOpen)
                    GlobalStates.wallpaperSelectorOpen = false
                else if (GlobalStates.sidebarRightOpen)
                    GlobalStates.sidebarRightOpen = false
            }
        }
    }

    readonly property bool wrappedFrame: Config.options.screen.fakeScreenRounding === 3
    readonly property int frameThickness: Config.options.screen.wrappedFrameThickness

    PanelWindow {
        screen: root.targetScreen
        visible: root.barVisible && !GlobalStates.screenLocked
        color: "transparent"
        WlrLayershell.namespace: "quickshell:lunaeBarExclusion"
        anchors { left: true; top: true; bottom: true }
        implicitWidth: 1
        mask: Region {}
        exclusiveZone: Appearance.sizes.baseVerticalBarWidth
    }

    PanelWindow {
        screen: root.targetScreen
        visible: root.barVisible && !GlobalStates.screenLocked && root.wrappedFrame
        color: "transparent"
        WlrLayershell.namespace: "quickshell:lunaeFrameTop"
        anchors { top: true; left: true; right: true }
        implicitHeight: 1
        mask: Region {}
        exclusiveZone: root.frameThickness
    }

    PanelWindow {
        screen: root.targetScreen
        visible: root.barVisible && !GlobalStates.screenLocked && root.wrappedFrame
        color: "transparent"
        WlrLayershell.namespace: "quickshell:lunaeFrameRight"
        anchors { right: true; top: true; bottom: true }
        implicitWidth: 1
        mask: Region {}
        exclusiveZone: root.frameThickness
    }

    PanelWindow {
        screen: root.targetScreen
        visible: root.barVisible && !GlobalStates.screenLocked && root.wrappedFrame
        color: "transparent"
        WlrLayershell.namespace: "quickshell:lunaeFrameBottom"
        anchors { bottom: true; left: true; right: true }
        implicitHeight: 1
        mask: Region {}
        exclusiveZone: root.frameThickness
    }

    Timer {
        id: trayMenuCloseTimer
        interval: 400
        onTriggered: {
            if (!panels.barPopupPanel.hoverHandler.hovered && !barMouseArea.containsMouse
                && GlobalStates.activeBarPopup === "tray_menu")
                GlobalStates.activeBarPopup = ""
        }
    }

    DrawerHotZones {
        id: hotZones
        panels: panels
        targetScreen: root.targetScreen
        barVisible: root.barVisible
        splitMode: root.splitMode
        frameInset: panels.frameInset
        hubShortcutActive: root.hubShortcutActive
        sidebarShortcutActive: root.sidebarShortcutActive
        sidebarNotifShortcutActive: root.sidebarNotifShortcutActive
        sidebarToggleShortcutActive: root.sidebarToggleShortcutActive
    }

    Connections {
        target: GlobalStates

        function onHubOpenChanged() {
            if (!GlobalStates.hubOpen)
                root.hubShortcutActive = false
        }

        function onSidebarRightOpenChanged() {
            if (!GlobalStates.sidebarRightOpen)
                root.sidebarShortcutActive = false
            else if (!root.splitMode) {
                Notifications.timeoutAll()
                Notifications.markAllRead()
            }
        }

        function onSidebarNotifOpenChanged() {
            if (!GlobalStates.sidebarNotifOpen)
                root.sidebarNotifShortcutActive = false
        }

        function onSidebarToggleOpenChanged() {
            if (!GlobalStates.sidebarToggleOpen)
                root.sidebarToggleShortcutActive = false
        }

        function onOverviewOpenChanged() {
            if (!GlobalStates.overviewOpen) {
                root.searchDontAutoCancelSearch = false
                root.searchShowWorkspaces = false
            }
        }
    }

    function setSearchingText(text: string) {
        panels.searchPanel.searchDrawer.setSearchingText(text)
    }

    function toggleClipboard() {
        if (GlobalStates.overviewOpen && root.searchDontAutoCancelSearch) {
            GlobalStates.overviewOpen = false
            return
        }
        root.searchDontAutoCancelSearch = true
        root.searchShowWorkspaces = false
        setSearchingText(Config.options.search.prefix.clipboard)
        GlobalStates.overviewOpen = true
    }

    function toggleEmojis() {
        if (GlobalStates.overviewOpen && root.searchDontAutoCancelSearch) {
            GlobalStates.overviewOpen = false
            return
        }
        root.searchDontAutoCancelSearch = true
        root.searchShowWorkspaces = false
        setSearchingText(Config.options.search.prefix.emojis)
        GlobalStates.overviewOpen = true
    }

    function toggleWorkspaceOverview() {
        if (GlobalStates.overviewOpen && root.searchShowWorkspaces) {
            GlobalStates.overviewOpen = false
        } else {
            root.searchShowWorkspaces = true
            GlobalStates.overviewOpen = true
        }
    }

    IpcHandler {
        target: "hub"
        function toggle() {
            root.hubShortcutActive = true
            GlobalStates.hubOpen = !GlobalStates.hubOpen
        }
        function close() { GlobalStates.hubOpen = false }
        function open() {
            root.hubShortcutActive = true
            GlobalStates.hubOpen = true
        }
    }

    IpcHandler {
        target: "sidebarRight"
        function toggle() {
            if (root.splitMode) {
                root.sidebarToggleShortcutActive = true
                GlobalStates.sidebarToggleOpen = !GlobalStates.sidebarToggleOpen
            } else {
                root.sidebarShortcutActive = true
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
            }
        }
        function close() {
            if (root.splitMode) {
                GlobalStates.sidebarNotifOpen = false
                GlobalStates.sidebarToggleOpen = false
            } else {
                GlobalStates.sidebarRightOpen = false
            }
        }
        function open() {
            if (root.splitMode) {
                root.sidebarToggleShortcutActive = true
                GlobalStates.sidebarToggleOpen = true
            } else {
                root.sidebarShortcutActive = true
                GlobalStates.sidebarRightOpen = true
            }
        }
    }

    IpcHandler {
        target: "search"
        function toggle() {
            root.searchShowWorkspaces = false
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen
        }
        function workspacesToggle() { root.toggleWorkspaceOverview() }
        function close() { GlobalStates.overviewOpen = false }
        function open() {
            root.searchShowWorkspaces = false
            GlobalStates.overviewOpen = true
        }
        function toggleReleaseInterrupt() { GlobalStates.superReleaseMightTrigger = false }
        function clipboardToggle() { root.toggleClipboard() }
    }

    IpcHandler {
        target: "bar"
        function toggle() { GlobalStates.barOpen = !GlobalStates.barOpen }
        function close() { GlobalStates.barOpen = false }
        function open() { GlobalStates.barOpen = true }
    }

    GlobalShortcut {
        name: "barToggle"
        description: "Toggles bar on press"
        onPressed: GlobalStates.barOpen = !GlobalStates.barOpen
    }
    GlobalShortcut {
        name: "barOpen"
        description: "Opens bar on press"
        onPressed: GlobalStates.barOpen = true
    }
    GlobalShortcut {
        name: "barClose"
        description: "Closes bar on press"
        onPressed: GlobalStates.barOpen = false
    }

    GlobalShortcut {
        name: "hubToggle"
        description: "Toggles hub dashboard"
        onPressed: {
            root.hubShortcutActive = !GlobalStates.hubOpen
            GlobalStates.hubOpen = !GlobalStates.hubOpen
        }
    }

    GlobalShortcut {
        name: "sidebarRightToggle"
        description: "Toggles right sidebar on press"
        onPressed: {
            if (root.splitMode) {
                root.sidebarToggleShortcutActive = !GlobalStates.sidebarToggleOpen
                GlobalStates.sidebarToggleOpen = !GlobalStates.sidebarToggleOpen
            } else {
                root.sidebarShortcutActive = !GlobalStates.sidebarRightOpen
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen
            }
        }
    }
    GlobalShortcut {
        name: "sidebarRightOpen"
        description: "Opens right sidebar on press"
        onPressed: {
            if (root.splitMode) {
                root.sidebarToggleShortcutActive = true
                GlobalStates.sidebarToggleOpen = true
            } else {
                root.sidebarShortcutActive = true
                GlobalStates.sidebarRightOpen = true
            }
        }
    }
    GlobalShortcut {
        name: "sidebarRightClose"
        description: "Closes right sidebar on press"
        onPressed: {
            if (root.splitMode) {
                GlobalStates.sidebarNotifOpen = false
                GlobalStates.sidebarToggleOpen = false
            } else {
                GlobalStates.sidebarRightOpen = false
            }
        }
    }

    GlobalShortcut {
        name: "searchToggle"
        description: "Toggles search drawer"
        onPressed: {
            root.searchShowWorkspaces = false
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen
        }
    }
    GlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "Toggles workspace overview"
        onPressed: root.toggleWorkspaceOverview()
    }
    GlobalShortcut {
        name: "searchToggleRelease"
        description: "Toggles search drawer on release"
        onPressed: GlobalStates.superReleaseMightTrigger = true
        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true
                return
            }
            root.searchShowWorkspaces = false
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen
        }
    }
    GlobalShortcut {
        name: "searchToggleReleaseInterrupt"
        description: "Interrupts possibility of search being toggled on release"
        onPressed: GlobalStates.superReleaseMightTrigger = false
    }
    GlobalShortcut {
        name: "overviewClipboardToggle"
        description: "Toggle clipboard query on drawer"
        onPressed: root.toggleClipboard()
    }
    GlobalShortcut {
        name: "overviewEmojiToggle"
        description: "Toggle emoji query on drawer"
        onPressed: root.toggleEmojis()
    }
}
