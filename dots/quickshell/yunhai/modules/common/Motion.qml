pragma Singleton

import QtQuick
import Quickshell
import qs.modules.common

Singleton {
    id: root

    readonly property bool bouncy: Config.options.motion.bouncy
    readonly property var curves: Appearance.animationCurves

    readonly property QtObject spatial: QtObject {
        readonly property int duration: root.curves.expressiveDefaultSpatialDuration
        readonly property list<real> curve: root.bouncy ? root.curves.expressiveDefaultSpatial : root.curves.emphasized
    }

    readonly property QtObject spatialFast: QtObject {
        readonly property int duration: root.bouncy ? root.curves.expressiveFastSpatialDuration : 250
        readonly property list<real> curve: root.bouncy ? root.curves.expressiveFastSpatial : root.curves.emphasized
    }

    readonly property QtObject effects: QtObject {
        readonly property int duration: root.curves.expressiveEffectsDuration
        readonly property list<real> curve: root.curves.expressiveEffects
    }

    readonly property QtObject exit: QtObject {
        readonly property int duration: 400
        readonly property list<real> curve: root.curves.emphasized
    }

    readonly property QtObject exitFast: QtObject {
        readonly property int duration: 250
        readonly property list<real> curve: root.curves.emphasized
    }
}
