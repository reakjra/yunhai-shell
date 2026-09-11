import QtQuick
import Quickshell

ShaderEffect {
    property real lobes: 9
    property real scallop: 0.08
    property real rot: 0
    property color color: "white"
    property vector2d size: Qt.vector2d(width, height)

    fragmentShader: Quickshell.shellPath("assets/shaders/lunae/cookieflat.frag.qsb")
}
