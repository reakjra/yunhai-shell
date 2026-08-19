pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono
import QtQuick
import QtQuick.Layouts
import Quickshell
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property real barHeight: 54
    property var shelf

    readonly property var player: MprisController.activePlayer
    readonly property var track: MprisController.activeTrack
    readonly property bool shelfEmpty: !player

    readonly property bool iconMode: (Config.options.akebono?.shelf.media.layout ?? "art") === "icon"
    readonly property bool showTitle: Config.options.akebono?.shelf.media.showTitle ?? true
    readonly property bool showLyricsInline: Config.options.akebono?.shelf.media.showLyricsInline ?? false
    readonly property bool lyricsExpand: Config.options.akebono?.shelf.media.lyricsExpand ?? false
    readonly property bool lyricsMode: !iconMode && showLyricsInline && LyricsService.hasLyrics

    readonly property string artUrl: track?.artUrl ?? ""
    readonly property bool hasArt: artUrl.length > 0

    readonly property bool lyricsWanted: !iconMode && showLyricsInline && (player !== null)
    onLyricsWantedChanged: LyricsService.setWant(root, lyricsWanted)
    Component.onCompleted: LyricsService.setWant(root, lyricsWanted)
    Component.onDestruction: LyricsService.setWant(root, false)

    readonly property real pillHeight: barHeight * (lyricsMode ? 0.98 : 0.7)
    readonly property real artSize: Math.round(pillHeight * 0.72)
    readonly property real lyricsViewHeight: Math.round(pillHeight - 6)
    readonly property real lineH: lyricsViewHeight / 3
    readonly property real lyricsWidth: lyricsExpand
        ? Math.min(Math.max(curMetrics.width + 6, 90), 460)
        : 240

    TextMetrics {
        id: curMetrics
        font.pixelSize: Appearance.font.pixelSize.small
        font.weight: Font.DemiBold
        text: LyricsService.currentLine
    }

    visible: !shelfEmpty
    implicitWidth: shelfEmpty ? 0 : pill.implicitWidth
    implicitHeight: pillHeight
    Layout.alignment: Qt.AlignVCenter
    Behavior on implicitHeight {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }

    Squircle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: pillRow.implicitWidth + (root.iconMode ? 16 : 18)
        implicitHeight: root.pillHeight
        radius: root.iconMode ? height / 2 : Math.min(height / 2, 22)
        color: mediaMouse.containsMouse ? AkebonoAppearance.shelfPillHoverColor : AkebonoAppearance.shelfPillColor
        Behavior on implicitHeight {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        Component.onCompleted: root.shelf?.registerMediaAnchor(pill)
        Component.onDestruction: root.shelf?.unregisterMediaAnchor(pill)
        onXChanged: root.shelf?.publishMedia()
        onWidthChanged: root.shelf?.publishMedia()

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 9

            MaterialSymbol {
                visible: root.iconMode
                Layout.alignment: Qt.AlignVCenter
                text: (root.player?.isPlaying ?? false) ? "pause" : "music_note"
                iconSize: Math.round(root.barHeight * 0.42)
                color: Appearance.colors.colOnLayer1
            }

            Squircle {
                id: art
                visible: !root.iconMode
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: root.artSize
                implicitHeight: root.artSize
                radius: root.artSize * 0.32
                color: Appearance.colors.colSecondaryContainer

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: "music_note"
                    iconSize: Math.round(root.artSize * 0.6)
                    color: Appearance.colors.colOnSecondaryContainer
                    visible: !root.hasArt || cover.status !== Image.Ready
                }

                Image {
                    id: cover
                    anchors.fill: parent
                    source: root.hasArt ? root.artUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                    visible: root.hasArt && status === Image.Ready
                    layer.enabled: visible
                    layer.effect: OpacityMask {
                        maskSource: Squircle {
                            width: cover.width
                            height: cover.height
                            radius: art.radius
                            color: "white"
                        }
                    }
                }
            }

            ListView {
                id: lyricsView
                visible: root.lyricsMode
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: root.lyricsWidth
                implicitHeight: root.lyricsViewHeight
                clip: true
                interactive: false
                model: LyricsService.model
                currentIndex: LyricsService.currentIndex
                highlightFollowsCurrentItem: true
                highlightMoveDuration: 300
                highlightRangeMode: ListView.ApplyRange
                preferredHighlightBegin: root.lineH
                preferredHighlightEnd: root.lineH * 2
                Behavior on implicitWidth {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }

                delegate: Item {
                    id: lyricDelegate
                    required property int index
                    required property string lyricLine
                    readonly property bool current: index === lyricsView.currentIndex
                    width: lyricsView.width
                    height: root.lineH

                    StyledText {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        text: lyricDelegate.lyricLine
                        font.pixelSize: lyricDelegate.current ? Appearance.font.pixelSize.small : Appearance.font.pixelSize.smaller
                        font.weight: lyricDelegate.current ? Font.DemiBold : Font.Normal
                        color: lyricDelegate.current ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                        opacity: lyricDelegate.current ? 1 : 0.45
                        elide: (lyricDelegate.current && root.lyricsExpand) ? Text.ElideNone : Text.ElideRight
                        wrapMode: Text.NoWrap
                    }
                }
            }

            Column {
                id: titleCol
                visible: !root.iconMode && !root.lyricsMode && root.showTitle
                Layout.alignment: Qt.AlignVCenter
                spacing: 1

                StyledText {
                    width: Math.min(implicitWidth, 220)
                    text: root.track?.title ?? ""
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                }
                StyledText {
                    width: Math.min(implicitWidth, 220)
                    visible: text.length > 0
                    text: root.track?.artist ?? ""
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: mediaMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.shelf?.toggleMedia()
        }
    }
}
