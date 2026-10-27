import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

WindowDialog {
    id: root

    property string title: ""
    property string body: ""
    property string confirmText: ""

    signal confirmed()

    backgroundWidth: 400

    WindowDialogTitle {
        Layout.fillWidth: true
        text: root.title
    }

    WindowDialogParagraph {
        Layout.fillWidth: true
        text: root.body
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
            buttonText: root.confirmText
            onClicked: {
                root.confirmed();
                root.dismiss();
            }
        }
    }
}
