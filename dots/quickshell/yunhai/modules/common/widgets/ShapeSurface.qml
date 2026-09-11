pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common

Item {
    id: root

    property var shape: ({})
    property color color: Appearance.colors.colPrimaryContainer
    property real themeRadius: Appearance.rounding.normal
    property real baseSize: 0
    property bool applySkew: true
    default property alias content: contentHost.data

    readonly property real sizeScale: root.shape.scale ?? 1
    implicitWidth: root.baseSize * root.sizeScale
    implicitHeight: root.baseSize * root.sizeScale

    readonly property real shapeRadius: Math.min(root.shape.radius ?? root.themeRadius, Math.min(root.width, root.height) / 2)
    readonly property real shapeSmoothing: root.shape.smoothing ?? Config.options.squircle.smoothing
    readonly property real shapeSkew: root.applySkew ? (root.shape.skew ?? 0) : 0
    readonly property bool scalloped: (root.shape.lobes ?? 0) > 0

    component SkewMatrix: Matrix4x4 {
        matrix: Qt.matrix4x4(1, root.shapeSkew, 0, -root.shapeSkew * root.height / 2,
                             0, 1, 0, 0,
                             0, 0, 1, 0,
                             0, 0, 0, 1)
    }

    Squircle {
        anchors.fill: parent
        visible: !root.scalloped
        radius: root.shapeRadius
        smoothing: root.shapeSmoothing
        color: root.color
        transform: SkewMatrix {}
    }

    CookieShape {
        anchors.fill: parent
        visible: root.scalloped
        lobes: root.shape.lobes ?? 9
        scallop: root.shape.scallop ?? 0.08
        color: root.color
        transform: SkewMatrix {}
    }

    Item {
        id: contentHost
        anchors.fill: parent
    }
}
