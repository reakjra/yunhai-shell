pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common

ListView {
    id: root

    property bool centered: true
    property real currentFontSize: Appearance.font.pixelSize.hugeass
    property real otherFontSize: Appearance.font.pixelSize.larger
    property color currentColor: Appearance.colors.colPrimary
    property color otherColor: Appearance.colors.colOnLayer1
    property real dimOpacity: 0.45
    property real linePadding: 12
    property real lineInset: root.centered ? 20 : 0
    property real emptyFontSize: Appearance.font.pixelSize.normal
    property color emptyColor: Appearance.colors.colSubtext

    clip: true
    visible: LyricsService.hasLyrics
    model: LyricsService.model
    currentIndex: LyricsService.currentIndex
    highlightFollowsCurrentItem: true
    highlightMoveDuration: 400
    highlightRangeMode: ListView.ApplyRange
    preferredHighlightBegin: root.height / 2 - 30
    preferredHighlightEnd: root.height / 2 + 30
    boundsBehavior: Flickable.StopAtBounds

    delegate: Item {
        id: line
        required property int index
        required property string lyricLine
        readonly property bool current: line.index === root.currentIndex

        width: root.width
        implicitHeight: lineText.implicitHeight + root.linePadding

        StyledText {
            id: lineText
            anchors.centerIn: parent
            width: parent.width - root.lineInset
            horizontalAlignment: root.centered ? Text.AlignHCenter : Text.AlignLeft
            wrapMode: Text.WordWrap
            text: line.lyricLine === "" ? "♪" : line.lyricLine
            font.pixelSize: line.current ? root.currentFontSize : root.otherFontSize
            font.weight: line.current ? Font.DemiBold : Font.Normal
            color: line.current ? root.currentColor : root.otherColor
            opacity: line.current ? 1 : root.dimOpacity

            Behavior on opacity {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }
            Behavior on color {
                ColorAnimation { duration: 220 }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: LyricsService.jumpTo(line.index)
        }
    }
}
