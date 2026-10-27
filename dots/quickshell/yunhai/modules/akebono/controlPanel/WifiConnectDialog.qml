import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono.shelf.widgets.controlPanel

WindowDialog {
    id: root

    required property bool hiddenRequested
    property bool hiddenMode: false
    property var target: null
    property bool revealPassword: false
    readonly property bool canSubmit: root.hiddenMode ? !Network.hiddenConnecting && ssidField.text.length > 0 && (passwordField.text.length === 0 || passwordField.text.length >= 8) : passwordField.text.length >= 8

    backgroundWidth: 420

    function submit() {
        if (!root.canSubmit)
            return;
        if (root.hiddenMode)
            Network.connectToHiddenNetwork(ssidField.text, passwordField.text);
        else
            Network.connectWithPassword(root.target, passwordField.text);
    }

    onShowChanged: {
        if (!root.show)
            return;
        root.hiddenMode = root.hiddenRequested;
        root.target = Network.passwordTarget;
        passwordField.text = "";
        Qt.callLater(() => (root.hiddenMode ? ssidField : passwordField).forceActiveFocus());
    }

    Connections {
        target: Network

        function onHiddenConnectFinished(succeeded) {
            if (succeeded)
                root.dismiss();
        }
    }

    WindowDialogTitle {
        Layout.fillWidth: true
        text: root.hiddenMode ? Translation.tr("Hidden network") : Translation.tr("Connect to %1").arg(root.target?.name ?? "")
    }

    WindowDialogParagraph {
        Layout.fillWidth: true
        visible: Network.connectError !== ""
        text: Translation.tr("Couldn't connect: %1").arg(Network.connectError)
        color: Appearance.colors.colError
    }

    MaterialTextField {
        id: ssidField
        Layout.fillWidth: true
        visible: root.hiddenMode
        placeholderText: Translation.tr("Network name")
        onAccepted: passwordField.forceActiveFocus()
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        MaterialTextField {
            id: passwordField
            Layout.fillWidth: true
            placeholderText: root.hiddenMode ? Translation.tr("Password (optional)") : Translation.tr("Password")
            echoMode: root.revealPassword ? TextInput.Normal : TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData
            onAccepted: root.submit()
        }
        ActionButton {
            flat: true
            size: Appearance.font.pixelSize.huge * 1.6
            icon: root.revealPassword ? "visibility_off" : "visibility"
            tooltip: root.revealPassword ? Translation.tr("Hide password") : Translation.tr("Show password")
            onClicked: root.revealPassword = !root.revealPassword
        }
    }

    WindowDialogButtonRow {
        Layout.fillWidth: true

        Item {
            Layout.fillWidth: true
        }
        DialogButton {
            buttonText: Translation.tr("Cancel")
            onClicked: root.dismiss()
        }
        DialogButton {
            buttonText: Translation.tr("Connect")
            enabled: root.canSubmit
            onClicked: root.submit()
        }
    }
}
