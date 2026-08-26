pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae.widgets
import qs.modules.lunae.sidebarRight.quickToggles.classicStyle
import qs.modules.lunae.sidebarRight.quickToggles.dialogs

LunaeCard {
    id: root

    Layout.fillWidth: true
    clip: true

    readonly property bool flickableMode: Config.options.lunae.sidebar.toggles.flickable
    property bool editMode: false

    readonly property var allToggleTypes: ["network", "bluetooth", "nightLight", "gameMode", "idleInhibitor", "easyEffects", "cloudflareWarp", "darkMode", "audio", "mic", "screenSnip", "record", "onScreenKeyboard", "musicRecognition"]
    readonly property int enabledToggleCount: (Config.options.lunae.sidebar.toggles.enabled ?? []).length
    property string activeDialog: ""
    onEditModeChanged: if (editMode) activeDialog = ""

    function hasDialog(type) {
        return ["network", "bluetooth", "nightLight", "audio", "mic", "record", "gameMode"].includes(type)
    }

    function dialogTitle(type) {
        switch (type) {
            case "network": return Translation.tr("Wi-Fi")
            case "bluetooth": return Translation.tr("Bluetooth")
            case "nightLight": return Translation.tr("Eye protection")
            case "audio": return Translation.tr("Audio output")
            case "mic": return Translation.tr("Audio input")
            case "record": return Translation.tr("Recording")
            case "gameMode": return Translation.tr("Game mode")
            default: return ""
        }
    }

    function componentForType(type) {
        switch (type) {
            case "network": return compNetwork
            case "bluetooth": return compBluetooth
            case "nightLight": return compNightLight
            case "gameMode": return compGameMode
            case "idleInhibitor": return compIdleInhibitor
            case "easyEffects": return compEasyEffects
            case "cloudflareWarp": return compCloudflareWarp
            case "darkMode": return compDarkMode
            case "audio": return compAudio
            case "mic": return compMic
            case "screenSnip": return compScreenSnip
            case "record": return compRecord
            case "onScreenKeyboard": return compOnScreenKeyboard
            case "musicRecognition": return compMusicRecognition
            default: return null
        }
    }

    function dialogComponentForType(type) {
        switch (type) {
            case "nightLight": return compNightLightDialog
            case "network": return compNetworkDialog
            case "bluetooth": return compBluetoothDialog
            case "audio": return compAudioOutputDialog
            case "mic": return compAudioInputDialog
            case "record": return compRecordDialog
            case "gameMode": return compGameModeDialog
            default: return null
        }
    }

    function removeToggle(type) {
        let list = [...Config.options.lunae.sidebar.toggles.enabled]
        const idx = list.indexOf(type)
        if (idx >= 0) list.splice(idx, 1)
        Config.options.lunae.sidebar.toggles.enabled = list
    }

    function addToggle(type) {
        let list = [...Config.options.lunae.sidebar.toggles.enabled]
        list.push(type)
        Config.options.lunae.sidebar.toggles.enabled = list
    }

    function moveToggle(index, offset) {
        let list = [...Config.options.lunae.sidebar.toggles.enabled]
        const targetIndex = index + offset
        if (targetIndex < 0 || targetIndex >= list.length) return
        const temp = list[index]
        list[index] = list[targetIndex]
        list[targetIndex] = temp
        Config.options.lunae.sidebar.toggles.enabled = list
    }

    Component { id: compNetwork; NetworkToggle { baseWidth: 48; baseHeight: 48; bounce: false } }
    Component { id: compBluetooth; BluetoothToggle { baseWidth: 48; baseHeight: 48; bounce: false } }
    Component { id: compNightLight; NightLight { baseWidth: 48; baseHeight: 48; bounce: false } }
    Component { id: compGameMode; GameModeToggle { baseWidth: 48; baseHeight: 48; bounce: false } }
    Component { id: compIdleInhibitor; IdleInhibitor { baseWidth: 48; baseHeight: 48; bounce: false } }
    Component { id: compEasyEffects; EasyEffectsToggle { baseWidth: 48; baseHeight: 48; bounce: false } }
    Component { id: compCloudflareWarp; CloudflareWarp { baseWidth: 48; baseHeight: 48; bounce: false } }
    Component { id: compDarkMode; DarkModeToggle { baseWidth: 48; baseHeight: 48; bounce: false } }
    Component { id: compAudio; AudioToggle { baseWidth: 48; baseHeight: 48; bounce: false } }
    Component { id: compMic; MicToggle { baseWidth: 48; baseHeight: 48; bounce: false } }
    Component { id: compScreenSnip; ScreenSnipToggle { baseWidth: 48; baseHeight: 48; bounce: false } }
    Component { id: compRecord; RecordToggle { baseWidth: 48; baseHeight: 48; bounce: false } }
    Component { id: compOnScreenKeyboard; OnScreenKeyboardToggle { baseWidth: 48; baseHeight: 48; bounce: false } }
    Component { id: compMusicRecognition; MusicRecognitionToggle { baseWidth: 48; baseHeight: 48; bounce: false } }

    Component { id: compNightLightDialog; NightLightDialog {} }
    Component { id: compNetworkDialog; NetworkDialog {} }
    Component { id: compBluetoothDialog; BluetoothDialog {} }
    Component { id: compAudioOutputDialog; AudioOutputDialog {} }
    Component { id: compAudioInputDialog; AudioInputDialog {} }
    Component { id: compRecordDialog; RecordDialog {} }
    Component { id: compGameModeDialog; GameModeDialog {} }

    implicitHeight: toggleContent.implicitHeight + 20

    Behavior on implicitHeight {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }

    Column {
        id: toggleContent
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 10
        }
        spacing: 8

        Item {
            id: editPanelWrapper
            width: parent.width
            visible: root.editMode && root.enabledToggleCount < root.allToggleTypes.length
            implicitHeight: visible ? editFlow.implicitHeight : 0
            opacity: 0

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            Timer {
                running: root.editMode
                interval: 150
                onTriggered: editPanelWrapper.opacity = 1
            }

            onVisibleChanged: if (!visible) opacity = 0

            Flow {
                id: editFlow
                width: parent.width
                spacing: 4

                Repeater {
                    model: {
                        const enabled = Config.options.lunae.sidebar.toggles.enabled
                        return root.allToggleTypes.filter(t => !enabled.includes(t))
                    }
                    delegate: Item {
                        required property string modelData
                        required property int index
                        width: 48; height: 48
                        opacity: editPanelWrapper.opacity

                        Loader {
                            anchors.fill: parent
                            sourceComponent: root.componentForType(modelData)
                            onLoaded: if (item) item.visible = true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            z: 100
                            onClicked: root.addToggle(modelData)
                        }
                    }
                }
            }
        }

        Item {
            id: dialogPanelWrapper
            width: parent.width
            visible: root.activeDialog !== ""
            implicitHeight: visible ? dialogColumn.implicitHeight : 0
            opacity: 0

            property string displayDialog: ""
            onVisibleChanged: {
                if (!visible) {
                    opacity = 0
                    displayDialog = ""
                } else {
                    displayDialog = root.activeDialog
                }
            }

            Connections {
                target: root
                function onActiveDialogChanged() {
                    if (root.activeDialog !== "" && dialogPanelWrapper.visible && root.activeDialog !== dialogPanelWrapper.displayDialog) {
                        dialogSwapAnim.restart()
                    } else if (root.activeDialog !== "") {
                        dialogPanelWrapper.displayDialog = root.activeDialog
                    }
                }
            }

            SequentialAnimation {
                id: dialogSwapAnim
                NumberAnimation {
                    target: dialogColumn
                    property: "opacity"
                    to: 0
                    duration: 150
                    easing.type: Easing.InCubic
                }
                ScriptAction {
                    script: dialogPanelWrapper.displayDialog = root.activeDialog
                }
                NumberAnimation {
                    target: dialogColumn
                    property: "opacity"
                    to: dialogPanelWrapper.opacity
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            Timer {
                running: root.activeDialog !== ""
                interval: 100
                onTriggered: dialogPanelWrapper.opacity = 1
            }

            Column {
                id: dialogColumn
                width: parent.width
                spacing: 0
                bottomPadding: 6
                opacity: dialogPanelWrapper.opacity

                Item {
                    width: parent.width
                    implicitHeight: 52

                    StyledText {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.dialogTitle(dialogPanelWrapper.displayDialog)
                        font.pixelSize: Appearance.font.pixelSize.huge
                        color: Appearance.colors.colOnLayer1
                    }

                    GroupButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        baseWidth: 48; baseHeight: 48
                        buttonRadius: Appearance.rounding.small
                        bounce: false
                        colBackground: "transparent"
                        onClicked: root.activeDialog = ""

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "check"
                            iconSize: 22
                            color: Appearance.colors.colOnLayer1
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Appearance.colors.colOnLayer1
                    opacity: 0.15
                }

                Loader {
                    width: parent.width
                    sourceComponent: root.dialogComponentForType(dialogPanelWrapper.displayDialog)
                }
            }
        }

        Item {
            width: parent.width
            implicitHeight: Math.max(toggleFlickable.height, chevronBtn.implicitHeight)

            MouseArea {
                id: wheelScrollArea
                anchors.fill: toggleFlickable
                z: 1
                visible: root.flickableMode && !root.editMode
                acceptedButtons: Qt.NoButton
                property real targetX: toggleFlickable.contentX
                onWheel: (event) => {
                    targetX = Math.max(0,
                        Math.min(toggleFlickable.contentWidth - toggleFlickable.width,
                            targetX - event.angleDelta.y))
                    scrollAnim.stop()
                    scrollAnim.from = toggleFlickable.contentX
                    scrollAnim.to = targetX
                    scrollAnim.restart()
                    event.accepted = true
                }
            }
            NumberAnimation {
                id: scrollAnim
                target: toggleFlickable
                property: "contentX"
                duration: 300
                easing.type: Easing.OutCubic
            }

            Flickable {
                id: toggleFlickable
                anchors.left: parent.left
                anchors.right: chevronBtn.left
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                height: root.flickableMode ? 48 : toggleFlow.implicitHeight
                contentWidth: toggleFlow.width
                contentHeight: toggleFlow.implicitHeight
                flickableDirection: Flickable.HorizontalFlick
                interactive: root.flickableMode
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Flow {
                    id: toggleFlow
                    width: root.flickableMode
                        ? (root.enabledToggleCount * 48 + Math.max(0, root.enabledToggleCount - 1) * spacing)
                        : toggleFlickable.width
                    spacing: 4

                    Repeater {
                        model: Config.options.lunae.sidebar.toggles.enabled ?? []
                        delegate: Item {
                            id: toggleSlot
                            required property string modelData
                            required property int index
                            width: 48; height: 48
                            opacity: root.editMode ? 0.6 : 1.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }

                            Loader {
                                anchors.fill: parent
                                sourceComponent: root.componentForType(toggleSlot.modelData)
                                onLoaded: if (item) item.visible = true
                            }

                            MouseArea {
                                visible: root.editMode
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                z: 100
                                onClicked: root.removeToggle(toggleSlot.modelData)
                                onWheel: (event) => {
                                    root.moveToggle(toggleSlot.index, event.angleDelta.y > 0 ? -1 : 1)
                                    event.accepted = true
                                }
                            }

                            MouseArea {
                                visible: !root.editMode && root.hasDialog(toggleSlot.modelData)
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                z: 50
                                onClicked: {
                                    root.activeDialog = root.activeDialog === toggleSlot.modelData ? "" : toggleSlot.modelData
                                }
                            }
                        }
                    }
                }
            }

            GroupButton {
                id: chevronBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                baseWidth: 48; baseHeight: 48
                buttonRadius: Appearance.rounding.small
                bounce: false
                colBackground: "transparent"
                onClicked: root.editMode = !root.editMode

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "chevron_left"
                    rotation: root.editMode ? 90 : 0
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
