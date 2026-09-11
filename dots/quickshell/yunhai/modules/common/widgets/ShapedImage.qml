pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.common

Item {
    id: root

    property var shape: ({})
    property url source
    property string fallbackIcon: "person"
    property real themeRadius: Appearance.rounding.normal
    property color fallbackColor: Appearance.colors.colLayer2
    readonly property int status: image.status
    readonly property bool ready: image.status === Image.Ready

    Image {
        id: image
        anchors.fill: parent
        source: root.source
        visible: root.ready
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize.width: image.width
        sourceSize.height: image.height
        layer.enabled: root.ready
        layer.effect: OpacityMask {
            maskSource: ShapeSurface {
                width: image.width
                height: image.height
                shape: root.shape
                themeRadius: root.themeRadius
                color: "white"
            }
        }
    }

    ShapeSurface {
        anchors.fill: parent
        visible: !root.ready
        shape: root.shape
        themeRadius: root.themeRadius
        color: root.fallbackColor

        MaterialSymbol {
            anchors.centerIn: parent
            text: root.fallbackIcon
            iconSize: Math.round(Math.min(root.width, root.height) * 0.45)
            color: Appearance.m3colors.m3onSurfaceVariant
        }
    }
}
