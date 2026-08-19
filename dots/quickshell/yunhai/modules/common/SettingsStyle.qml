pragma Singleton

import QtQuick
import Quickshell
import qs.modules.common

Singleton {
    id: root

    property bool grouped: false

    readonly property color cardColor: Appearance.colors.colLayer1
    readonly property real cardRadius: Appearance.rounding.normal
    readonly property real cardPaddingV: 7
    readonly property real cardPaddingH: 10

    readonly property color sectionHeaderColor: Appearance.colors.colOnLayer0
    readonly property real sectionHeaderSize: Appearance.font.pixelSize.larger
}
