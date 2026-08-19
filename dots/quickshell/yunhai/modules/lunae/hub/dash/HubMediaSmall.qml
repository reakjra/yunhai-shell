pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae.widgets
import qs.services

ColumnLayout {
    id: root

    spacing: 6

    property real playerProgress: {
        const player = MprisController.activePlayer;
        return player?.length ? player.position / player.length : 0;
    }

    Behavior on playerProgress {
        NumberAnimation {
            duration: 450
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        running: MprisController.activePlayer?.isPlaying ?? false
        interval: 500
        triggeredOnStart: true
        repeat: true
        onTriggered: MprisController.activePlayer?.positionChanged()
    }

    Item {
        id: artContainer
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: coverSize + 26
        Layout.preferredHeight: coverSize + 26

        readonly property real coverSize: Math.min(100, root.width - 38)

        WavyArc {
            anchors.fill: parent
            value: root.playerProgress
            playing: MprisController.isPlaying
        }

        MouseArea {
            anchors.fill: parent
            enabled: MprisController.activePlayer?.canSeek ?? false
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

            function seekFromMouse(mouse: MouseEvent) {
                if (!MprisController.activePlayer) return;
                const dx = mouse.x - width / 2;
                const dy = mouse.y - height / 2;
                const angle = Math.max(-90, Math.min(90, Math.atan2(dx, -dy) * 180 / Math.PI));
                const ratio = (angle + 90) / 180;
                MprisController.activePlayer.position = ratio * MprisController.activePlayer.length;
            }

            onPressed: mouse => seekFromMouse(mouse)
            onPositionChanged: mouse => { if (pressed) seekFromMouse(mouse); }
        }

        CookieImage {
            id: cover
            anchors.centerIn: parent
            width: artContainer.coverSize
            height: artContainer.coverSize
            source: MprisController.activeTrack?.artUrl ?? ""
            lobes: 9
            scallop: 0.06
            fallbackIcon: "art_track"

            NumberAnimation on rot {
                running: MprisController.isPlaying && cover.visible
                loops: Animation.Infinite
                from: 0
                to: 2 * Math.PI
                duration: 40000
            }
        }
    }

    StyledText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: MprisController.activeTrack?.title ?? Translation.tr("No media")
        font.pixelSize: Appearance.font.pixelSize.small
        color: Appearance.colors.colPrimary
        elide: Text.ElideRight
    }

    StyledText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: MprisController.activeTrack?.album ?? ""
        font.pixelSize: Appearance.font.pixelSize.smallest
        color: Appearance.m3colors.m3outline
        elide: Text.ElideRight
        visible: text !== ""
    }

    StyledText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        text: MprisController.activeTrack?.artist ?? ""
        font.pixelSize: Appearance.font.pixelSize.small
        color: Appearance.m3colors.m3secondary
        elide: Text.ElideRight
        visible: text !== ""
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 4

        LunaeIconButton {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 32; implicitHeight: 32
            buttonIcon: "skip_previous"
            iconFill: 1
            enabled: MprisController.canGoPrevious
            onClicked: MprisController.previous()
        }

        LunaeIconButton {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 52; implicitHeight: 32
            buttonRadius: MprisController.isPlaying ? Appearance.rounding.unsharpenmore : Appearance.rounding.verysmall
            Behavior on buttonRadius {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
            buttonIcon: MprisController.isPlaying ? "pause" : "play_arrow"
            iconFill: 1
            enabled: MprisController.canTogglePlaying
            onClicked: MprisController.togglePlaying()
        }

        LunaeIconButton {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 32; implicitHeight: 32
            buttonIcon: "skip_next"
            iconFill: 1
            enabled: MprisController.canGoNext
            onClicked: MprisController.next()
        }
    }

    AnimatedImage {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.margins: 4
        playing: MprisController.activePlayer?.isPlaying ?? false
        source: Config.options.lunae.hub.dash.gifSource
        asynchronous: true
        fillMode: AnimatedImage.PreserveAspectFit
    }
}
