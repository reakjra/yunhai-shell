import QtQuick
import qs.modules.common

Rectangle {
    id: contentItem
    anchors.fill: parent
    color: (Config?.options.appearance.transparency.enable ?? false)
        ? Qt.rgba(
            Appearance.m3colors.m3surfaceContainer.r,
            Appearance.m3colors.m3surfaceContainer.g,
            Appearance.m3colors.m3surfaceContainer.b,
            Math.max(0.8, 1 - Config.options.appearance.transparency.backgroundTransparency)
        )
        : Appearance.colors.colSurfaceContainer
}
