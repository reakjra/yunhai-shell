pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.modules.common

Singleton {
    id: root

    readonly property QtObject rounding: QtObject {
        readonly property real armpit: Appearance.rounding.medlarge
        readonly property real panelLarge: Appearance.rounding.medlarge
        readonly property real panelNested: 20
        readonly property real panelSmall: Appearance.rounding.normal
    }
}
