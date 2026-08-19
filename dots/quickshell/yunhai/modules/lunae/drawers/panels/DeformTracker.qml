import QtQuick
import qs.modules.common

Item {
    id: root

    required property Item target
    property real amount: 0.1
    property real stiffness: 200
    property real damping: 16
    property real maxStretch: 0.3

    readonly property real strength: Config.options.lunae?.deformStrength ?? 1

    property real sx: 1
    property real sy: 1

    readonly property matrix4x4 matrix: Qt.matrix4x4(
        sx, 0, 0, (1 - sx) * (target?.width ?? 0) / 2,
        0, sy, 0, (1 - sy) * (target?.height ?? 0) / 2,
        0, 0, 1, 0,
        0, 0, 0, 1)

    visible: false

    property bool excited: false
    property real _px: 0
    property real _py: 0
    property real _vx: 0
    property real _vy: 0

    function poke() {
        if (excited || amount <= 0 || strength <= 0 || !target || !target.visible)
            return
        _px = target.x + target.width / 2
        _py = target.y + target.height / 2
        excited = true
    }

    function rest() {
        excited = false
        sx = 1
        sy = 1
        _vx = 0
        _vy = 0
    }

    Connections {
        target: root.target
        function onXChanged() { root.poke() }
        function onYChanged() { root.poke() }
        function onWidthChanged() { root.poke() }
        function onHeightChanged() { root.poke() }
        function onVisibleChanged() { if (!root.target.visible) root.rest() }
    }

    FrameAnimation {
        running: root.excited
        onTriggered: {
            const t = root.target
            const dt = Math.min(frameTime, 1 / 30)
            if (dt <= 0)
                return
            const cx = t.x + t.width / 2
            const cy = t.y + t.height / 2
            const vx = (cx - root._px) / dt
            const vy = (cy - root._py) / dt
            root._px = cx
            root._py = cy
            const kk = root.amount * root.strength / 10000
            const ex = Math.min(root.maxStretch, Math.abs(vx) * kk)
            const ey = Math.min(root.maxStretch, Math.abs(vy) * kk)
            const tx = (1 + ex) / (1 + ey)
            const ty = (1 + ey) / (1 + ex)
            root._vx += (root.stiffness * (tx - root.sx) - root.damping * root._vx) * dt
            root._vy += (root.stiffness * (ty - root.sy) - root.damping * root._vy) * dt
            root.sx += root._vx * dt
            root.sy += root._vy * dt
            if (Math.abs(vx) < 2 && Math.abs(vy) < 2
                && Math.abs(root.sx - 1) < 0.001 && Math.abs(root.sy - 1) < 0.001
                && Math.abs(root._vx) < 0.01 && Math.abs(root._vy) < 0.01)
                root.rest()
        }
    }
}
