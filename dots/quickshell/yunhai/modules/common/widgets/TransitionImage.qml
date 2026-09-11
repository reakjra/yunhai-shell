import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.common

Item {
    id: root

    property url source
    property size imageSourceSize
    property real zoom: 1
    property real parallaxX: 0.5
    property real parallaxY: 0.5
    property string style: "circle"
    property int transitionDuration: 850
    property real feather: 64
    property point origin: Qt.point(width / 2, height / 2)
    property HyprlandMonitor cursorMonitor: null

    readonly property var styleIndices: ({
        "none": 0,
        "fade": 0,
        "circle": 1,
        "wipe": 2,
        "dissolve": 3
    })
    readonly property int styleIndex: root.styleIndices[root.style] ?? 1
    readonly property int effectiveDuration: root.style === "none" ? 0 : root.transitionDuration

    readonly property bool hasSource: String(root.source).length > 0
    readonly property Layer frontLayer: root.frontIsA ? layerA : layerB
    readonly property Layer backLayer: root.frontIsA ? layerB : layerA
    readonly property bool loaded: root.frontLayer.status === Image.Ready

    property real smoothParallaxX: root.parallaxX
    property real smoothParallaxY: root.parallaxY
    Behavior on smoothParallaxX {
        NumberAnimation {
            duration: 600
            easing.type: Easing.OutCubic
        }
    }
    Behavior on smoothParallaxY {
        NumberAnimation {
            duration: 600
            easing.type: Easing.OutCubic
        }
    }

    readonly property real parallaxOffsetX: (root.frontLayer.imageWidth - root.width) * (0.5 - root.smoothParallaxX)
    readonly property real parallaxOffsetY: (root.frontLayer.imageHeight - root.height) * (0.5 - root.smoothParallaxY)

    property bool frontIsA: true
    property bool everLoaded: false
    property real progress: 0

    readonly property real maxRadius: {
        const dx = Math.max(root.origin.x, root.width - root.origin.x)
        const dy = Math.max(root.origin.y, root.height - root.origin.y)
        return Math.sqrt(dx * dx + dy * dy)
    }

    opacity: (root.everLoaded && root.hasSource) ? 1 : 0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
    }

    onSourceChanged: {
        if (!root.hasSource || root.frontLayer.source == root.source) return
        if (root.cursorMonitor) cursorProc.running = true
        if (root.backLayer.source == root.source) {
            if (root.backLayer.status === Image.Ready) root.present(root.backLayer)
            return
        }
        root.backLayer.budget = root.imageSourceSize
        root.backLayer.source = root.source
    }

    function present(layer) {
        if (layer !== root.backLayer || layer.source != root.source) return
        if (!root.everLoaded) {
            root.progress = 1
            root.frontIsA = (layer === layerA)
            root.everLoaded = true
            return
        }
        root.progress = 0
        root.frontIsA = (layer === layerA)
        revealAnim.restart()
    }

    NumberAnimation {
        id: revealAnim
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: root.effectiveDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: root.styleIndex === 0
            ? Appearance.animationCurves.expressiveEffects
            : Appearance.animationCurves.expressiveDefaultSpatial
    }

    Process {
        id: cursorProc
        command: ["hyprctl", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: {
                const pos = text.trim().split(",")
                if (pos.length !== 2 || revealAnim.running) return
                const local = root.mapFromItem(root.parent,
                    parseInt(pos[0]) - root.cursorMonitor.x,
                    parseInt(pos[1]) - root.cursorMonitor.y)
                root.origin = Qt.point(local.x, local.y)
            }
        }
    }

    component Layer: Item {
        id: layer
        anchors.fill: parent

        property alias source: image.source
        property size budget
        readonly property int status: image.status
        readonly property real imageWidth: image.width
        readonly property real imageHeight: image.height

        readonly property real coverScale: (image.implicitWidth > 0 && image.implicitHeight > 0)
            ? Math.max(layer.width / image.implicitWidth, layer.height / image.implicitHeight) * root.zoom
            : 1

        Image {
            id: image
            asynchronous: true
            retainWhileLoading: true
            cache: false
            smooth: true
            sourceSize: layer.budget

            width: implicitWidth * layer.coverScale
            height: implicitHeight * layer.coverScale
            x: -(width - layer.width) * root.smoothParallaxX
            y: -(height - layer.height) * root.smoothParallaxY

            onStatusChanged: if (status === Image.Ready) root.present(layer)
        }
    }

    Layer { id: layerA }
    Layer { id: layerB }

    ShaderEffectSource {
        id: textureA
        anchors.fill: parent
        sourceItem: layerA
        hideSource: true
        visible: false
    }

    ShaderEffectSource {
        id: textureB
        anchors.fill: parent
        sourceItem: layerB
        hideSource: true
        visible: false
    }

    ShaderEffect {
        anchors.fill: parent
        fragmentShader: Quickshell.shellPath("assets/shaders/common/imagetransition.frag.qsb")

        readonly property variant fromSource: root.frontIsA ? textureB : textureA
        readonly property variant toSource: root.frontIsA ? textureA : textureB
        readonly property vector2d size: Qt.vector2d(width, height)
        readonly property vector2d origin: Qt.vector2d(root.origin.x, root.origin.y)
        readonly property real progress: root.progress
        readonly property real feather: root.feather
        readonly property real maxRadius: root.maxRadius
        readonly property int style: root.styleIndex
    }
}
