import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae.sidebarRight.notifications
import qs.modules.lunae.sidebarRight.quickToggles.dialogs

Item {
    id: pane
    required property var panel

    visible: panel.width > panel.mainW + 40
    opacity: Math.max(0, Math.min(1, (panel.width - panel.mainW) / panel.dialogW))

    property string displayDialog: ""
    onVisibleChanged: if (!visible) displayDialog = ""

    function dialogTitle(type) {
        switch (type) {
        case "network": return Translation.tr("Wi-Fi");
        case "bluetooth": return Translation.tr("Bluetooth");
        case "nightLight": return Translation.tr("Eye protection");
        case "audio": return Translation.tr("Audio output");
        case "mic": return Translation.tr("Audio input");
        case "record": return Translation.tr("Recording");
        case "gameMode": return Translation.tr("Game mode");
        case "notifications": return Translation.tr("Notifications");
        default: return "";
        }
    }

    function dialogComponentForType(type) {
        switch (type) {
        case "network": return compNetworkDialog;
        case "bluetooth": return compBluetoothDialog;
        case "nightLight": return compNightLightDialog;
        case "audio": return compAudioOutputDialog;
        case "mic": return compAudioInputDialog;
        case "record": return compRecordDialog;
        case "gameMode": return compGameModeDialog;
        case "notifications": return compNotificationsDialog;
        default: return null;
        }
    }

    Component { id: compNetworkDialog; NetworkDialog {} }
    Component { id: compBluetoothDialog; BluetoothDialog {} }
    Component { id: compNightLightDialog; NightLightDialog {} }
    Component { id: compAudioOutputDialog; AudioOutputDialog {} }
    Component { id: compAudioInputDialog; AudioInputDialog {} }
    Component { id: compRecordDialog; RecordDialog {} }
    Component { id: compGameModeDialog; GameModeDialog {} }
    Component { id: compNotificationsDialog; NotificationList { placeholderIconSize: 40 } }

    Connections {
        target: pane.panel
        function onActiveDialogChanged() {
            if (pane.panel.activeDialog === "")
                return;
            if (pane.displayDialog !== "" && pane.displayDialog !== pane.panel.activeDialog)
                dialogSwapAnim.restart();
            else
                pane.displayDialog = pane.panel.activeDialog;
        }
    }
    SequentialAnimation {
        id: dialogSwapAnim
        NumberAnimation { target: dialogContent; property: "opacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
        ScriptAction { script: pane.displayDialog = pane.panel.activeDialog }
        NumberAnimation { target: dialogContent; property: "opacity"; to: 1; duration: 150; easing.type: Easing.OutCubic }
    }

    ColumnLayout {
        id: dialogContent
        anchors.top: parent.top
        anchors.topMargin: 18
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        anchors.left: pane.panel.dialogOnLeft ? undefined : parent.left
        anchors.right: pane.panel.dialogOnLeft ? parent.right : undefined
        width: pane.panel.dialogW - 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StyledText {
                Layout.fillWidth: true
                text: pane.dialogTitle(pane.displayDialog)
                font.pixelSize: Appearance.font.pixelSize.larger
                font.weight: Font.DemiBold
                color: Appearance.colors.colOnLayer0
                elide: Text.ElideRight
            }
            ActionButton {
                size: 30
                iconSize: 19
                flat: true
                icon: "check"
                onClicked: pane.panel.activeDialog = ""
            }
        }
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.colors.colOnLayer0
            opacity: 0.14
        }
        Loader {
            id: dialogLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: pane.dialogComponentForType(pane.displayDialog)
            onLoaded: {
                if (item && item.maxListHeight !== undefined)
                    item.maxListHeight = Qt.binding(() => Math.max(120, dialogLoader.height - 16));
            }
        }
    }
}
