pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common

Singleton {
    readonly property real squircleSmoothing: Config?.options.akebono.squircle.smoothing ?? 4.0

    readonly property bool shelfPills: Config?.options.akebono.shelf.pills ?? true
    readonly property color shelfPillColor: shelfPills ? Appearance.colors.colLayer1 : "transparent"
    readonly property color shelfPillHoverColor: shelfPills ? Appearance.colors.colLayer1Hover : Appearance.colors.colLayer1
}
