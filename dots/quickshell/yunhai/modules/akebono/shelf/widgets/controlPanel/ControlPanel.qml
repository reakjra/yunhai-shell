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
    signal reshaped()

    property string activeDialog: ""
    property string displayDialog: ""
    property bool editMode: false

    readonly property EntryRegistry registry: EntryRegistry {}
    readonly property var allToggleTypes: root.registry.toggleIds
    readonly property var enabledToggles: Config.options.akebono.shelf.quickSettings.toggles
    readonly property bool flickMode: Config.options.akebono.shelf.quickSettings.flickable
    readonly property var brightnessMonitor: Brightness.getMonitorForScreen(QsWindow.window?.screen)

    implicitWidth: 406
    implicitHeight: viewHost.implicitHeight + 36

    function hasDialog(type) {
        return root.registry.hasDetail(type);
    }

    onActiveDialogChanged: {
        if (root.activeDialog === "notifications") {
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
        if (root.displayDialog !== root.activeDialog)
            swapAnim.restart();
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

    Connections {
        target: root.shelf
        function onQsOpenChanged() {
            swapAnim.stop();
            if (!root.shelf.qsOpen)
                return;
            viewHost.morphing = false;
            viewHost.opacity = 1;
            root.displayDialog = "";
            root.activeDialog = "";
            root.editMode = false;
        }
    }

    SequentialAnimation {
        id: swapAnim

        NumberAnimation {
            target: viewHost
            property: "opacity"
            to: 0
            duration: 150
            easing.type: Easing.InCubic
        }
        ScriptAction {
            script: {
                viewHost.morphing = true;
                root.displayDialog = root.activeDialog;
                root.reshaped();
            }
        }
        NumberAnimation {
            target: viewHost
            property: "opacity"
            to: 1
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
    }

    Item {
        id: viewHost
        property bool morphing: false

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 18
        clip: true
        implicitHeight: root.displayDialog === "" ? mainView.implicitHeight : detailView.implicitHeight

        Behavior on implicitHeight {
            enabled: viewHost.morphing
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
                onFinished: viewHost.morphing = false
            }
        }

        ColumnLayout {
            id: mainView
            width: viewHost.width
            spacing: 14
            opacity: root.displayDialog === "" ? 1 : 0
            enabled: root.displayDialog === ""

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

        DialogPane {
            id: detailView
            panel: root
            width: viewHost.width
            opacity: root.displayDialog === "" ? 0 : 1
            enabled: root.displayDialog !== ""
        }
    }
}
