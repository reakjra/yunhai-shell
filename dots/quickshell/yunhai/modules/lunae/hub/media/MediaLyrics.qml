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

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        LyricsView {
            anchors.fill: parent
            centered: false
            currentFontSize: Appearance.font.pixelSize.normal
            otherFontSize: Appearance.font.pixelSize.small
            otherColor: Appearance.colors.colSubtext
            dimOpacity: 0.75
            linePadding: 6
        }

        LyricsPlaceholder {
            anchors.centerIn: parent
            width: parent.width
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
