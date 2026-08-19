pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.lunae.widgets
import qs.services

ColumnLayout {
    id: root

    readonly property var player: MprisController.activePlayer
    readonly property real playerProgress: player?.length ? player.position / player.length : 0

    spacing: 2

    Timer {
        running: root.player?.isPlaying ?? false
        interval: 500
        triggeredOnStart: true
        repeat: true
        onTriggered: root.player?.positionChanged()
    }

    Item { Layout.fillHeight: true }

    Item {
        id: trackInfoWrapper
        Layout.fillWidth: true
        implicitHeight: trackInfoCol.implicitHeight

        property string displayTitle: ""
        property string displayAlbum: ""
        property string displayArtist: ""

        Component.onCompleted: syncText()
        function syncText() {
            displayTitle = MprisController.activeTrack?.title ?? Translation.tr("No media")
            displayAlbum = MprisController.activeTrack?.album ?? ""
            displayArtist = MprisController.activeTrack?.artist ?? ""
        }

        property string trackKey: MprisController.activeTrack?.title ?? ""
        onTrackKeyChanged: trackFade.restart()

        SequentialAnimation {
            id: trackFade
            NumberAnimation {
                target: trackInfoCol; property: "opacity"; to: 0
                duration: 150; easing.type: Easing.InCubic
            }
            ScriptAction { script: trackInfoWrapper.syncText() }
            NumberAnimation {
                target: trackInfoCol; property: "opacity"; to: 1
                duration: 150; easing.type: Easing.OutCubic
            }
        }

        ColumnLayout {
            id: trackInfoCol
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 2

            StyledText {
                Layout.fillWidth: true
                text: trackInfoWrapper.displayTitle
                font.pixelSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colPrimary
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                text: trackInfoWrapper.displayArtist
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.m3colors.m3secondary
                elide: Text.ElideRight
                visible: text !== ""
            }

            StyledText {
                Layout.fillWidth: true
                text: trackInfoWrapper.displayAlbum
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.m3colors.m3outline
                elide: Text.ElideRight
                visible: text !== ""
            }
        }
    }

    Item { implicitHeight: 12 }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        TextMetrics {
            id: timeMetrics
            text: StringUtils.friendlyTimeForSeconds(root.player?.length ?? 0).replace(/[0-9]/g, "0")
            font.pixelSize: Appearance.font.pixelSize.smallest
        }

        StyledText {
            Layout.preferredWidth: timeMetrics.width
            text: StringUtils.friendlyTimeForSeconds(root.player?.position ?? 0)
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: Appearance.m3colors.m3outline
            horizontalAlignment: Text.AlignHCenter
        }

        MediaProgressSlider {
            Layout.fillWidth: true
            enabled: root.player?.canSeek ?? false
            value: root.playerProgress
            onMoved: {
                if (!root.player)
                    return
                root.player.position = value * root.player.length
            }
        }

        StyledText {
            Layout.preferredWidth: timeMetrics.width
            text: StringUtils.friendlyTimeForSeconds(root.player?.length ?? 0)
            font.pixelSize: Appearance.font.pixelSize.smallest
            color: Appearance.m3colors.m3outline
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Item { implicitHeight: 6 }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 8

        LunaeIconButton {
            implicitWidth: 34; implicitHeight: 34
            buttonIcon: "shuffle"
            iconSize: 18
            toggled: root.player?.shuffle ?? false
            enabled: root.player?.shuffleSupported ?? false
            onClicked: MprisController.setShuffle(!root.player.shuffle)
        }

        LunaeIconButton {
            implicitWidth: 40; implicitHeight: 40
            buttonIcon: "skip_previous"
            iconSize: 24
            iconFill: 1
            enabled: MprisController.canGoPrevious
            onClicked: MprisController.previous()
        }

        RippleButton {
            implicitWidth: 44; implicitHeight: 44
            padding: 0
            buttonRadius: MprisController.isPlaying ? Appearance.rounding.verysmall : Appearance.rounding.small
            Behavior on buttonRadius {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
            colBackground: Appearance.colors.colPrimary
            colBackgroundHover: Appearance.colors.colPrimaryHover
            colRipple: Appearance.colors.colPrimaryActive
            enabled: MprisController.canTogglePlaying
            onClicked: MprisController.togglePlaying()
            contentItem: MaterialSymbol {
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: MprisController.isPlaying ? "pause" : "play_arrow"
                iconSize: 28
                fill: 1
                color: Appearance.m3colors.m3onPrimary
            }
        }

        LunaeIconButton {
            implicitWidth: 40; implicitHeight: 40
            buttonIcon: "skip_next"
            iconSize: 24
            iconFill: 1
            enabled: MprisController.canGoNext
            onClicked: MprisController.next()
        }

        LunaeIconButton {
            implicitWidth: 34; implicitHeight: 34
            buttonIcon: root.player?.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
            iconSize: 18
            toggled: root.player?.loopState === MprisLoopState.Track || root.player?.loopState === MprisLoopState.Playlist
            enabled: root.player?.loopSupported ?? false
            onClicked: {
                const state = root.player.loopState
                if (state === MprisLoopState.None)
                    MprisController.setLoopState(MprisLoopState.Playlist)
                else if (state === MprisLoopState.Playlist)
                    MprisController.setLoopState(MprisLoopState.Track)
                else
                    MprisController.setLoopState(MprisLoopState.None)
            }
        }
    }

    Item { Layout.fillHeight: true }
}
