pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae.widgets
import qs.services

Item {
    id: root

    property bool hubVisible: false
    property Item menuOverlay: null

    readonly property var player: MprisController.activePlayer
    readonly property bool hasPlayer: player !== null
    readonly property bool playing: player?.isPlaying ?? false
    readonly property bool lyricsEnabled: Config.options.media?.lyrics?.enable ?? false
    readonly property bool lyricsShown: lyricsEnabled && (Config.options.lunae.hub.media.showLyrics ?? true)
    readonly property real lyricsWidth: 190

    property real lyricsW: lyricsShown ? lyricsWidth : 0
    Behavior on lyricsW {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    DriftingShapes {
        anchors.fill: parent
        playing: root.playing
        visible: root.hasPlayer
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16
        opacity: root.hasPlayer ? 1 : 0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        CookieVisualiser {
            Layout.preferredWidth: 210
            Layout.fillHeight: true
            playing: root.playing
            active: root.hubVisible && root.hasPlayer
        }

        MediaDetails {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        MediaLyrics {
            Layout.preferredWidth: root.lyricsW
            Layout.leftMargin: -16 * (1 - root.lyricsW / root.lyricsWidth)
            Layout.fillHeight: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            clip: true
            opacity: root.lyricsW / root.lyricsWidth
            visible: root.lyricsEnabled
            wanted: root.lyricsShown && root.hubVisible && root.hasPlayer
            menuOverlay: root.menuOverlay
        }

        AnimatedImage {
            Layout.preferredWidth: 150
            Layout.fillHeight: true
            visible: source !== ""
            playing: root.playing
            source: Config.options.lunae.hub.media.gifSource
            asynchronous: true
            fillMode: AnimatedImage.PreserveAspectFit
        }
    }

    LunaeIconButton {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 12
        implicitWidth: 28
        implicitHeight: 28
        buttonIcon: "lyrics"
        iconSize: 16
        toggled: root.lyricsShown
        visible: root.lyricsEnabled && root.hasPlayer
        onClicked: Config.options.lunae.hub.media.showLyrics = !Config.options.lunae.hub.media.showLyrics
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 4
        opacity: root.hasPlayer ? 0 : 1
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 64
            implicitHeight: 64
            radius: 24
            color: Appearance.colors.colPrimaryContainer

            MaterialSymbol {
                anchors.centerIn: parent
                text: "queue_music"
                iconSize: 32
                color: Appearance.colors.colOnPrimaryContainer
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Translation.tr("Nothing playing")
            font.pixelSize: Appearance.font.pixelSize.large
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Translation.tr("Play something for it to show up here!")
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.m3colors.m3outline
        }
    }
}
