pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.modules.lunae.widgets
import qs.services

Item {
    id: root

    property bool playing: false
    property bool active: false

    readonly property real gap: 6
    readonly property real maxMag: 26
    readonly property real lobes: 9
    readonly property real scallop: 0.07
    readonly property real cookieSize: Math.max(60, Math.min(Math.min(width, height) - 2 * (gap + maxMag) - 8, 180))

    property real rot: 0

    function edgeDist(theta) {
        return cookieSize / 2 * (1 - scallop + scallop * Math.cos(lobes * (theta + rot)))
    }

    onActiveChanged: active ? CavaService.acquire(root) : CavaService.release(root)
    Component.onCompleted: if (active) CavaService.acquire(root)
    Component.onDestruction: CavaService.release(root)

    NumberAnimation on rot {
        running: root.playing && root.active
        loops: Animation.Infinite
        from: 0
        to: 2 * Math.PI
        duration: 40000
    }

    Repeater {
        model: CavaService.barCount

        Rectangle {
            required property int index
            readonly property real angle: (index / CavaService.barCount) * 360 - 90
            readonly property real radian: angle * Math.PI / 180
            readonly property real value: Math.max(0.03, Math.min(1, CavaService.bars[index] ?? 0))
            readonly property real innerR: root.edgeDist(radian) + root.gap
            readonly property real barLen: Math.max(2, value * root.maxMag)

            x: root.width / 2 + Math.cos(radian) * (innerR + barLen / 2) - width / 2
            y: root.height / 2 + Math.sin(radian) * (innerR + barLen / 2) - barLen / 2
            width: Math.max(3, (2 * Math.PI * (root.cookieSize / 2 + root.gap)) / CavaService.barCount - 3)
            height: barLen
            radius: width / 2
            rotation: angle + 90
            color: Appearance.colors.colPrimary
            transformOrigin: Item.Center
        }
    }

    CookieImage {
        anchors.centerIn: parent
        width: root.cookieSize
        height: root.cookieSize
        source: MprisController.activeTrack?.artUrl ?? ""
        lobes: root.lobes
        scallop: root.scallop
        rot: root.rot
        fallbackIcon: "music_note"
    }
}
