pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae
import qs.modules.lunae.drawers.panels

Item {
    id: root

    enum Axis { Vertical, Horizontal }

    property int axis: Panel.Axis.Vertical
    property bool shouldShow: false
    property real naturalSize: 0
    property real slidePad: 8
    property real deformAmount: 0.1

    readonly property alias deformX: deform.sx
    readonly property alias deformY: deform.sy

    readonly property bool _vertical: axis === Panel.Axis.Vertical

    property real _frozenSize: 0
    onNaturalSizeChanged: if (naturalSize > 0) _frozenSize = naturalSize
    readonly property real _effSize: naturalSize > 0 ? naturalSize : _frozenSize

    property real progress: shouldShow ? 1 : 0
    readonly property real slideOffset: (_effSize + slidePad) * (1 - progress)

    visible: progress > 0.004
    opacity: progress
    transform: Matrix4x4 { matrix: deform.matrix }

    DeformTracker {
        id: deform
        target: root
        amount: root.deformAmount
    }

    MotionBehavior on progress {}

    Binding on implicitHeight {
        when: root._vertical
        value: root._effSize
    }

    Binding on implicitWidth {
        when: !root._vertical
        value: root._effSize
    }
}
