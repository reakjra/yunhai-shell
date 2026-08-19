import qs.services
import qs.modules.common
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

MaterialTextField {
    id: root
    property var keyringPath: []
    property string tooltipText: ""
    property bool secret: true
    property bool ready: false

    Layout.fillWidth: true
    echoMode: root.secret ? TextInput.Password : TextInput.Normal

    function storedValue(): string {
        let node = KeyringStorage.keyringData;
        for (const key of root.keyringPath) {
            if (node === undefined || node === null)
                return "";
            node = node[key];
        }
        return node ?? "";
    }

    function adopt() {
        root.text = root.storedValue();
        root.ready = true;
    }

    onTextChanged: {
        if (root.ready)
            KeyringStorage.setNestedField(root.keyringPath, text);
    }

    Connections {
        target: KeyringStorage
        function onLoadedChanged() {
            if (KeyringStorage.loaded)
                root.adopt();
        }
    }

    Component.onCompleted: {
        if (KeyringStorage.loaded)
            root.adopt();
        else
            KeyringStorage.fetchKeyringData();
    }

    StyledToolTip {
        extraVisibleCondition: root.tooltipText.length > 0
        text: root.tooltipText
    }
}
