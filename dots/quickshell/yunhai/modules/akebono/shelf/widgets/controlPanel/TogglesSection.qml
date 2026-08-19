pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono
import qs.modules.akebono.shelf.widgets.controlPanel.toggles

Column {
    id: section
    required property var panel
    spacing: 0

    function componentForType(type) {
        switch (type) {
        case "network": return compNetwork;
        case "bluetooth": return compBluetooth;
        case "nightLight": return compNightLight;
        case "gameMode": return compGameMode;
        case "idleInhibitor": return compIdleInhibitor;
        case "easyEffects": return compEasyEffects;
        case "cloudflareWarp": return compCloudflareWarp;
        case "darkMode": return compDarkMode;
        case "audio": return compAudio;
        case "mic": return compMic;
        case "screenSnip": return compScreenSnip;
        case "record": return compRecord;
        case "onScreenKeyboard": return compOnScreenKeyboard;
        case "musicRecognition": return compMusicRecognition;
        default: return null;
        }
    }

    function removeToggle(type) {
        let list = [...section.panel.enabledToggles];
        const idx = list.indexOf(type);
        if (idx >= 0)
            list.splice(idx, 1);
        Config.options.akebono.shelf.quickSettings.toggles = list;
    }
    function addToggle(type) {
        let list = [...section.panel.enabledToggles];
        list.push(type);
        Config.options.akebono.shelf.quickSettings.toggles = list;
    }
    function moveToggle(index, offset) {
        let list = [...section.panel.enabledToggles];
        const target = index + offset;
        if (target < 0 || target >= list.length)
            return;
        const tmp = list[index];
        list[index] = list[target];
        list[target] = tmp;
        Config.options.akebono.shelf.quickSettings.toggles = list;
    }

    Component { id: compNetwork; NetworkToggle {} }
    Component { id: compBluetooth; BluetoothToggle {} }
    Component { id: compNightLight; NightLightToggle {} }
    Component { id: compGameMode; GameModeToggle {} }
    Component { id: compIdleInhibitor; IdleInhibitorToggle {} }
    Component { id: compEasyEffects; EasyEffectsToggle {} }
    Component { id: compCloudflareWarp; CloudflareWarpToggle {} }
    Component { id: compDarkMode; DarkModeToggle {} }
    Component { id: compAudio; AudioToggle {} }
    Component { id: compMic; MicToggle {} }
    Component { id: compScreenSnip; ScreenSnipToggle {} }
    Component { id: compRecord; RecordToggle {} }
    Component { id: compOnScreenKeyboard; OnScreenKeyboardToggle {} }
    Component { id: compMusicRecognition; MusicRecognitionToggle {} }

    Item {
        id: editPanelWrapper
        width: parent.width
        clip: true
        height: section.panel.shelf?.qsEditH ?? 0
        opacity: section.panel.editMode ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Binding {
            target: section.panel.shelf
            property: "qsEditH"
            value: section.panel.editMode ? editCol.implicitHeight : 0
            when: section.panel.shelf !== null
        }

        Column {
            id: editCol
            width: parent.width
            anchors.bottom: parent.bottom
            spacing: 10
            bottomPadding: 10

            Flow {
                id: addFlow
                width: parent.width
                spacing: 6

                Repeater {
                    model: section.panel.allToggleTypes.filter(t => !section.panel.enabledToggles.includes(t))
                    delegate: Item {
                        id: addSlot
                        required property string modelData
                        width: 48
                        height: 48
                        visible: addLoader.item?.shown ?? true
                        opacity: 0.55

                        Loader {
                            id: addLoader
                            anchors.fill: parent
                            sourceComponent: section.componentForType(addSlot.modelData)
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            z: 100
                            onClicked: section.addToggle(addSlot.modelData)
                        }
                    }
                }
            }
            Rectangle {
                width: parent.width
                height: 1
                color: Appearance.colors.colOnLayer0
                opacity: 0.14
            }
        }
    }

    Item {
        width: parent.width
        implicitHeight: Math.max(toggleFlick.height, 48)

        MouseArea {
            id: wheelScrollArea
            anchors.fill: toggleFlick
            z: 1
            visible: section.panel.flickMode && !section.panel.editMode
            acceptedButtons: Qt.NoButton
            property real targetX: toggleFlick.contentX
            onWheel: event => {
                targetX = Math.max(0, Math.min(toggleFlick.contentWidth - toggleFlick.width, targetX - event.angleDelta.y));
                scrollAnim.stop();
                scrollAnim.from = toggleFlick.contentX;
                scrollAnim.to = targetX;
                scrollAnim.restart();
                event.accepted = true;
            }
        }
        NumberAnimation {
            id: scrollAnim
            target: toggleFlick
            property: "contentX"
            duration: 300
            easing.type: Easing.OutCubic
        }

        Flickable {
            id: toggleFlick
            anchors.left: parent.left
            anchors.right: chevronBtn.left
            anchors.rightMargin: 4
            anchors.top: parent.top
            height: section.panel.flickMode ? 48 : toggleFlow.implicitHeight
            contentWidth: toggleFlow.width
            contentHeight: toggleFlow.implicitHeight
            flickableDirection: Flickable.HorizontalFlick
            interactive: section.panel.flickMode
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Flow {
                id: toggleFlow
                width: section.panel.flickMode
                    ? (section.panel.enabledToggles.length * 48 + Math.max(0, section.panel.enabledToggles.length - 1) * spacing)
                    : toggleFlick.width
                spacing: 6

                Repeater {
                    model: section.panel.enabledToggles
                    delegate: Item {
                        id: toggleSlot
                        required property string modelData
                        required property int index
                        width: 48
                        height: 48
                        visible: toggleLoader.item?.shown ?? true
                        opacity: section.panel.editMode ? 0.6 : 1
                        Behavior on opacity { NumberAnimation { duration: 150 } }

                        Loader {
                            id: toggleLoader
                            anchors.fill: parent
                            sourceComponent: section.componentForType(toggleSlot.modelData)
                            onLoaded: if (item) item.panel = section.panel
                        }
                        MouseArea {
                            visible: !section.panel.editMode && section.panel.hasDialog(toggleSlot.modelData)
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            z: 50
                            onClicked: section.panel.activeDialog = section.panel.activeDialog === toggleSlot.modelData ? "" : toggleSlot.modelData
                        }
                        MouseArea {
                            visible: section.panel.editMode
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            z: 100
                            onClicked: section.removeToggle(toggleSlot.modelData)
                            onWheel: event => {
                                section.moveToggle(toggleSlot.index, event.angleDelta.y > 0 ? -1 : 1);
                                event.accepted = true;
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: chevronBtn
            anchors.right: parent.right
            anchors.top: parent.top
            width: 48
            height: 48

            MaterialSymbol {
                anchors.centerIn: parent
                text: "chevron_left"
                rotation: section.panel.editMode ? 90 : 0
                iconSize: 22
                color: Appearance.colors.colSubtext
                Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            }
            RippleArea {
                shapeRadius: 16
                rippleColor: Appearance.colors.colOnLayer2
                onClicked: section.panel.editMode = !section.panel.editMode
            }
        }
    }
}
