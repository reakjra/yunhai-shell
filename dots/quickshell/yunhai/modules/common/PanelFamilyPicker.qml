pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    GlobalShortcut {
        name: "panelFamilyPicker"
        description: "Open the panel family picker"
        onPressed: GlobalStates.panelFamilyPickerOpen = !GlobalStates.panelFamilyPickerOpen
    }

    IpcHandler {
        target: "panelFamilyPicker"

        function toggle(): void {
            GlobalStates.panelFamilyPickerOpen = !GlobalStates.panelFamilyPickerOpen
        }
    }

    Loader {
        id: pickerLoader
        active: GlobalStates.panelFamilyPickerOpen || ((pickerLoader.item?.anim ?? 0) > 0.01)

        sourceComponent: PanelWindow {
            id: win
            visible: true
            color: "transparent"
            WlrLayershell.namespace: "quickshell:panelFamilyPicker"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            property real anim: 0
            Behavior on anim {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
            Component.onCompleted: anim = 1

            Connections {
                target: GlobalStates
                function onPanelFamilyPickerOpenChanged() {
                    win.anim = GlobalStates.panelFamilyPickerOpen ? 1 : 0;
                }
            }

            HyprlandFocusGrab {
                active: GlobalStates.panelFamilyPickerOpen
                windows: [win]
                onCleared: GlobalStates.panelFamilyPickerOpen = false
            }

            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: 0.42 * win.anim
                MouseArea {
                    anchors.fill: parent
                    onClicked: GlobalStates.panelFamilyPickerOpen = false
                }
            }

            Rectangle {
                id: card
                anchors.centerIn: parent
                radius: Appearance.rounding.large
                color: Appearance.colors.colLayer0
                implicitWidth: col.implicitWidth + 48
                implicitHeight: col.implicitHeight + 40
                opacity: win.anim
                scale: 0.96 + 0.04 * win.anim
                focus: true

                Component.onCompleted: card.forceActiveFocus()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.panelFamilyPickerOpen = false;
                        event.accepted = true;
                    }
                }

                ColumnLayout {
                    id: col
                    anchors.centerIn: parent
                    spacing: 18

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Panel Family"
                        font.pixelSize: Appearance.font.pixelSize.larger
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colOnLayer0
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12

                        Repeater {
                            model: PanelFamilies.list

                            delegate: Rectangle {
                                id: familyCard
                                required property var modelData

                                readonly property bool current: Config.options.panelFamily === modelData.id

                                implicitWidth: 152
                                implicitHeight: 146
                                radius: Appearance.rounding.normal
                                color: current ? Appearance.colors.colPrimaryContainer
                                    : cardHover.containsMouse ? Appearance.colors.colLayer1Hover
                                    : Appearance.colors.colLayer1
                                border.width: current ? 2 : 0
                                border.color: Appearance.colors.colPrimary

                                Behavior on color {
                                    ColorAnimation { duration: 120 }
                                }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    width: parent.width - 16
                                    spacing: 6

                                    MaterialSymbol {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: familyCard.modelData.icon
                                        iconSize: 40
                                        color: familyCard.current ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: familyCard.modelData.name
                                        font.pixelSize: Appearance.font.pixelSize.normal
                                        font.weight: familyCard.current ? Font.DemiBold : Font.Normal
                                        color: familyCard.current ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: familyCard.modelData.blurb
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: familyCard.current ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                                        opacity: 0.85
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    id: cardHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Config.options.panelFamily = familyCard.modelData.id;
                                        GlobalStates.panelFamilyPickerOpen = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
