import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae.widgets

LunaeCard {
    id: root

    property bool timerExpanded: false

    Layout.fillWidth: true
    implicitHeight: profileColumn.implicitHeight
    clip: true

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    Column {
        id: profileColumn
        width: parent.width

        Item {
            width: parent.width
            height: 56

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 12

                CookieImage {
                    Layout.alignment: Qt.AlignVCenter
                    width: 42
                    height: 42
                    source: (Directories.userAvatarPathAccountsService && !Directories.userAvatarPathAccountsService.endsWith("/user")) ? Directories.userAvatarPathAccountsService : ""
                    lobes: 9
                    scallop: 0.05
                    fallbackIcon: "person"
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    text: SystemInfo.username
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                    font.variableAxes: {"wght": 600}
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 4

                    RippleButton {
                        implicitWidth: 42; implicitHeight: 42
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        buttonRadius: Appearance.rounding.small
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        colRipple: Appearance.colors.colLayer1Active
                        onClicked: {
                            Hyprland.dispatch("reload");
                            Quickshell.reload(true);
                        }

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "restart_alt"
                            iconSize: 22
                            color: Appearance.colors.colOnLayer1
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        StyledToolTip {
                            text: Translation.tr("Reload Hyprland & Quickshell")
                        }
                    }

                    RippleButton {
                        implicitWidth: 42; implicitHeight: 42
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        buttonRadius: Appearance.rounding.small
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        colRipple: Appearance.colors.colLayer1Active
                        onClicked: {
                            Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")])
                            GlobalStates.sidebarRightOpen = false
                            GlobalStates.sidebarToggleOpen = false
                        }

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "settings"
                            iconSize: 22
                            color: Appearance.colors.colOnLayer1
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        StyledToolTip {
                            text: Translation.tr("Settings")
                        }
                    }

                    RippleButton {
                        id: footerChevronBtn
                        implicitWidth: 42; implicitHeight: 42
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        buttonRadius: Appearance.rounding.small
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer1Hover
                        colRipple: Appearance.colors.colLayer1Active
                        onClicked: root.timerExpanded = !root.timerExpanded

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "chevron_left"
                            rotation: root.timerExpanded ? -90 : 0
                            iconSize: 22
                            color: Appearance.colors.colOnLayer1
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            Behavior on rotation {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }
            }
        }

        TimerSection {
            id: timerSection
            width: parent.width
            visible: root.timerExpanded
            opacity: 0

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            Timer {
                running: root.timerExpanded
                interval: 80
                onTriggered: timerSection.opacity = 1
            }
            onVisibleChanged: if (!visible) opacity = 0
        }
    }
}
