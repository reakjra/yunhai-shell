pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.lunae
import qs.modules.lunae.widgets

ColumnLayout {
    id: root
    spacing: 10

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing
    readonly property string title: {
        const cleaned = StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || Translation.tr("No media");
        return cleaned.length > 32 ? cleaned.substring(0, 30) + "…" : cleaned;
    }
    readonly property string artist: {
        const a = activePlayer?.trackArtist || Translation.tr("Unknown");
        return a.length > 32 ? a.substring(0, 30) + "…" : a;
    }
    readonly property real position: activePlayer?.position ?? 0
    readonly property real length: activePlayer?.length ?? 0
    readonly property real progress: length > 0 ? position / length : 0

    implicitWidth: 200

    readonly property int cavaBars: 30

    onIsPlayingChanged: isPlaying ? CavaService.acquire(root) : CavaService.release(root)
    Component.onCompleted: if (isPlaying) CavaService.acquire(root)
    Component.onDestruction: CavaService.release(root)

    Timer {
        running: root.isPlaying
        interval: Config.options.resources.updateInterval
        repeat: true
        onTriggered: root.activePlayer?.positionChanged()
    }

    CookieImage {
        id: cover
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 120
        Layout.preferredHeight: 120
        source: root.activePlayer?.trackArtUrl ?? ""
        lobes: 9
        scallop: 0.06
        fallbackIcon: "art_track"

        NumberAnimation on rot {
            running: root.isPlaying && cover.visible
            loops: Animation.Infinite
            from: 0
            to: 2 * Math.PI
            duration: 40000
        }
    }

    StyledText {
        Layout.fillWidth: true
        Layout.topMargin: 2
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Appearance.font.pixelSize.large
        font.weight: Font.DemiBold
        color: Appearance.colors.colOnLayer0
        text: root.title
        elide: Text.ElideRight
        maximumLineCount: 1
    }

    StyledText {
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Appearance.font.pixelSize.small
        color: Appearance.colors.colSubtext
        text: root.artist
        elide: Text.ElideRight
        maximumLineCount: 1
    }

    Row {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 2
        spacing: 20

        LunaeIconButton {
            implicitWidth: 36
            implicitHeight: 36
            buttonIcon: "skip_previous"
            iconSize: Appearance.font.pixelSize.huge
            iconFill: 1
            onClicked: root.activePlayer?.previous()
        }

        RippleButton {
            implicitWidth: 36
            implicitHeight: 36
            padding: 0
            buttonRadius: root.isPlaying ? Appearance.rounding.unsharpenmore : Appearance.rounding.verysmall
            buttonRadiusPressed: Appearance.rounding.unsharpenmore
            colBackground: Appearance.colors.colPrimary
            colBackgroundHover: Appearance.colors.colPrimaryHover
            colRipple: Appearance.colors.colPrimaryActive
            onClicked: root.activePlayer?.togglePlaying()

            Behavior on buttonEffectiveRadius {
                NumberAnimation {
                    duration: LunaeAppearance.morphDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: LunaeAppearance.morphCurve
                }
            }

            contentItem: MaterialSymbol {
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.isPlaying ? "pause" : "play_arrow"
                fill: 1
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colOnPrimary
            }
        }

        LunaeIconButton {
            implicitWidth: 36
            implicitHeight: 36
            buttonIcon: "skip_next"
            iconSize: Appearance.font.pixelSize.huge
            iconFill: 1
            onClicked: root.activePlayer?.next()
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.topMargin: 4
        implicitHeight: cavaRow.height + progressTrack.height

        Row {
            id: cavaRow
            anchors.bottom: progressTrack.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 18
            spacing: 0

            Repeater {
                model: root.cavaBars

                delegate: Item {
                    required property int index
                    readonly property real value: CavaService.bars[Math.floor(index * CavaService.barCount / root.cavaBars)] ?? 0
                    width: cavaRow.width / root.cavaBars
                    height: cavaRow.height

                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 2
                        height: Math.max(2, parent.value * parent.height)
                        radius: width / 2
                        color: Appearance.colors.colPrimary
                        opacity: 0.6

                        Behavior on height {
                            NumberAnimation { duration: 60 }
                        }
                    }
                }
            }
        }

        MouseArea {
            id: progressTrack
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 4
            cursorShape: root.activePlayer?.canSeek ? Qt.PointingHandCursor : Qt.ArrowCursor

            onClicked: (mouse) => {
                if (root.activePlayer?.canSeek && root.length > 0) {
                    root.activePlayer.position = (mouse.x / width) * root.length;
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 2
                color: Appearance.colors.colSecondaryContainer
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * root.progress
                radius: 2
                color: Appearance.colors.colPrimary

                Behavior on width {
                    NumberAnimation { duration: 200 }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: Appearance.font.family.numbers
            color: Appearance.colors.colSubtext
            text: StringUtils.friendlyTimeForSeconds(root.position)
        }

        Item { Layout.fillWidth: true }

        StyledText {
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: Appearance.font.family.numbers
            color: Appearance.colors.colSubtext
            text: StringUtils.friendlyTimeForSeconds(root.length)
        }
    }
}
