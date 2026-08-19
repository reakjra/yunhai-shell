import QtQuick
import Quickshell
import qs.modules.common

ShaderEffect {
    id: root

    property real value: 0
    property real sweepDeg: 180
    property real thickness: 6
    property real waveAmpTarget: 3
    property real waveFreq: 8
    property bool playing: false

    property color fgColor: Appearance.colors.colPrimary
    property color trackColor: Appearance.colors.colLayer2

    property vector2d size: Qt.vector2d(width, height)
    property real radius: Math.min(width, height) / 2 - thickness / 2 - waveAmpTarget
    property real sweep: sweepDeg * Math.PI / 180
    property real progress: Math.max(0, Math.min(1, value))
    property real waveAmp: playing ? waveAmpTarget : 0
    property real phase: 0

    Behavior on waveAmp {
        NumberAnimation {
            duration: 400
            easing.type: Easing.OutCubic
        }
    }

    NumberAnimation on phase {
        running: root.playing && root.visible
        loops: Animation.Infinite
        from: 0
        to: 2 * Math.PI
        duration: 2000
    }

    fragmentShader: Quickshell.shellPath("assets/shaders/lunae/wavyarc.frag.qsb")
}
