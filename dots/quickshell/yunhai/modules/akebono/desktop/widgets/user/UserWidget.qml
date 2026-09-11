// copied :3 https://github.com/pctrade/end4-pC/blob/main/modules/ii/background/widgets/usercard/UserCardWidget.qml
pragma ComponentBehavior: Bound

import qs
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono.desktop.widgets

WidgetCard {
    id: root
    minSize: 150

    readonly property bool isFull: root.styleId === "full"
    readonly property real avatarSize: Math.max(40, Math.min(84, Math.round(Math.min(root.width, root.height) * (root.isFull ? 0.32 : 0.42))))
    readonly property real actionSize: Math.max(40, Math.min(58, Math.round(root.height * 0.21)))
    readonly property bool actionsShown: root.isFull && root.height >= 180

    property int avatarCandidate: 0
    readonly property var avatarCandidates: [Directories.userAvatarPathAccountsService, Directories.userAvatarPathRicersAndWeirdSystems, Directories.userAvatarPathRicersAndWeirdSystems2]
    readonly property url avatarSource: root.avatarCandidate < root.avatarCandidates.length ? `file://${root.avatarCandidates[root.avatarCandidate]}` : ""

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ShapedImage {
                id: avatar
                implicitWidth: root.avatarSize
                implicitHeight: root.avatarSize
                shape: root.chipShape
                themeRadius: root.avatarSize / 2
                source: root.avatarSource
                fallbackIcon: "person"

                onStatusChanged: {
                    if (avatar.status === Image.Error && root.avatarCandidate < root.avatarCandidates.length)
                        root.avatarCandidate++;
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: `${SystemInfo.username}@${SystemInfo.hostname}`
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Up · %1").arg(DateTime.uptime)
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.isFull
            spacing: 8

            MaterialSymbol {
                text: Icons.getWeatherIcon(Weather.data.wCode) ?? "cloud"
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colSubtext
            }
            StyledText {
                Layout.fillWidth: true
                text: typeof Weather.data.desc === "string" && Weather.data.desc.length > 0 ? `${Weather.data.desc} · ${Weather.data.temp}` : Translation.tr("Weather unavailable")
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.actionsShown
            spacing: 8

            TonalButton {
                Layout.fillWidth: true
                buttonIcon: "lock"
                buttonText: Translation.tr("Lock")
                onClicked: GlobalStates.screenLocked = true
            }
            TonalButton {
                buttonIcon: "settings"
                onClicked: Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")])
            }
            TonalButton {
                buttonIcon: "power_settings_new"
                onClicked: GlobalStates.sessionOpen = true
            }
        }
    }

    component TonalButton: RippleButton {
        id: button
        property string buttonIcon: ""

        implicitHeight: root.actionSize
        implicitWidth: button.buttonText === "" ? root.actionSize : Math.max(root.actionSize, button.implicitContentWidth + 32)
        buttonRadius: Appearance.rounding.full
        colBackground: Appearance.colors.colSecondaryContainer
        colBackgroundHover: Appearance.colors.colSecondaryContainerHover

        contentItem: Item {
            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    text: button.buttonIcon
                    fill: 1
                    iconSize: Math.round(root.actionSize * 0.46)
                    color: Appearance.colors.colOnSecondaryContainer
                }
                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    visible: button.buttonText !== ""
                    text: button.buttonText
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnSecondaryContainer
                }
            }
        }
    }
}
