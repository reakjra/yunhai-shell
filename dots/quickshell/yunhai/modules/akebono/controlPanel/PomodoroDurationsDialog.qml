import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

WindowDialog {
    id: root

    backgroundWidth: 400

    onShowChanged: {
        if (!root.show)
            return;
        focusBox.value = TimerService.focusTime / 60;
        breakBox.value = TimerService.breakTime / 60;
        longBreakBox.value = TimerService.longBreakTime / 60;
        cyclesBox.value = TimerService.cyclesBeforeLongBreak;
    }

    WindowDialogTitle {
        Layout.fillWidth: true
        text: Translation.tr("Pomodoro durations")
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        DialogConfigSpinBox {
            id: focusBox
            icon: "search_activity"
            text: Translation.tr("Focus (minutes)")
            from: 1
            to: 180
        }
        DialogConfigSpinBox {
            id: breakBox
            icon: "coffee"
            text: Translation.tr("Break (minutes)")
            from: 1
            to: 60
        }
        DialogConfigSpinBox {
            id: longBreakBox
            icon: "self_improvement"
            text: Translation.tr("Long break (minutes)")
            from: 1
            to: 120
        }
        DialogConfigSpinBox {
            id: cyclesBox
            icon: "repeat"
            text: Translation.tr("Cycles before a long break")
            from: 1
            to: 12
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
            buttonText: Translation.tr("Save")
            onClicked: {
                Config.options.time.pomodoro.focus = focusBox.value * 60;
                Config.options.time.pomodoro.breakTime = breakBox.value * 60;
                Config.options.time.pomodoro.longBreak = longBreakBox.value * 60;
                Config.options.time.pomodoro.cyclesBeforeLongBreak = cyclesBox.value;
                root.dismiss();
            }
        }
    }
}
