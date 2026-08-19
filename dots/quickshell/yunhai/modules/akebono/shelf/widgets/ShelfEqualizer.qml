pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common.widgets

Item {
    id: root
    property real barHeight: 54
    readonly property bool playing: MprisController.activePlayer?.isPlaying ?? false
    readonly property bool shelfEmpty: !root.playing

    implicitWidth: bars.implicitWidth
    implicitHeight: root.barHeight * 0.7

    CavaBars {
        id: bars
        anchors.centerIn: parent
        running: root.playing
        extent: root.barHeight * 0.5
    }
}
