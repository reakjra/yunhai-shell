import QtQuick
import qs.modules.common

NumberAnimation {
    property QtObject motion: Motion.spatial

    duration: motion.duration
    easing.type: Easing.BezierSpline
    easing.bezierCurve: motion.curve
}
