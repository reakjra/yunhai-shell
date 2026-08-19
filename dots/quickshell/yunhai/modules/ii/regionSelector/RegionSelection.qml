pragma ComponentBehavior: Bound
import qs.modules.common
import qs.modules.common.utils
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Controls
import Qt.labs.synchronizer
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects

PanelWindow {
    id: root
    visible: false
    color: "transparent"
    WlrLayershell.namespace: "quickshell:regionSelector"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.phase === RegionSelection.Phase.Post ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    // Modes
    // TODO: Ask: sidebar AI
    enum SnipAction { Copy, Edit, Search, CharRecognition, Record, RecordWithSound, Translate }
    enum SelectionMode { RectCorners, Circle }
    enum Phase { Select, Post, Translate }
    property var action: RegionSelection.SnipAction.Copy
    property var selectionMode: RegionSelection.SelectionMode.RectCorners
    property var phase: RegionSelection.Phase.Select
    signal dismiss()

    // Styles
    property string screenshotDir: Directories.screenshotTemp
    property color overlayColor: ColorUtils.transparentize("#000000", 0.4)
    property color brightText: Appearance.m3colors.darkmode ? Appearance.colors.colOnLayer0 : Appearance.colors.colLayer0
    property color brightSecondary: Appearance.m3colors.darkmode ? Appearance.colors.colSecondary : Appearance.colors.colOnSecondary
    property color brightTertiary: Appearance.m3colors.darkmode ? Appearance.colors.colTertiary : Qt.lighter(Appearance.colors.colPrimary)
    property color selectionBorderColor: ColorUtils.mix(brightText, brightSecondary, 0.5)
    property color selectionFillColor: "#33ffffff"
    property color windowBorderColor: brightSecondary
    property color windowFillColor: ColorUtils.transparentize(windowBorderColor, 0.85)
    property color imageBorderColor: brightTertiary
    property color imageFillColor: ColorUtils.transparentize(imageBorderColor, 0.85)
    property color onBorderColor: "#ff000000"
    property real targetRegionOpacity: Config.options.regionSelector.targetRegions.opacity
    property bool contentRegionOpacity: Config.options.regionSelector.targetRegions.contentRegionOpacity

    // Vars for indicators
    readonly property var windows: [...HyprlandData.windowList].sort((a, b) => {
        // Sort floating=true windows before others
        if (a.floating === b.floating) return 0;
        return a.floating ? -1 : 1;
    })
    readonly property var layers: HyprlandData.layers
    readonly property real falsePositivePreventionRatio: 0.5

    // Screen & interaction vars
    readonly property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(screen)
    readonly property real monitorScale: hyprlandMonitor.scale
    readonly property real monitorOffsetX: hyprlandMonitor.x
    readonly property real monitorOffsetY: hyprlandMonitor.y
    property int activeWorkspaceId: hyprlandMonitor.activeWorkspace?.id ?? 0
    property string screenshotPath: `${root.screenshotDir}/image-${screen.name}`
    property real dragStartX: 0
    property real dragStartY: 0
    property real draggingX: 0
    property real draggingY: 0
    property real dragDiffX: 0
    property real dragDiffY: 0
    property bool draggedAway: (dragDiffX !== 0 || dragDiffY !== 0)
    property bool dragging: false
    property list<point> points: []
    property var mouseButton: null
    property var imageRegions: []
    readonly property list<var> windowRegions: RegionFunctions.filterWindowRegionsByLayers(
        root.windows.filter(w => w.workspace.id === root.activeWorkspaceId),
        root.layerRegions
    ).map(window => {
        return {
            at: [window.at[0] - root.monitorOffsetX, window.at[1] - root.monitorOffsetY],
            size: [window.size[0], window.size[1]],
            class: window.class,
            title: window.title,
        }
    })
    readonly property list<var> layerRegions: {
        const layersOfThisMonitor = root.layers[root.hyprlandMonitor.name]
        const topLayers = layersOfThisMonitor?.levels["2"]
        if (!topLayers) return [];
        const nonBarTopLayers = topLayers
            .filter(layer => !(layer.namespace.includes(":bar") || layer.namespace.includes(":verticalBar") || layer.namespace.includes(":dock")))
            .map(layer => {
            return {
                at: [layer.x, layer.y],
                size: [layer.w, layer.h],
                namespace: layer.namespace,
            }
        })
        const offsetAdjustedLayers = nonBarTopLayers.map(layer => {
            return {
                at: [layer.at[0] - root.monitorOffsetX, layer.at[1] - root.monitorOffsetY],
                size: layer.size,
                namespace: layer.namespace,
            }
        });
        return offsetAdjustedLayers;
    }

    // Config
    property bool isCircleSelection: (root.selectionMode === RegionSelection.SelectionMode.Circle)
    property bool enableWindowRegions: Config.options.regionSelector.targetRegions.windows && !isCircleSelection
    property bool enableLayerRegions: Config.options.regionSelector.targetRegions.layers && !isCircleSelection
    property bool enableContentRegions: Config.options.regionSelector.targetRegions.content

    // Target
    property real targetedRegionX: -1
    property real targetedRegionY: -1
    property real targetedRegionWidth: 0
    property real targetedRegionHeight: 0
    function targetedRegionValid() {
        return (root.targetedRegionX >= 0 && root.targetedRegionY >= 0)
    }
    function setRegionToTargeted() {
        const padding = Config.options.regionSelector.targetRegions.selectionPadding; // Make borders not cut off n stuff
        root.regionX = root.targetedRegionX - padding;
        root.regionY = root.targetedRegionY - padding;
        root.regionWidth = root.targetedRegionWidth + padding * 2;
        root.regionHeight = root.targetedRegionHeight + padding * 2;
    }

    function updateTargetedRegion(x, y) {
        // Image regions
        const clickedRegion = root.imageRegions.find(region => {
            return region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
        });
        if (clickedRegion) {
            root.targetedRegionX = clickedRegion.at[0];
            root.targetedRegionY = clickedRegion.at[1];
            root.targetedRegionWidth = clickedRegion.size[0];
            root.targetedRegionHeight = clickedRegion.size[1];
            return;
        }

        // Layer regions
        const clickedLayer = root.layerRegions.find(region => {
            return region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
        });
        if (clickedLayer) {
            root.targetedRegionX = clickedLayer.at[0];
            root.targetedRegionY = clickedLayer.at[1];
            root.targetedRegionWidth = clickedLayer.size[0];
            root.targetedRegionHeight = clickedLayer.size[1];
            return;
        }

        // Window regions
        const clickedWindow = root.windowRegions.find(region => {
            return region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
        });
        if (clickedWindow) {
            root.targetedRegionX = clickedWindow.at[0];
            root.targetedRegionY = clickedWindow.at[1];
            root.targetedRegionWidth = clickedWindow.size[0];
            root.targetedRegionHeight = clickedWindow.size[1];
            return;
        }

        root.targetedRegionX = -1;
        root.targetedRegionY = -1;
        root.targetedRegionWidth = 0;
        root.targetedRegionHeight = 0;
    }

    property real regionWidth: Math.abs(draggingX - dragStartX)
    property real regionHeight: Math.abs(draggingY - dragStartY)
    property real regionX: Math.min(dragStartX, draggingX)
    property real regionY: Math.min(dragStartY, draggingY)

    // Screenshot stuff
    TempScreenshotProcess {
        id: screenshotProc
        running: true
        screen: root.screen
        screenshotDir: root.screenshotDir
        screenshotPath: root.screenshotPath
        onExited: (exitCode, exitStatus) => {
            if (root.enableContentRegions) imageDetectionProcess.running = true;
            root.preparationDone = !checkRecordingProc.running;
        }
    }
    property bool isRecording: root.action === RegionSelection.SnipAction.Record || root.action === RegionSelection.SnipAction.RecordWithSound
    property bool recordingShouldStop: false
    Process {
        id: checkRecordingProc
        running: isRecording
        command: ["pidof", "wf-recorder"]
        onExited: (exitCode, exitStatus) => {
            root.preparationDone = !screenshotProc.running
            root.recordingShouldStop = (exitCode === 0);
        }
    }
    property bool preparationDone: false
    onPreparationDoneChanged: {
        if (!preparationDone) return;
        if (root.isRecording && root.recordingShouldStop) {
            Quickshell.execDetached([Directories.recordScriptPath]);
            root.dismiss();
            return;
        }
        root.visible = true;
    }

    Process {
        id: imageDetectionProcess
        command: ["bash", "-c", `${Directories.scriptPath}/images/find-regions-venv.sh ` 
            + `--hyprctl ` 
            + `--image '${StringUtils.shellSingleQuoteEscape(root.screenshotPath)}' ` 
            + `--max-width ${Math.round(root.screen.width * root.falsePositivePreventionRatio)} ` 
            + `--max-height ${Math.round(root.screen.height * root.falsePositivePreventionRatio)} `]
        stdout: StdioCollector {
            id: imageDimensionCollector
            onStreamFinished: {
                imageRegions = RegionFunctions.filterImageRegions(
                    JSON.parse(imageDimensionCollector.text),
                    root.windowRegions
                );
            }
        }
    }

    // Translation
    property var translateParagraphs: []
    property var translateTranslation: ({})
    property var translateColors: []
    property bool translateBusy: false
    readonly property string batchColorScriptPath: Quickshell.shellPath("scripts/images/batch-text-colors-venv.sh")

    function translateText(s) {
        return root.translateTranslation[s] ?? s;
    }

    function startTranslation() {
        if (!KeyringStorage.loaded) KeyringStorage.fetchKeyringData()

        const rx = Math.round(root.regionX * root.monitorScale)
        const ry = Math.round(root.regionY * root.monitorScale)
        const rw = Math.round(root.regionWidth * root.monitorScale)
        const rh = Math.round(root.regionHeight * root.monitorScale)
        const escapedPath = StringUtils.shellSingleQuoteEscape(root.screenshotPath)
        const cropCmd = `magick '${escapedPath}' -crop ${rw}x${rh}+${rx}+${ry} +repage '${escapedPath}'`

        const cfg = Config.options?.screenSnip?.translator
        const targetLang = cfg?.targetLanguage ?? "auto"
        const sourceLang = cfg?.ocrLanguage ?? "auto"
        const ocrBackend = cfg?.ocrBackend ?? "google"
        const translationEngine = cfg?.translationEngine ?? "trans"

        if (translationEngine === "deepl") {
            const deeplKey = KeyringStorage.keyringData?.apiKeys?.deepl ?? ""
            if (!deeplKey) {
                console.warn("[RegionTranslate] No DeepL API key in keyring")
                root.dismiss()
                return
            }
        }

        const googleVisionKey = KeyringStorage.keyringData?.apiKeys?.googleVision ?? ""
        if (ocrBackend === "google" && !googleVisionKey) {
            console.warn("[RegionTranslate] No Google Vision API key in keyring")
            root.dismiss()
            return
        }

        root.translateParagraphs = []
        root.translateTranslation = ({})
        root.translateColors = []
        root.translateBusy = true
        root.phase = RegionSelection.Phase.Translate

        const translationKey = translationEngine === "deepl"
            ? (KeyringStorage.keyringData?.apiKeys?.deepl ?? "unused")
            : "unused"

        let cmd = `${cropCmd} && python3 '${Directories.screenTranslateScriptPath}' `
            + `'${escapedPath}' '${StringUtils.shellSingleQuoteEscape(translationKey)}' `
            + `'${StringUtils.shellSingleQuoteEscape(targetLang)}'`

        if (sourceLang && sourceLang !== "auto")
            cmd += ` '${StringUtils.shellSingleQuoteEscape(sourceLang)}'`

        cmd += ` --rich`
        cmd += ` --translation-engine ${translationEngine}`

        if (!(cfg?.usePreprocessing ?? true))
            cmd += ` --no-preprocess`

        cmd += ` --ocr ${ocrBackend}`
        if (ocrBackend === "google")
            cmd += ` --google-key '${StringUtils.shellSingleQuoteEscape(googleVisionKey)}'`

        cmd += " 2>/dev/null"

        translateProc.command = ["bash", "-c", cmd]
        translateProc.running = true
    }

    function runTranslateColorDetection() {
        if (root.translateParagraphs.length === 0) return;
        const regions = root.translateParagraphs.map(p => {
            const v = p.boundingBox.vertices;
            return { x: v[0].x, y: v[0].y, w: v[1].x - v[0].x, h: v[3].y - v[0].y };
        });
        const payload = JSON.stringify({ image: root.screenshotPath, regions: regions });
        translateColorProc.command = [
            "bash", "-c",
            `echo ${StringUtils.shellSingleQuoteEscape(payload)} | ${root.batchColorScriptPath}`
        ];
        translateColorProc.running = true;
    }

    Process {
        id: translateProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const result = JSON.parse(text)
                    if (result.error) {
                        console.warn("[RegionTranslate]", result.error)
                        root.translateBusy = false
                        return
                    }
                    root.translateParagraphs = result.paragraphs ?? []
                    root.translateTranslation = result.translations ?? {}
                    Qt.callLater(() => {
                        root.translateBusy = false
                        root.runTranslateColorDetection()
                    })
                } catch (e) {
                    console.warn("[RegionTranslate] bad JSON:", e, text)
                    root.translateBusy = false
                }
            }
        }
    }

    Process {
        id: translateColorProc
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.translateColors = JSON.parse(text) }
                catch (e) { /* fallback to theme colors */ }
            }
        }
    }

    function getScreenshotAction() {
        switch(root.action) {
            case RegionSelection.SnipAction.Copy:
                return ScreenshotAction.Action.Copy;
            case RegionSelection.SnipAction.Edit:
                return ScreenshotAction.Action.Edit;
            case RegionSelection.SnipAction.Search:
                return ScreenshotAction.Action.Search;
            case RegionSelection.SnipAction.CharRecognition:
                return ScreenshotAction.Action.CharRecognition;
            case RegionSelection.SnipAction.Record:
                return ScreenshotAction.Action.Record;
            case RegionSelection.SnipAction.RecordWithSound:
                return ScreenshotAction.Action.RecordWithSound;
            case RegionSelection.SnipAction.Translate:
                return ScreenshotAction.Action.Copy;
            default:
                console.warn("[Region Selector] Unknown snip action, skipping snip.");
                root.dismiss();
                return;
        }
    }

    // Execution after selection
    function snip() {
        // Validity check
        if (root.regionWidth <= 0 || root.regionHeight <= 0) {
            console.warn("[Region Selector] Invalid region size, skipping snip.");
            root.dismiss();
        }

        // Clamp region to screen bounds
        root.regionX = Math.max(0, Math.min(root.regionX, root.screen.width - root.regionWidth));
        root.regionY = Math.max(0, Math.min(root.regionY, root.screen.height - root.regionHeight));
        root.regionWidth = Math.max(0, Math.min(root.regionWidth, root.screen.width - root.regionX));
        root.regionHeight = Math.max(0, Math.min(root.regionHeight, root.screen.height - root.regionY));

        // Translate action: switch to translate phase
        if (root.action === RegionSelection.SnipAction.Translate) {
            root.startTranslation();
            return;
        }

        // Adjust action
        if (root.action === RegionSelection.SnipAction.Copy || root.action === RegionSelection.SnipAction.Edit) {
            root.action = root.mouseButton === Qt.RightButton ? RegionSelection.SnipAction.Edit : RegionSelection.SnipAction.Copy;
        }
        
        const screenshotDir = Config.options.screenSnip.savePath !== "" ? //
            Config.options.screenSnip.savePath : "";
        var screenshotAction = root.getScreenshotAction();
        const command = ScreenshotAction.getCommand(
            root.regionX, //
            root.regionY, //
            root.regionWidth, //
            root.regionHeight, //
            root.screenshotPath, //
            screenshotAction, //
            screenshotDir, //
            root.monitorScale, //
            root.monitorOffsetX, //
            root.monitorOffsetY
        )
        Quickshell.execDetached(command);
        if ((root.action == RegionSelection.SnipAction.Record || root.action == RegionSelection.SnipAction.RecordWithSound)
            && Config.options.screenRecord.showBreathingBorder) {
            root.phase = RegionSelection.Phase.Post
            root.selectionMode = RegionSelection.SelectionMode.RectCorners
        } else {
            root.dismiss();
        }
    }

    // Only clickable in Selection phase
    mask: Region {
        item: switch(root.phase) {
            case RegionSelection.Phase.Select: return mouseArea;
            case RegionSelection.Phase.Translate: return mouseArea;
            case RegionSelection.Phase.Post: return maskEmpty;
        }
    }

    Item {
        id: maskEmpty
        width: 0
        height: 0
    }

    ScreencopyView { // For freezing
        anchors.fill: parent
        live: false
        captureSource: root.screen
        visible: root.phase === RegionSelection.Phase.Select || root.phase === RegionSelection.Phase.Translate

        focus: true
        Keys.onPressed: (event) => { // Esc to close
            if (event.key === Qt.Key_Escape) {
                root.dismiss();
            }
        }
    }

    CursorTracker {
        id: cursor
        monitor: root.hyprlandMonitor
        active: root.visible
        onCursorYChanged: if (!cursor.moved) root.updateTargetedRegion(cursor.cursorX, cursor.cursorY)
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.phase !== RegionSelection.Phase.Post
        cursorShape: Qt.CrossCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true

        // Controls
        onPressed: (mouse) => {
            if (root.phase === RegionSelection.Phase.Translate) return;
            const px = cursor.localX(mouse.x);
            const py = cursor.localY(mouse.y);
            root.dragStartX = px;
            root.dragStartY = py;
            root.draggingX = px;
            root.draggingY = py;
            root.dragging = true;
            root.mouseButton = mouse.button;
        }
        onReleased: (mouse) => {
            if (root.phase === RegionSelection.Phase.Translate) return;
            // Detect if it was a click -> Try to select targeted region
            if (root.draggingX === root.dragStartX && root.draggingY === root.dragStartY) {
                if (root.targetedRegionValid()) {
                    root.setRegionToTargeted();
                }
            }
            // Circle dragging?
            else if (root.selectionMode === RegionSelection.SelectionMode.Circle) {
                const padding = Config.options.regionSelector.circle.padding + Config.options.regionSelector.circle.strokeWidth / 2;
                const dragPoints = (root.points.length > 0) ? root.points : [{ x: cursor.cursorX, y: cursor.cursorY }];
                const maxX = Math.max(...dragPoints.map(p => p.x));
                const minX = Math.min(...dragPoints.map(p => p.x));
                const maxY = Math.max(...dragPoints.map(p => p.y));
                const minY = Math.min(...dragPoints.map(p => p.y));
                root.regionX = minX - padding;
                root.regionY = minY - padding;
                root.regionWidth = maxX - minX + padding * 2;
                root.regionHeight = maxY - minY + padding * 2;
            }
            root.snip();
        }
        onPositionChanged: (mouse) => {
            if (root.phase === RegionSelection.Phase.Translate) return;
            if (!cursor.track(mouse.x, mouse.y)) return;
            root.updateTargetedRegion(mouse.x, mouse.y);
            if (!root.dragging) return;
            root.draggingX = mouse.x;
            root.draggingY = mouse.y;
            root.dragDiffX = mouse.x - root.dragStartX;
            root.dragDiffY = mouse.y - root.dragStartY;
            root.points.push({ x: mouse.x, y: mouse.y });
        }
        
        Loader {
            z: 2
            anchors.fill: parent
            active: root.selectionMode === RegionSelection.SelectionMode.RectCorners && root.phase !== RegionSelection.Phase.Translate
            sourceComponent: RectCornersSelectionDetails {
                regionX: root.regionX
                regionY: root.regionY
                regionWidth: root.regionWidth
                regionHeight: root.regionHeight
                mouseX: cursor.cursorX
                mouseY: cursor.cursorY
                color: root.selectionBorderColor
                overlayColor: root.overlayColor
                breathingBorderOnly: root.phase === RegionSelection.Phase.Post
            }
        }

        Loader {
            z: 2
            anchors.fill: parent
            active: root.selectionMode === RegionSelection.SelectionMode.Circle && root.phase !== RegionSelection.Phase.Translate
            sourceComponent: CircleSelectionDetails {
                color: root.selectionBorderColor
                overlayColor: root.overlayColor
                points: root.points
            }
        }

        // The thing to the bottom-right with an icon
        CursorGuide {
            z: 9999
            visible: root.phase === RegionSelection.Phase.Select
            x: root.dragging ? root.regionX + root.regionWidth : cursor.cursorX
            y: root.dragging ? root.regionY + root.regionHeight : cursor.cursorY
            action: root.action
            selectionMode: root.selectionMode
        }

        // Window regions
        Repeater {
            model: ScriptModel {
                values: {
                    if (root.phase === RegionSelection.Phase.Select && root.enableWindowRegions) {
                        return root.windowRegions
                    } else {
                        return []
                    }
                }
            }
            delegate: TargetRegion {
                z: 2
                required property var modelData
                clientDimensions: modelData
                showIcon: true
                targeted: !root.draggedAway && //
                    (root.targetedRegionX === modelData.at[0]  //
                    && root.targetedRegionY === modelData.at[1] //
                    && root.targetedRegionWidth === modelData.size[0] //
                    && root.targetedRegionHeight === modelData.size[1])

                opacity: root.draggedAway ? 0 : root.targetRegionOpacity
                borderColor: root.windowBorderColor
                fillColor: targeted ? root.windowFillColor : "transparent"
                text: `${modelData.class}`
                radius: Appearance.rounding.windowRounding
            }
        }

        // Layer regions
        Repeater {
            model: ScriptModel {
                values: {
                    if (root.phase === RegionSelection.Phase.Select && root.enableLayerRegions) {
                        return root.layerRegions
                    } else {
                        return []
                    }
                }
            }
            delegate: TargetRegion {
                z: 3
                required property var modelData
                clientDimensions: modelData
                targeted: !root.draggedAway &&
                    (root.targetedRegionX === modelData.at[0] 
                    && root.targetedRegionY === modelData.at[1]
                    && root.targetedRegionWidth === modelData.size[0]
                    && root.targetedRegionHeight === modelData.size[1])

                opacity: root.draggedAway ? 0 : root.targetRegionOpacity
                borderColor: root.windowBorderColor
                fillColor: targeted ? root.windowFillColor : "transparent"
                text: `${modelData.namespace}`
                radius: Appearance.rounding.windowRounding
            }
        }

        // Content regions
        Repeater {
            model: ScriptModel {
                values: {
                    if (root.phase === RegionSelection.Phase.Select && root.enableContentRegions) {
                        return root.imageRegions
                    } else {
                        return []
                    }
                }
            }
            delegate: TargetRegion {
                z: 4
                required property var modelData
                clientDimensions: modelData
                targeted: !root.draggedAway &&
                    (root.targetedRegionX === modelData.at[0] 
                    && root.targetedRegionY === modelData.at[1]
                    && root.targetedRegionWidth === modelData.size[0]
                    && root.targetedRegionHeight === modelData.size[1])

                opacity: root.draggedAway ? 0 : root.contentRegionOpacity
                borderColor: root.imageBorderColor
                fillColor: targeted ? root.imageFillColor : "transparent"
                text: Translation.tr("Content region")
            }
        }

        // Translation overlay
        Item {
            id: translateOverlay
            anchors.fill: parent
            z: 5
            visible: root.phase === RegionSelection.Phase.Translate

            // dim everything outside the selection
            Item {
                id: translateMaskSource
                anchors.fill: parent
                visible: false
                Rectangle {
                    x: root.regionX
                    y: root.regionY
                    width: root.regionWidth
                    height: root.regionHeight
                    color: "black"
                }
            }

            Rectangle {
                id: translateDim
                anchors.fill: parent
                color: ColorUtils.transparentize(Appearance.colors.colShadow, 0.3)
                visible: false
            }

            OpacityMask {
                anchors.fill: parent
                source: translateDim
                maskSource: translateMaskSource
                invert: true
            }

            Rectangle {
                x: root.regionX - 2
                y: root.regionY - 2
                width: root.regionWidth + 4
                height: root.regionHeight + 4
                color: "transparent"
                border.width: 2
                border.color: Appearance.colors.colPrimary
                radius: Appearance.rounding.small
            }

            // loading indicator
            Column {
                visible: root.translateBusy
                x: root.regionX + (root.regionWidth - width) / 2
                y: root.regionY + (root.regionHeight - height) / 2
                spacing: 12

                MaterialLoadingIndicator {
                    id: translateLoadingSpinner
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitSize: Math.max(32, Math.min(64, Math.min(root.regionWidth, root.regionHeight) * 0.15))
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Translation.tr("Translating...")
                    color: Appearance.colors.colOnLayer0
                    font.pixelSize: Math.max(14, translateLoadingSpinner.implicitSize * 0.4)
                }
            }

            // translation overlay with blur + adaptive text
            Item {
                x: root.regionX
                y: root.regionY
                width: root.regionWidth
                height: root.regionHeight
                clip: true

                Image {
                    id: translateCropImage
                    visible: false
                    width: parent.width
                    height: parent.height
                    source: root.translateParagraphs.length > 0 ? Qt.resolvedUrl(root.screenshotPath) : ""
                    sourceSize: Qt.size(parent.width * root.monitorScale, parent.height * root.monitorScale)
                    asynchronous: true
                    cache: false
                }

                Item {
                    id: translateBlurMask
                    width: parent.width
                    height: parent.height
                    layer.enabled: true
                    visible: false
                    Repeater {
                        model: root.translateBusy ? [] : root.translateParagraphs
                        delegate: Rectangle {
                            required property var modelData
                            property list<var> verts: modelData.boundingBox.vertices
                            readonly property string paraText: modelData.text
                            readonly property string translated: root.translateText(paraText)
                            visible: translated !== paraText
                            x: verts[0].x / root.monitorScale
                            y: verts[0].y / root.monitorScale
                            width: (verts[1].x - verts[0].x) / root.monitorScale
                            height: (verts[3].y - verts[0].y) / root.monitorScale
                            radius: 4

                            // rotate around top-left so vertical/tilted text doesnt get stretched
                            property real dx: verts[1].x - verts[0].x
                            property real dy: verts[1].y - verts[0].y
                            transformOrigin: Item.TopLeft
                            rotation: Math.atan2(dy, dx) * 180 / Math.PI
                        }
                    }
                }

                MaskMultiEffect {
                    width: parent.width
                    height: parent.height
                    source: translateCropImage
                    maskSource: translateBlurMask
                    blurEnabled: true
                    blur: 1
                    blurMax: 50
                    autoPaddingEnabled: false
                }

                Repeater {
                    model: root.translateBusy ? [] : root.translateParagraphs
                    delegate: Rectangle {
                        id: transBlock
                        required property var modelData
                        required property int index
                        property list<var> verts: modelData.boundingBox.vertices
                        readonly property string paraText: modelData.text
                        readonly property string translated: root.translateText(paraText)
                        visible: translated !== paraText

                        x: verts[0].x / root.monitorScale
                        y: verts[0].y / root.monitorScale
                        width: (verts[1].x - verts[0].x) / root.monitorScale
                        height: (verts[3].y - verts[0].y) / root.monitorScale
                        radius: 4

                        // rotate around top-left so vertical/tilted text doesnt get stretched
                        property real dx: verts[1].x - verts[0].x
                        property real dy: verts[1].y - verts[0].y
                        transformOrigin: Item.TopLeft
                        rotation: Math.atan2(dy, dx) * 180 / Math.PI

                        readonly property var colorData: root.translateColors[index] ?? null
                        readonly property real boxTransparency: 1 - (Config.options?.screenSnip?.translator?.textBoxOpacity ?? 0.85)

                        color: colorData?.background
                            ? ColorUtils.transparentize(colorData.background, boxTransparency)
                            : ColorUtils.transparentize(Appearance.colors.colSecondaryContainer, boxTransparency)
                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }

                        SqueezedAnnotationStyledText {
                            width: parent.width
                            height: parent.height
                            text: transBlock.translated
                            scaleFactor: 1
                            color: transBlock.colorData?.text ?? Appearance.colors.colOnSecondaryContainer

                            Behavior on color {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                z: -1
                onClicked: root.dismiss()
            }
        }

        // Controls
        Row {
            id: regionSelectionControls
            z: 10
            visible: root.phase === RegionSelection.Phase.Select
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: -height
            }
            opacity: 0
            Connections {
                target: root
                function onVisibleChanged() {
                    if (!visible) return;
                    regionSelectionControls.anchors.bottomMargin = 8;
                    regionSelectionControls.opacity = 1;
                }
            }
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Behavior on anchors.bottomMargin {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }
            spacing: 6

            OptionsToolbar {
                Synchronizer on action {
                    property alias source: root.action
                }
                Synchronizer on selectionMode {
                    property alias source: root.selectionMode
                }
                onDismiss: root.dismiss();
            }
            ToolbarPairedFab {
                anchors.verticalCenter: parent.verticalCenter
                iconText: "close"
                onClicked: root.dismiss();
                StyledToolTip {
                    text: Translation.tr("Close")
                }
            }
        }
        
    }
}
