pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae.widgets
import qs.services

RowLayout {
    id: root

    spacing: 12

    CookieImage {
        Layout.preferredWidth: 76
        Layout.preferredHeight: 76
        Layout.alignment: Qt.AlignVCenter
        source: (Directories.userAvatarPathAccountsService && !Directories.userAvatarPathAccountsService.endsWith("/user")) ? Directories.userAvatarPathAccountsService : ""
        lobes: 9
        scallop: 0.05
        fallbackIcon: "person"
    }

    ColumnLayout {
        id: infoColumn
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        spacing: 6

        RowLayout {
            spacing: 8
            CustomIcon {
                Layout.preferredWidth: Appearance.font.pixelSize.large
                Layout.preferredHeight: Appearance.font.pixelSize.large
                source: SystemInfo.distroIcon
                colorize: true
                color: Appearance.colors.colPrimary
            }
            StyledText {
                Layout.fillWidth: true
                text: SystemInfo.distroName
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                elide: Text.ElideRight
            }
        }

        RowLayout {
            spacing: 8
            MaterialSymbol {
                text: "select_window_2"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.m3colors.m3secondary
                fill: 1
            }
            StyledText {
                Layout.fillWidth: true
                text: "Hyprland"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                elide: Text.ElideRight
            }
        }

        RowLayout {
            spacing: 8
            MaterialSymbol {
                text: "timer"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.m3colors.m3tertiary
                fill: 1
            }
            StyledText {
                Layout.fillWidth: true
                text: `up ${DateTime.uptime}`
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer1
                elide: Text.ElideRight
            }
        }
    }
}
