pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.modules.lunae.widgets

Item {
    id: root

    property bool playing: false
    property int count: 12

    readonly property var lobePool: [0, 4, 6, 7, 9, 12]

    function rand(min, max) {
        return min + Math.random() * (max - min)
    }

    function signedRand(min, max) {
        return rand(min, max) * (Math.random() < 0.5 ? -1 : 1)
    }

    clip: true

    Repeater {
        id: shapes
        model: root.count

        CookieShape {
            id: shape

            required property int index
            property real vx: root.signedRand(4, 18)
            property real vy: root.signedRand(4, 18)
            property real vr: root.rand(-12, 12)
            readonly property int colourIdx: Math.floor(Math.random() * 3)

            width: 36 + (index / root.count) * 88
            height: width
            opacity: [0.2, 0.2, 0.1][colourIdx]

            Component.onCompleted: {
                x = root.rand(0, Math.max(1, root.width - width))
                y = root.rand(0, Math.max(1, root.height - height))
                rotation = root.rand(0, 360)
            }

            lobes: root.lobePool[Math.floor(Math.random() * root.lobePool.length)]
            scallop: lobes === 0 ? 0 : 0.14
            color: [Appearance.colors.colPrimaryContainer, Appearance.colors.colSecondaryContainer, Appearance.colors.colTertiaryContainer][colourIdx]
        }
    }

    FrameAnimation {
        running: root.visible && root.playing && root.width > 0
        onTriggered: {
            const dt = frameTime
            for (let i = 0; i < shapes.count; i++) {
                const s = shapes.itemAt(i)
                if (!s)
                    continue
                s.x += s.vx * dt
                s.y += s.vy * dt
                s.rotation += s.vr * dt
                if (s.x + s.width < 0)
                    s.x = root.width
                else if (s.x > root.width)
                    s.x = -s.width
                if (s.y + s.height < 0)
                    s.y = root.height
                else if (s.y > root.height)
                    s.y = -s.height
            }
        }
    }
}
