import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono
import qs.modules.akebono.shelf.widgets.controlPanel

RowLayout {
    id: header
    required property var panel
    Layout.fillWidth: true
    spacing: 12

    component HeaderButton: ActionButton {
        size: Appearance.font.pixelSize.huge * 1.7
        iconSize: Appearance.font.pixelSize.huge
        flat: true
    }

    Item {
        implicitWidth: 42
        implicitHeight: 42

        Squircle {
            anchors.fill: parent
            radius: 21
            smoothing: AkebonoAppearance.squircleSmoothing
            color: Appearance.colors.colSecondaryContainer
        }
        MaterialSymbol {
            anchors.centerIn: parent
            text: "person"
            iconSize: 25
            color: Appearance.colors.colOnSecondaryContainer
            visible: avatarImg.status !== Image.Ready
        }
        Image {
            id: avatarImg
            anchors.fill: parent
            sourceSize: Qt.size(42, 42)
            source: (Directories.userAvatarPathAccountsService && !Directories.userAvatarPathAccountsService.endsWith("/user")) ? Directories.userAvatarPathAccountsService : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: status === Image.Ready
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Squircle {
                    width: 42
                    height: 42
                    radius: 21
                    smoothing: AkebonoAppearance.squircleSmoothing
                    color: "white"
                }
            }
        }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: -2
        StyledText {
            Layout.fillWidth: true
            text: SystemInfo.username
            font.pixelSize: Appearance.font.pixelSize.larger
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
        }
        StyledText {
            Layout.fillWidth: true
            text: Battery.available
                ? `${Math.round(Battery.percentage * 100)}%${Battery.isCharging ? " ⚡" : ""} · ${DateTime.shortDate}`
                : DateTime.shortDate
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
        }
    }
    RowLayout {
        spacing: 2

        HeaderButton {
            icon: "refresh"
            onClicked: Quickshell.reload(true)
        }
        HeaderButton {
            icon: "settings"
            onClicked: {
                Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")]);
                header.panel.closeRequested();
            }
        }
        HeaderButton {
            icon: "power_settings_new"
            danger: true
            onClicked: {
                header.panel.closeRequested();
                GlobalStates.sessionOpen = true;
            }
        }
    }
}
