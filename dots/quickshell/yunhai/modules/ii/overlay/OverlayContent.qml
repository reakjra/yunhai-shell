import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas

Item {
    id: root
    focus: true
    readonly property bool usePasswordChars: !PolkitService.flow?.responseVisible ?? true

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.overlayOpen = false;
        }
    }

    Connections {
        target: GlobalStates
        function onOverlayOpenChanged() {
            if (!GlobalStates.overlayOpen)
                taskbar.settingsMenuOpen = false;
        }
    }

    property real initScale: Config.options.overlay.openingZoomAnimation ? 1.08 : 1.000001
    scale: initScale
    Component.onCompleted: {
        scale = 1
    }
    Behavior on scale {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        color: Appearance.colors.colScrim
        visible: Config.options.overlay.darkenScreen && opacity > 0
        opacity: (GlobalStates.overlayOpen && root.scale !== initScale) ? 1 : 0
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    WidgetCanvas {
        anchors.fill: parent
        onClicked: GlobalStates.overlayOpen = false

        OverlayTaskbar {
            id: taskbar
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 50
            }
        }

        Rectangle {
            id: settingsPopup
            visible: opacity > 0
            opacity: taskbar.settingsMenuOpen ? 1 : 0

            x: (parent.width / 2) - (width / 2)
            y: taskbar.y + taskbar.implicitHeight + 8

            width: 260
            implicitHeight: settingsLoader.item ? settingsLoader.item.implicitHeight : 0

            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.large
            border.color: Appearance.colors.colOutlineVariant
            border.width: 1

            scale: taskbar.settingsMenuOpen ? 1 : 0.95
            transformOrigin: Item.Top

            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }

            Loader {
                id: settingsLoader
                anchors.fill: parent
                active: taskbar.settingsMenuOpen || settingsPopup.opacity > 0
                sourceComponent: SettingsMenu {}
            }
        }

        Repeater {
            model: ScriptModel {
                values: Persistent.states.overlay.open.map(identifier => {
                    return OverlayContext.availableWidgets.find(w => w.identifier === identifier);
                })
                objectProp: "identifier"
            }
            delegate: OverlayWidgetDelegateChooser {

            }
        }
    }

    component SettingsMenu: Item {
        implicitHeight: Math.min(menuContent.implicitHeight + 16, 340)
        implicitWidth: 260

        ScrollView {
            anchors {
                fill: parent
                topMargin: 8
                bottomMargin: 8
            }
            clip: true
            contentWidth: -1

            Column {
                id: menuContent
                width: 260
                leftPadding: 8
                rightPadding: 8
                spacing: 2

                Repeater {
                    model: Object.keys(OverlayContext.widgetSymbols).map(key => ({
                        identifier: key,
                        materialSymbol: OverlayContext.widgetSymbols[key],
                        widgetName: key.replace(/([A-Z])/g, ' $1').trim().replace(/^\w/, c => c.toUpperCase())
                    }))

                    delegate: SettingsMenuItem {
                        required property var modelData
                        identifier: modelData.identifier
                        materialSymbol: modelData.materialSymbol
                        widgetName: modelData.widgetName
                    }
                }
            }
        }
    }

    component SettingsMenuItem: RippleButton {
        required property string identifier
        required property string materialSymbol
        required property string widgetName

        property bool isActive: Config.options.overlay.buttons.includes(identifier)

        width: 244
        height: 36

        toggled: isActive
        buttonRadius: Appearance.rounding.small

        colBackgroundToggled: Appearance.colors.colSecondaryContainer
        colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
        colRippleToggled: Appearance.colors.colSecondaryContainerActive

        onClicked: {
            const buttons = Config.options.overlay.buttons
            Config.options.overlay.buttons = isActive ?
                buttons.filter(id => id !== identifier) :
                [...buttons, identifier]
        }

        contentItem: RowLayout {
            spacing: 8
            anchors {
                fill: parent
                leftMargin: 12
                rightMargin: 12
            }

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                iconSize: 20
                text: parent.parent.materialSymbol
                color: parent.parent.isActive ?
                    Appearance.colors.colOnSecondaryContainer :
                    Appearance.colors.colOnSurfaceVariant
            }

            StyledText {
                Layout.alignment: Qt.AlignVCenter
                Layout.fillWidth: true
                text: parent.parent.widgetName
                elide: Text.ElideRight
                color: parent.parent.isActive ?
                    Appearance.colors.colOnSecondaryContainer :
                    Appearance.colors.colOnSurface
                font.pixelSize: Appearance.font.pixelSize.small
            }

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                iconSize: 18
                text: "star"
                fill: parent.parent.isActive ? 1 : 0
                color: parent.parent.isActive ?
                    Appearance.colors.colOnSecondaryContainer :
                    Appearance.colors.colOnSurfaceVariant
            }
        }
    }
}
