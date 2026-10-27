import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

WindowDialog {
    id: root

    readonly property int totalSeconds: time.firstValue * 60 + time.secondValue

    backgroundWidth: 360

    onShowChanged: {
        if (!root.show)
            return;
        const last = TimerService.countdownDuration > 0 ? TimerService.countdownDuration : 300;
        time.firstValue = Math.floor(last / 60);
        time.secondValue = last % 60;
    }

    WindowDialogTitle {
        Layout.fillWidth: true
        text: Translation.tr("Custom countdown")
    }

    TimeSpinBoxes {
        id: time
        firstTo: 999
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
            buttonText: Translation.tr("Start")
            enabled: root.totalSeconds > 0
            onClicked: {
                TimerService.startCountdown(root.totalSeconds);
                root.dismiss();
            }
        }
    }
}
