pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae.widgets
import qs.services

ColumnLayout {
    id: root

    property bool wanted: false
    property Item menuOverlay: null

    readonly property var player: MprisController.activePlayer

    spacing: 8

    onWantedChanged: LyricsService.setWant(root, wanted)
    Component.onCompleted: LyricsService.setWant(root, wanted)
    Component.onDestruction: LyricsService.setWant(root, false)

    RowLayout {
        Layout.fillWidth: true
        Layout.rightMargin: 26
        spacing: 6

        MaterialSymbol {
            text: "lyrics"
            iconSize: 18
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            Layout.fillWidth: true
            text: Translation.tr("Lyrics")
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            text: LyricsService.loading ? "…" : LyricsService.source
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: Appearance.m3colors.m3outline
            visible: text !== ""
        }
    }

    ListView {
        id: lyricList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        model: LyricsService.model
        currentIndex: LyricsService.currentIndex
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: height / 2 - 24
        preferredHighlightEnd: height / 2 + 24
        highlightMoveDuration: 300
        highlightMoveVelocity: -1
        spacing: 6
        boundsBehavior: Flickable.StopAtBounds

        delegate: StyledText {
            id: line

            required property int index
            required property real time
            required property string lyricLine

            readonly property bool current: ListView.isCurrentItem

            width: lyricList.width
            text: lyricLine === "" ? "♪" : lyricLine
            wrapMode: Text.Wrap
            font.pixelSize: current ? Appearance.font.pixelSize.normal : Appearance.font.pixelSize.small
            font.weight: current ? Font.DemiBold : Font.Normal
            color: current ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
            opacity: current ? 1 : 0.75

            Behavior on opacity {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.player?.canSeek ?? false
                onClicked: root.player.position = line.time
            }
        }

        StyledText {
            anchors.centerIn: parent
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            visible: !LyricsService.hasLyrics
            text: LyricsService.loading ? Translation.tr("Searching lyrics…")
                : LyricsService.instrumental ? Translation.tr("Instrumental ♪")
                : Translation.tr("No lyrics")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.m3colors.m3outline
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 4

        LunaeIconButton {
            implicitWidth: 34; implicitHeight: 34
            buttonIcon: "move_up"
            iconSize: 18
            enabled: root.player?.canRaise ?? false
            onClicked: root.player?.raise()
        }

        PlayerSelector {
            menuOverlay: root.menuOverlay
        }

        LunaeIconButton {
            implicitWidth: 34; implicitHeight: 34
            buttonIcon: "close"
            iconSize: 18
            enabled: root.player?.canQuit ?? false
            onClicked: root.player?.quit()
        }
    }
}
