pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.widgets
import qs.services

PanelWindow {
    id: root

    // Interface
    signal dismiss

    Component.onCompleted: {
        if (!KeyringStorage.loaded)
            KeyringStorage.fetchKeyringData();
    }

    // Window props
    visible: false
    color: "black"
    WlrLayershell.namespace: "quickshell:regionSelector"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // Config
    readonly property string screenshotDir: Directories.screenshotTemp
    readonly property string screenshotPath: `${root.screenshotDir}/image-${screen.name}`

    // Preparation
    property bool screenshotReady: false

    function performTranslation() {
        screenshotReady = true;
    }

    TempScreenshotProcess {
        id: screenshotProc
        running: true
        screen: root.screen
        screenshotDir: root.screenshotDir
        screenshotPath: root.screenshotPath
        onExited: (_, __) => {
            root.visible = true;
            root.performTranslation();
        }
    }

    // Actual content
    property real scale: 1.0
    property real contentX: 0
    property real contentY: 0

    MouseArea {
        anchors.fill: parent
        clip: true

        property real lastX: 0
        property real lastY: 0

        cursorShape: Qt.SizeAllCursor

        onPressed: mouse => {
            lastX = mouse.x;
            lastY = mouse.y;
        }

        onPositionChanged: mouse => {
            if (pressed) {
                root.contentX += (mouse.x - lastX);
                root.contentY += (mouse.y - lastY);
                lastX = mouse.x;
                lastY = mouse.y;
            }
        }

        onWheel: event => {
            const zoomFactor = event.angleDelta.y > 0 ? 1.1 : 0.9;
            const oldScale = root.scale;
            const newScale = Math.min(Math.max(0.1, oldScale * zoomFactor), 5);

            if (newScale !== oldScale) {
                const localX = (event.x - root.contentX) / oldScale;
                const localY = (event.y - root.contentY) / oldScale;

                root.scale = newScale;

                root.contentX = event.x - (localX * newScale);
                root.contentY = event.y - (localY * newScale);
            }
        }

        ScreencopyView {
            id: screencopy
            width: parent.width
            height: parent.height

            x: root.contentX
            y: root.contentY
            scale: root.scale
            transformOrigin: Item.TopLeft

            live: false
            captureSource: root.screen
        }

        Loader {
            width: parent.width * root.scale
            height: parent.height * root.scale

            x: root.contentX
            y: root.contentY

            active: root.screenshotReady
            sourceComponent: ScreenTextOverlay {
                screenshotPath: root.screenshotPath
                scaleFactor: root.scale
            }
        }
    }

    Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: -height
        }
        Behavior on anchors.bottomMargin {
            animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
        }
        Component.onCompleted: {
            anchors.bottomMargin = 8;
        }

        spacing: 6

        Toolbar {
            id: toolbar
            focus: root.visible
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.dismiss();
                }
            }
            spacing: 0

            IconToolbarButton {
                id: keyButton
                onClicked: toggled = !toggled
                text: "key"

                StyledToolTip {
                    z: 9999
                    text: Translation.tr("API Keys")
                }
            }

            Revealer {
                reveal: keyButton.toggled
                Layout.fillHeight: true

                RowLayout {
                    anchors.left: parent.left
                    spacing: 6
                    Item {} // padding

                    ToolbarTextField {
                        id: googleKeyInput
                        implicitWidth: 260
                        placeholderText: Translation.tr("Google Vision API key")
                        inputMethodHints: Qt.ImhSensitiveData
                        text: KeyringStorage.keyringData?.apiKeys?.googleVision ?? ""
                        onAccepted: {
                            KeyringStorage.setNestedField(["apiKeys", "googleVision"], text.trim());
                            googleSaved.restart();
                        }
                    }
                    IconToolbarButton {
                        onClicked: {
                            KeyringStorage.setNestedField(["apiKeys", "googleVision"], googleKeyInput.text.trim());
                            googleSaved.restart();
                        }
                        text: googleSaved.running ? "check" : "save"
                        toggled: googleSaved.running

                        Timer { id: googleSaved; interval: 1500 }

                        StyledToolTip {
                            z: 9999
                            text: Translation.tr("Save Google Vision key")
                        }
                    }

                    Item { implicitWidth: 4 } // spacer

                    ToolbarTextField {
                        id: deeplKeyInput
                        implicitWidth: 260
                        placeholderText: Translation.tr("DeepL API key")
                        inputMethodHints: Qt.ImhSensitiveData
                        text: KeyringStorage.keyringData?.apiKeys?.deepl ?? ""
                        onAccepted: {
                            KeyringStorage.setNestedField(["apiKeys", "deepl"], text.trim());
                            deeplSaved.restart();
                        }
                    }
                    IconToolbarButton {
                        onClicked: {
                            KeyringStorage.setNestedField(["apiKeys", "deepl"], deeplKeyInput.text.trim());
                            deeplSaved.restart();
                        }
                        text: deeplSaved.running ? "check" : "save"
                        toggled: deeplSaved.running

                        Timer { id: deeplSaved; interval: 1500 }

                        StyledToolTip {
                            z: 9999
                            text: Translation.tr("Save DeepL key")
                        }
                    }
                }
            }
        }

        ToolbarPairedFab {
            iconText: "close"
            onClicked: root.dismiss()
            StyledToolTip {
                text: Translation.tr("Close")
            }
        }
    }
}
