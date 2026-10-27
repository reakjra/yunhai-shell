import QtQuick
import qs.modules.common

Squircle {
    id: root

    property bool shown: false
    property real hiddenScale: 0.92
    property bool revealed: false
    readonly property bool open: revealed && shown

    opacity: open ? 1 : 0
    scale: open ? 1 : hiddenScale
    layer.enabled: opacity < 1
    layer.smooth: true

    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    MotionBehavior on scale {
        motion: Motion.spatialFast
        exitMotion: Motion.exitFast
        exitTarget: root.hiddenScale
    }

    Component.onCompleted: revealed = true
}
