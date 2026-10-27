import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.panels.quickToggles as QuickToggles
import QtQuick
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root
    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    backgroundHeight: 700

    WindowDialogTitle {
        text: Translation.tr("Eye protection")
    }

    QuickToggles.NightLightDialog {
        Layout.fillWidth: true
    }

    WindowDialogSectionHeader {
        text: Translation.tr("Brightness")
    }

    WindowDialogSeparator {
        Layout.topMargin: -22
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    Column {
        Layout.topMargin: -16
        Layout.fillWidth: true
        Layout.fillHeight: true

        WindowDialogSlider {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: 4
                rightMargin: 4
            }
            value: root.brightnessMonitor.brightness
            onMoved: root.brightnessMonitor.setBrightness(value)
            tooltipContent: `${Math.round(value * 100)}%`
        }
    }

    WindowDialogButtonRow {
        Layout.fillWidth: true

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
