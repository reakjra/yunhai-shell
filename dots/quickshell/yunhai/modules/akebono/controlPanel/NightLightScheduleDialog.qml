import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

WindowDialog {
    id: root

    property string requestedEdge: ""
    property string edge: "from"

    backgroundWidth: 360

    onShowChanged: {
        if (!root.show)
            return;
        root.edge = root.requestedEdge;
        time.firstValue = root.edge === "from" ? Hyprsunset.fromHour : Hyprsunset.toHour;
        time.secondValue = root.edge === "from" ? Hyprsunset.fromMinute : Hyprsunset.toMinute;
    }

    WindowDialogTitle {
        Layout.fillWidth: true
        text: root.edge === "from" ? Translation.tr("Turn on at") : Translation.tr("Turn off at")
    }

    TimeSpinBoxes {
        id: time
        firstTo: 23
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
            buttonText: Translation.tr("Save")
            onClicked: {
                Hyprsunset.setScheduleTime(root.edge, time.firstValue, time.secondValue);
                root.dismiss();
            }
        }
    }
}
