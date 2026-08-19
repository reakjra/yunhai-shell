import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property alias source: img.source
    property real lobes: 9
    property real scallop: 0.06
    property real rot: 0
    property color fallbackColor: Appearance.colors.colLayer2
    property string fallbackIcon: "art_track"
    readonly property bool ready: img.status === Image.Ready

    Item {
        id: artBox
        anchors.fill: parent

        Image {
            id: img
            anchors.fill: parent
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: width
            sourceSize.height: height
        }
    }

    ShaderEffectSource {
        id: artTex
        sourceItem: artBox
        hideSource: true
        visible: false
    }

    ShaderEffect {
        anchors.fill: parent
        property vector2d size: Qt.vector2d(width, height)
        property real rot: root.rot
        property real lobes: root.lobes
        property real scallop: root.scallop
        property real hasArt: root.ready ? 1 : 0
        property color color: root.fallbackColor
        property var source: artTex
        fragmentShader: Quickshell.shellPath("assets/shaders/lunae/cookie.frag.qsb")
    }

    MaterialSymbol {
        anchors.centerIn: parent
        text: root.fallbackIcon
        iconSize: root.width * 0.35
        color: Appearance.m3colors.m3onSurfaceVariant
        visible: !root.ready
    }
}
