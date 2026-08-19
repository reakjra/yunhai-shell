import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.lunae.widgets

Item {
    id: root
    property var shelf: null
    signal closeRequested()

    readonly property real mainW: shelf?.qsBaseW ?? 360
    readonly property real dialogW: shelf?.qsDialogW ?? 300
    readonly property bool dialogOnLeft: shelf?.qsGrowLeft ?? false
    property string activeDialog: ""
    property bool editMode: false

    readonly property var allToggleTypes: ["network", "bluetooth", "nightLight", "gameMode", "idleInhibitor", "easyEffects", "cloudflareWarp", "darkMode", "audio", "mic", "screenSnip", "record", "onScreenKeyboard", "musicRecognition"]
    readonly property var enabledToggles: Config.options.akebono?.shelf.quickSettings.toggles ?? []
    readonly property bool flickMode: Config.options.akebono?.shelf.quickSettings.flickable ?? false
    readonly property var brightnessMonitor: Brightness.getMonitorForScreen(QsWindow.window?.screen)

    function hasDialog(type) {
        return ["network", "bluetooth", "nightLight", "audio", "mic", "record", "gameMode"].includes(type);
    }

    onActiveDialogChanged: {
        if (root.shelf) root.shelf.qsDialogOpen = root.activeDialog !== "";
        if (root.activeDialog === "notifications") {
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }
    onEditModeChanged: if (root.editMode) root.activeDialog = ""

    Connections {
        target: Notifications
        enabled: root.activeDialog === "notifications"
        function onUnreadChanged() {
            if (Notifications.unread > 0) {
                Notifications.timeoutAll();
                Notifications.markAllRead();
            }
        }
    }

    Binding {
        target: root.shelf
        property: "qsContentH"
        value: mainCol.implicitHeight + 36
        when: root.shelf !== null
    }

    Connections {
        target: root.shelf
        function onQsOpenChanged() {
            if (!root.shelf.qsOpen) {
                root.activeDialog = "";
                root.editMode = false;
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
    }

    ColumnLayout {
        id: mainCol
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: root.dialogOnLeft ? undefined : parent.left
        anchors.right: root.dialogOnLeft ? parent.right : undefined
        anchors.margins: 18
        width: root.mainW - 36
        spacing: 14

        Header { panel: root }

        TogglesSection {
            panel: root
            Layout.fillWidth: true
        }

        Card {
            Layout.fillWidth: true

            SidebarSlider {
                Layout.fillWidth: true
                icon: "volume_up"
                value: Audio.sink?.audio?.volume ?? 0
                onMoved: if (Audio.sink?.audio) Audio.sink.audio.volume = value
            }
            SidebarSlider {
                Layout.fillWidth: true
                icon: "brightness_6"
                value: root.brightnessMonitor?.brightness ?? 0
                onMoved: root.brightnessMonitor?.setBrightness(value)
            }
        }

        NotificationRow {
            panel: root
            Layout.fillWidth: true
        }
    }

    Rectangle {
        anchors.left: root.dialogOnLeft ? dialogPane.right : undefined
        anchors.leftMargin: 9
        anchors.right: root.dialogOnLeft ? undefined : dialogPane.left
        anchors.rightMargin: 9
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: parent.height - 64
        color: Appearance.colors.colOnLayer0
        opacity: dialogPane.opacity * 0.14
        visible: dialogPane.visible
    }

    DialogPane {
        id: dialogPane
        panel: root
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: root.dialogOnLeft ? parent.left : mainCol.right
        anchors.leftMargin: 16
        anchors.right: root.dialogOnLeft ? mainCol.left : parent.right
        anchors.rightMargin: 16
        clip: true
    }
}
