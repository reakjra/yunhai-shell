pragma ComponentBehavior: Bound

import qs
import qs.services
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    readonly property var pages: [
        { name: Translation.tr("Wi-Fi"), icon: "wifi", file: "WifiPage.qml" },
        { name: Translation.tr("Bluetooth"), icon: "bluetooth", file: "BluetoothPage.qml" },
        { name: Translation.tr("Audio"), icon: "volume_up", file: "AudioPage.qml" },
        { name: Translation.tr("Night light"), icon: "bedtime", file: "NightLightPage.qml" },
        { name: Translation.tr("Timers"), icon: "timer", file: "TimersPage.qml" },
        { name: Translation.tr("Notifications"), icon: "notifications", file: "NotificationsPage.qml" },
        { name: Translation.tr("Song recognition"), icon: "music_note", file: "SongRecPage.qml" }
    ].map(page => Object.assign({ component: `modules/${root.chromeFamily}/controlPanel/${page.file}` }, page))
    readonly property string chromeFamily: PanelFamilies.controlPanelFamilyFor(Config.options.panelFamily)
    readonly property bool available: root.chromeFamily !== ""

    onAvailableChanged: if (!root.available) GlobalStates.controlPanelOpen = false

    function toggle() {
        if (root.available)
            GlobalStates.controlPanelOpen = !GlobalStates.controlPanelOpen;
    }

    GlobalShortcut {
        name: "controlPanelToggle"
        description: "Toggles the control panel"
        onPressed: root.toggle()
    }

    IpcHandler {
        target: "controlPanel"

        function toggle(): void {
            root.toggle()
        }
    }

    Loader {
        active: GlobalStates.controlPanelOpen && root.available

        sourceComponent: FloatingWindow {
            visible: true
            title: "Control panel"
            implicitWidth: 1100
            implicitHeight: 750
            minimumSize: Qt.size(750, 500)
            color: Appearance.m3colors.m3background

            onVisibleChanged: {
                if (!visible) GlobalStates.controlPanelOpen = false;
            }

            Loader {
                anchors.fill: parent
                source: Quickshell.shellPath(`modules/${root.chromeFamily}/chrome/ControlPanelChrome.qml`)
                onLoaded: item.pages = Qt.binding(() => root.pages)
            }
        }
    }
}
