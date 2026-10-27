import QtQuick
import qs.modules.common

Behavior {
    id: root

    property QtObject motion: Motion.spatial
    property QtObject exitMotion: motion
    property var exitTarget

    MotionAnimation {
        motion: root.targetValue === root.exitTarget ? root.exitMotion : root.motion
    }
}
