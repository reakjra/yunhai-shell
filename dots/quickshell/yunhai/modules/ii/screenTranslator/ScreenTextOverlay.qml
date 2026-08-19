pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io

import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.utils
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    property double scaleFactor: 1
    property color overlayColor: "#BB000000"
    property color textColor: "white"
    required property string screenshotPath

    readonly property string batchColorScriptPath: Quickshell.shellPath("scripts/images/batch-text-colors-venv.sh")

    property bool loading: true
    property var visionParagraphs: []
    property var translation: ({})
    property var paragraphColors: [] // parallel array: [{background, text}, ...]

    function translate(s: string): string {
        return translation[s] ?? s;
    }

    property bool error: false
    property string errorMessage: ""

    Component.onCompleted: {
        runTranslation();
    }

    function runTranslation() {
        const cfg = Config.options?.screenSnip?.translator;
        const ocrBackend = cfg?.ocrBackend ?? "google";
        const translationEngine = cfg?.translationEngine ?? "trans";
        const targetLang = cfg?.targetLanguage ?? "auto";
        const ocrLang = cfg?.ocrLanguage ?? "auto";
        const usePreprocessing = cfg?.usePreprocessing ?? true;

        var cmd = ["python3", Directories.screenTranslateScriptPath, root.screenshotPath];

        if (translationEngine === "deepl") {
            const deeplKey = KeyringStorage.keyringData?.apiKeys?.deepl ?? "";
            if (!deeplKey) {
                root.errorMessage = Translation.tr("DeepL API key not set in keyring");
                root.error = true;
                root.loading = false;
                return;
            }
            cmd.push(deeplKey);
        } else {
            cmd.push("unused");
        }

        cmd.push(targetLang);

        if (ocrLang && ocrLang !== "auto")
            cmd.push(ocrLang);

        cmd.push("--rich");
        cmd.push("--ocr", ocrBackend);
        cmd.push("--translation-engine", translationEngine);

        if (!usePreprocessing)
            cmd.push("--no-preprocess");

        if (ocrBackend === "google") {
            const googleKey = KeyringStorage.keyringData?.apiKeys?.googleVision ?? "";
            if (!googleKey) {
                root.errorMessage = Translation.tr("Google Vision API key not set in keyring");
                root.error = true;
                root.loading = false;
                return;
            }
            cmd.push("--google-key", googleKey);
        }

        translateProcess.command = cmd;
        translateProcess.running = true;
    }

    // batch color detection after translation
    function runColorDetection() {
        if (root.visionParagraphs.length === 0) return;

        const regions = root.visionParagraphs.map(p => {
            const v = p.boundingBox.vertices;
            return {
                x: v[0].x, y: v[0].y,
                w: v[1].x - v[0].x, h: v[3].y - v[0].y,
            };
        });
        const payload = JSON.stringify({ image: root.screenshotPath, regions: regions });
        // pipe json via echo to avoid needing Process stdin API
        colorProcess.command = [
            "bash", "-c",
            `echo ${StringUtils.shellSingleQuoteEscape(payload)} | ${root.batchColorScriptPath}`
        ];
        colorProcess.running = true;
    }

    Process {
        id: translateProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text);
                    if (result.error) {
                        root.errorMessage = result.error;
                        root.error = true;
                        root.loading = false;
                        return;
                    }
                    root.visionParagraphs = result.paragraphs ?? [];
                    root.translation = result.translations ?? {};
                    root.loading = false;
                    // kick off batch color detection
                    root.runColorDetection();
                } catch (e) {
                    root.errorMessage = `Failed to parse: ${e}`;
                    root.error = true;
                    root.loading = false;
                }
            }
        }
    }

    Process {
        id: colorProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.paragraphColors = JSON.parse(text);
                } catch (e) {
                    // color detection failed, use theme fallback colors. nbd
                }
            }
        }
    }

    Rectangle {
        id: loadingOverlay
        anchors.fill: parent
        opacity: root.loading ? 1 : 0
        Behavior on opacity {
            animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
        }
        color: root.overlayColor

        Column {
            visible: !root.error
            anchors.centerIn: parent
            spacing: 10 * root.scaleFactor
            MaterialLoadingIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                implicitSize: 100 * root.scaleFactor
                scale: 1 + ((1 - loadingOverlay.opacity) * 0.5) * root.scaleFactor
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Translation.tr("Translating screen...")
                font.pixelSize: Appearance.font.pixelSize.small * root.scaleFactor
                animateChange: true
                color: root.textColor
            }
        }

        Column {
            visible: root.error
            anchors.centerIn: parent
            spacing: 10 * root.scaleFactor

            MaterialShapeWrappedMaterialSymbol {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "exclamation"
                iconSize: 80 * root.scaleFactor
                padding: 6 * root.scaleFactor
                color: Appearance.colors.colError
                colSymbol: Appearance.colors.colOnError
                shape: MaterialShape.Shape.Sunny
            }
            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                text: `**${Translation.tr("Screen Translator")}**\n\n${root.errorMessage}`
                textFormat: Text.MarkdownText
                font.pixelSize: Appearance.font.pixelSize.small * root.scaleFactor
                color: root.textColor
            }
        }
    }

    property real windowWidth: QsWindow.window.screen.width
    property real windowHeight: QsWindow.window.screen.height

    StyledImage {
        id: screenshotImage
        z: 1
        asynchronous: false
        width: root.windowWidth
        height: root.windowHeight
        sourceSize: Qt.size(root.windowWidth, root.windowHeight)
        source: Qt.resolvedUrl(root.screenshotPath)
        visible: false
    }

    Item {
        id: blurMaskItem
        z: 2
        width: root.windowWidth
        height: root.windowHeight
        layer.enabled: true
        visible: false
        Repeater {
            model: root.loading ? [] : root.visionParagraphs
            delegate: VisionBoundingBoxRect {
                required property int index
                readonly property string text: modelData.text
                readonly property string translatedText: root.translate(text)
                visible: translatedText != text
                scaleFactor: 1
            }
        }
    }

    MaskMultiEffect {
        z: 4
        implicitWidth: parent.width
        implicitHeight: parent.height
        width: parent.width
        height: parent.height

        source: screenshotImage
        maskSource: blurMaskItem

        blurEnabled: true
        blur: 1
        blurMax: 50
        blurMultiplier: root.scaleFactor
        autoPaddingEnabled: false
    }

    Item {
        id: textItems
        z: 999
        Repeater {
            model: root.loading ? [] : root.visionParagraphs
            delegate: TextItem {}
        }
    }

    component VisionBoundingBoxRect: Rectangle {
        required property var modelData
        property real scaleFactor: root.scaleFactor
        property list<var> boundingVertices: modelData.boundingBox.vertices
        property real unscaledX: boundingVertices[0].x
        property real unscaledY: boundingVertices[0].y
        property real unscaledWidth: boundingVertices[1].x - boundingVertices[0].x
        property real unscaledHeight: boundingVertices[3].y - boundingVertices[0].y

        // rotate around top-left so vertical/tilted text doesnt get stretched
        property real dx: boundingVertices[1].x - boundingVertices[0].x
        property real dy: boundingVertices[1].y - boundingVertices[0].y
        transformOrigin: Item.TopLeft
        rotation: Math.atan2(dy, dx) * 180 / Math.PI

        x: unscaledX * scaleFactor
        y: unscaledY * scaleFactor
        width: unscaledWidth * scaleFactor
        height: unscaledHeight * scaleFactor
        radius: 4
    }

    component TextItem: VisionBoundingBoxRect {
        id: ti
        required property int index
        readonly property string text: modelData.text
        readonly property string translatedText: root.translate(text)
        visible: translatedText != text

        readonly property var colorData: root.paragraphColors[index] ?? null
        readonly property real boxTransparency: 1 - (Config.options?.screenSnip?.translator?.textBoxOpacity ?? 0.85)

        color: colorData?.background
            ? ColorUtils.transparentize(colorData.background, boxTransparency)
            : ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, boxTransparency)
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        SqueezedAnnotationStyledText {
            id: tiText
            width: parent.width
            height: parent.height
            text: ti.translatedText
            scaleFactor: root.scaleFactor
            color: ti.colorData?.text ?? Appearance.colors.colOnSecondaryContainer

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }
}
