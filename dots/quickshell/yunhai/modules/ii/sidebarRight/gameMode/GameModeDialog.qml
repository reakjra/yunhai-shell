import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

WindowDialog {
    id: root
    backgroundHeight: 500

    WindowDialogTitle {
        text: Translation.tr("Game mode")
    }

    WindowDialogSectionHeader {
        text: Translation.tr("Hyprland settings to apply")
    }

    WindowDialogSeparator {
        Layout.topMargin: -22
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    Column {
        id: settingsColumn
        Layout.topMargin: -16
        Layout.fillWidth: true

        ConfigSwitch {
            anchors {
                left: parent.left
                right: parent.right
            }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "animation"
            text: Translation.tr("Disable animations")
            checked: Config.options.gameMode.disableAnimations
            onCheckedChanged: Config.options.gameMode.disableAnimations = checked
        }

        ConfigSwitch {
            anchors {
                left: parent.left
                right: parent.right
            }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "shadow"
            text: Translation.tr("Disable shadows")
            checked: Config.options.gameMode.disableShadows
            onCheckedChanged: Config.options.gameMode.disableShadows = checked
        }

        ConfigSwitch {
            anchors {
                left: parent.left
                right: parent.right
            }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "blur_off"
            text: Translation.tr("Disable blur")
            checked: Config.options.gameMode.disableBlur
            onCheckedChanged: Config.options.gameMode.disableBlur = checked
        }

        ConfigSwitch {
            anchors {
                left: parent.left
                right: parent.right
            }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "fullscreen"
            text: Translation.tr("Remove gaps")
            checked: Config.options.gameMode.removeGaps
            onCheckedChanged: Config.options.gameMode.removeGaps = checked
        }

        ConfigSwitch {
            anchors {
                left: parent.left
                right: parent.right
            }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "border_style"
            text: Translation.tr("Set border size")
            checked: Config.options.gameMode.setBorderSize
            onCheckedChanged: Config.options.gameMode.setBorderSize = checked
        }

        ConfigSpinBox {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: 8
                rightMargin: 8
            }
            icon: "border_outer"
            text: Translation.tr("Border size (px)")
            from: 0
            to: 10
            value: Config.options.gameMode.borderSize
            onValueChanged: Config.options.gameMode.borderSize = value
            enabled: Config.options.gameMode.setBorderSize
        }

        ConfigSwitch {
            anchors {
                left: parent.left
                right: parent.right
            }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "rounded_corner"
            text: Translation.tr("Disable rounding")
            checked: Config.options.gameMode.disableRounding
            onCheckedChanged: Config.options.gameMode.disableRounding = checked
        }

        ConfigSwitch {
            anchors {
                left: parent.left
                right: parent.right
            }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "speed"
            text: Translation.tr("Enable tearing")
            checked: Config.options.gameMode.enableTearing
            onCheckedChanged: Config.options.gameMode.enableTearing = checked
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
