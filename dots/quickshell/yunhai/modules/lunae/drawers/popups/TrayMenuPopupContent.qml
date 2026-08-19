pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    x: -20

    readonly property var menuHandle: GlobalStates.trayMenuHandle
    readonly property string trayItemId: GlobalStates.trayMenuItemId

    readonly property real maxMenuWidth: 280
    implicitWidth: Math.min(stackView.implicitWidth, maxMenuWidth)
    implicitHeight: stackView.implicitHeight



    SequentialAnimation {
        id: switchAnim
        property var pendingHandle: null

        NumberAnimation { target: stackView; property: "opacity"; to: 0; duration: 100
            easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.standard }
        ScriptAction {
            script: {
                stackView.clear()
                if (switchAnim.pendingHandle)
                    stackView.push(mainMenuComp.createObject(null, { handle: switchAnim.pendingHandle }))
            }
        }
        NumberAnimation { target: stackView; property: "opacity"; to: 1; duration: 150
            easing.type: Easing.BezierSpline; easing.bezierCurve: Appearance.animationCurves.standard }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        pushEnter: Transition { NumberAnimation { duration: 0 } }
        pushExit: Transition { NumberAnimation { duration: 0 } }
        popEnter: Transition { NumberAnimation { duration: 0 } }
        popExit: Transition { NumberAnimation { duration: 0 } }

        implicitWidth: currentItem?.implicitWidth ?? 0
        implicitHeight: currentItem?.implicitHeight ?? 0

        Component.onCompleted: {
            if (root.menuHandle)
                stackView.push(mainMenuComp.createObject(null, { handle: root.menuHandle }))
        }

        Connections {
            target: GlobalStates
            function onTrayMenuHandleChanged() {
                if (stackView.depth > 0 && GlobalStates.trayMenuHandle) {
                    switchAnim.pendingHandle = GlobalStates.trayMenuHandle
                    switchAnim.restart()
                } else {
                    stackView.clear()
                    if (GlobalStates.trayMenuHandle)
                        stackView.push(mainMenuComp.createObject(null, { handle: GlobalStates.trayMenuHandle }))
                }
            }
        }
    }

    Component {
        id: mainMenuComp
        SubMenuView {
            isSubMenu: false
            trayItemId: root.trayItemId
        }
    }

    Component {
        id: subMenuComp
        SubMenuView {
            isSubMenu: true
            trayItemId: ""
        }
    }

    component SubMenuView: ColumnLayout {
        id: submenu
        required property QsMenuHandle handle
        property bool isSubMenu: false
        property string trayItemId: ""
        property bool shown: false
        opacity: shown ? 1 : 0

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        Component.onCompleted: shown = true
        StackView.onActivating: shown = true
        StackView.onDeactivating: shown = false
        StackView.onRemoved: destroy()

        QsMenuOpener {
            id: menuOpener
            menu: submenu.handle
        }

        spacing: 0

        RippleButton {
            id: pinEntry
            horizontalPadding: 6
            implicitWidth: pinContent.implicitWidth + horizontalPadding * 2
            implicitHeight: 26
            Layout.fillWidth: true
            visible: submenu.trayItemId.length > 0 && stackView.depth === 1

            releaseAction: () => TrayService.togglePin(submenu.trayItemId)

            contentItem: Item {
                RowLayout {
                    id: pinContent
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        right: parent.right
                        leftMargin: pinEntry.horizontalPadding
                        rightMargin: pinEntry.horizontalPadding
                    }
                    spacing: 6

                    MaterialSymbol {
                        iconSize: 16
                        text: "push_pin"
                    }

                    StyledText {
                        Layout.fillWidth: true
                        font.pixelSize: Appearance.font.pixelSize.smallie
                        text: TrayService.isPinned(submenu.trayItemId) ? Translation.tr("Unpin") : Translation.tr("Pin")
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Appearance.colors.colSubtext
            Layout.topMargin: 2
            Layout.bottomMargin: 2
            visible: pinEntry.visible
        }

        Loader {
            Layout.fillWidth: true
            visible: submenu.isSubMenu
            active: visible
            sourceComponent: RippleButton {
                id: backButton
                horizontalPadding: 6
                implicitWidth: backContent.implicitWidth + horizontalPadding * 2
                implicitHeight: 26

                downAction: () => stackView.pop()

                contentItem: Item {
                    RowLayout {
                        id: backContent
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            right: parent.right
                            leftMargin: backButton.horizontalPadding
                            rightMargin: backButton.horizontalPadding
                        }
                        spacing: 8
                        MaterialSymbol {
                            iconSize: 20
                            text: "chevron_left"
                        }
                        StyledText {
                            Layout.fillWidth: true
                            text: Translation.tr("Back")
                        }
                    }
                }
            }
        }

        Repeater {
            id: menuEntriesRepeater
            property bool iconColumnNeeded: {
                for (let i = 0; i < menuOpener.children.values.length; i++) {
                    if (menuOpener.children.values[i].icon.length > 0)
                        return true;
                }
                return false;
            }
            property bool specialInteractionColumnNeeded: {
                for (let i = 0; i < menuOpener.children.values.length; i++) {
                    if (menuOpener.children.values[i].buttonType !== QsMenuButtonType.None)
                        return true;
                }
                return false;
            }
            model: menuOpener.children
            delegate: RippleButton {
                id: entryButton
                required property QsMenuEntry modelData
                readonly property bool hasIcon: modelData.icon.length > 0
                readonly property bool hasSpecialInteraction: modelData.buttonType !== QsMenuButtonType.None

                colBackground: modelData.isSeparator ? Appearance.m3colors.m3outlineVariant : ColorUtils.transparentize(Appearance.colors.colLayer0)
                enabled: !modelData.isSeparator
                horizontalPadding: 6
                implicitWidth: entryContent.implicitWidth + horizontalPadding * 2
                implicitHeight: modelData.isSeparator ? 1 : 26
                Layout.topMargin: modelData.isSeparator ? 2 : 0
                Layout.bottomMargin: modelData.isSeparator ? 2 : 0
                Layout.fillWidth: true

                Component.onCompleted: {
                    if (modelData.isSeparator)
                        entryButton.buttonColor = entryButton.colBackground
                }

                releaseAction: () => {
                    if (modelData.hasChildren) {
                        stackView.push(subMenuComp.createObject(null, {
                            handle: modelData,
                            isSubMenu: true
                        }))
                        return
                    }
                    modelData.triggered()
                    GlobalStates.activeBarPopup = ""
                }
                altAction: (event) => { event.accepted = false }

                contentItem: Item {
                    RowLayout {
                        id: entryContent
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            right: parent.right
                            leftMargin: entryButton.horizontalPadding
                            rightMargin: entryButton.horizontalPadding
                        }
                        spacing: 6
                        visible: !entryButton.modelData.isSeparator

                        Item {
                            visible: entryButton.hasSpecialInteraction || menuEntriesRepeater.specialInteractionColumnNeeded
                            implicitWidth: 18
                            implicitHeight: 18

                            Loader {
                                anchors.fill: parent
                                active: entryButton.modelData.buttonType === QsMenuButtonType.RadioButton
                                sourceComponent: StyledRadioButton {
                                    enabled: false
                                    padding: 0
                                    checked: entryButton.modelData.checkState === Qt.Checked
                                }
                            }

                            Loader {
                                anchors.fill: parent
                                active: entryButton.modelData.buttonType === QsMenuButtonType.CheckBox && entryButton.modelData.checkState !== Qt.Unchecked
                                sourceComponent: MaterialSymbol {
                                    text: entryButton.modelData.checkState === Qt.PartiallyChecked ? "check_indeterminate_small" : "check"
                                    iconSize: 20
                                }
                            }
                        }

                        Item {
                            visible: entryButton.hasIcon || menuEntriesRepeater.iconColumnNeeded
                            implicitWidth: 18
                            implicitHeight: 18

                            Loader {
                                anchors.centerIn: parent
                                active: entryButton.modelData.icon.length > 0
                                sourceComponent: IconImage {
                                    asynchronous: true
                                    source: entryButton.modelData.icon
                                    implicitSize: 18
                                    mipmap: true
                                }
                            }
                        }

                        StyledText {
                            text: entryButton.modelData.text
                            font.pixelSize: Appearance.font.pixelSize.smallie
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Loader {
                            active: entryButton.modelData.hasChildren
                            sourceComponent: MaterialSymbol {
                                text: "chevron_right"
                                iconSize: 18
                            }
                        }
                    }
                }
            }
        }
    }
}
