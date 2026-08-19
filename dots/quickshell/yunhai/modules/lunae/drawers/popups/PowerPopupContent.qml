pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.lunae

Column {
    id: root
    spacing: 12
    x: -16
    y: 8

    Rectangle {
        id: profiles

        property string current: {
            switch (PowerProfiles.profile) {
                case PowerProfile.PowerSaver: return saver.icon
                case PowerProfile.Performance: return perf.icon
                default: return balanced.icon
            }
        }

        anchors.horizontalCenter: parent.horizontalCenter
        implicitWidth: saver.width + balanced.width + perf.width + 16 + 12
        implicitHeight: 46
        color: Appearance.colors.colSurfaceContainer
        radius: Appearance.rounding.full

        Rectangle {
            id: indicator
            color: Appearance.m3colors.m3primary
            radius: Appearance.rounding.full
            state: profiles.current

            states: [
                State {
                    name: saver.icon
                    AnchorChanges {
                        target: indicator
                        anchors.left: saver.left
                        anchors.right: saver.right
                        anchors.top: saver.top
                        anchors.bottom: saver.bottom
                    }
                },
                State {
                    name: balanced.icon
                    AnchorChanges {
                        target: indicator
                        anchors.left: balanced.left
                        anchors.right: balanced.right
                        anchors.top: balanced.top
                        anchors.bottom: balanced.bottom
                    }
                },
                State {
                    name: perf.icon
                    AnchorChanges {
                        target: indicator
                        anchors.left: perf.left
                        anchors.right: perf.right
                        anchors.top: perf.top
                        anchors.bottom: perf.bottom
                    }
                }
            ]

            transitions: Transition {
                AnchorAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
        }

        component ProfileButton: Item {
            required property string icon
            required property int profile
            width: 42; height: 42

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: PowerProfiles.profile = parent.profile
            }

            MaterialSymbol {
                anchors.centerIn: parent
                text: parent.icon
                iconSize: 24
                fill: profiles.current === parent.icon ? 1 : 0
                color: profiles.current === parent.icon
                    ? Appearance.m3colors.m3onPrimary
                    : Appearance.colors.colOnSurfaceVariant

                Behavior on fill {
                    NumberAnimation { duration: 200 }
                }
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }
        }

        ProfileButton {
            id: saver
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 4
            icon: "energy_savings_leaf"
            profile: PowerProfile.PowerSaver
        }

        ProfileButton {
            id: balanced
            anchors.centerIn: parent
            icon: "balance"
            profile: PowerProfile.Balanced
        }

        ProfileButton {
            id: perf
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 4
            icon: "rocket_launch"
            profile: PowerProfile.Performance
        }
    }

    Rectangle {
        width: parent.implicitWidth - 16
        anchors.horizontalCenter: parent.horizontalCenter
        height: 1
        color: Appearance.colors.colOutlineVariant
    }

    Grid {
        columns: 4
        spacing: 6

        Repeater {
            model: [
                { icon: "lock", label: Translation.tr("Lock"), action: () => { GlobalStates.activeBarPopup = ""; Session.lock() } },
                { icon: "dark_mode", label: Translation.tr("Sleep"), action: () => { GlobalStates.activeBarPopup = ""; Session.suspend() } },
                { icon: "logout", label: Translation.tr("Logout"), action: () => Session.logout() },
                { icon: "browse_activity", label: Translation.tr("Tasks"), action: () => { Session.launchTaskManager(); GlobalStates.activeBarPopup = "" } },
                { icon: "downloading", label: Translation.tr("Hibernate"), action: () => Session.hibernate() },
                { icon: "power_settings_new", label: Translation.tr("Shutdown"), action: () => Session.poweroff() },
                { icon: "restart_alt", label: Translation.tr("Reboot"), action: () => Session.reboot() },
                { icon: "settings_applications", label: Translation.tr("Firmware"), action: () => Session.rebootToFirmware() },
            ]

            delegate: Column {
                required property var modelData
                spacing: 3
                width: 48

                RippleButton {
                    width: 48; height: 48
                    buttonRadius: Appearance.rounding.small
                    buttonRadiusPressed: Appearance.rounding.unsharpenmore
                    colBackground: Appearance.colors.colLayer1
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active

                    Behavior on buttonEffectiveRadius {
                        NumberAnimation {
                            duration: LunaeAppearance.morphDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: LunaeAppearance.morphCurve
                        }
                    }

                    onClicked: modelData.action()

                    contentItem: Item {
                        MaterialSymbol {
                            anchors.centerIn: parent
                            text: modelData.icon
                            iconSize: 22
                            fill: 0
                            color: Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }

                StyledText {
                    width: 48
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colOnSurfaceVariant
                    text: modelData.label
                    elide: Text.ElideRight
                }
            }
        }
    }
}
