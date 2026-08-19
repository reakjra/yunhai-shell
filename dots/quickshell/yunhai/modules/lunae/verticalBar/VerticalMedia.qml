import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.services
import qs

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

MouseArea {
    id: root
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property bool isPlaying: activePlayer?.playbackState === MprisPlaybackState.Playing

    Layout.fillHeight: true
    implicitHeight: contentColumn.implicitHeight + 12
    implicitWidth: Appearance.sizes.verticalBarWidth

    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton

    onPressed: (event) => {
        if (event.button === Qt.MiddleButton) {
            activePlayer.togglePlaying();
        } else if (event.button === Qt.BackButton) {
            activePlayer.previous();
        } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
            activePlayer.next();
        } else if (event.button === Qt.LeftButton) {
            if (GlobalStates.activeBarPopup === "media")
                GlobalStates.activeBarPopup = ""
            else {
                const pos = root.mapToItem(null, 0, root.height / 2)
                GlobalStates.barPopupY = pos.y
                GlobalStates.activeBarPopup = "media"
            }
        }
    }

    property list<real> cavaPoints: [0, 0, 0, 0, 0]
    Process {
        id: cavaProc
        running: root.isPlaying
        onRunningChanged: {
            if (!running) root.cavaPoints = [0, 0, 0, 0, 0];
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/bar_mini_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                const points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                if (points.length >= 5) root.cavaPoints = points.slice(0, 5);
            }
        }
    }

    Item {
        id: contentColumn
        anchors.centerIn: parent
        implicitWidth: 24
        implicitHeight: cavaRow.height + playButton.height + 4

        Item {
            id: cavaRow
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: 5 * 3 + 4 * 2
            height: 16

            Repeater {
                model: 5
                delegate: Rectangle {
                    property real barValue: root.cavaPoints[index] ?? 0
                    property real normalizedValue: Math.min(barValue / 800, 1.0)

                    x: index * 5
                    width: 3
                    height: 2 + normalizedValue * 14
                    anchors.bottom: parent.bottom
                    radius: 1.5
                    color: Config.options.lunae.colorful ? Appearance.colors.colTertiary : Appearance.colors.colOnLayer0

                    Behavior on height {
                        NumberAnimation { duration: 80 }
                    }
                }
            }
        }

        MaterialSymbol {
            id: playButton
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: cavaRow.top
            anchors.bottomMargin: -14
            text: root.isPlaying ? "pause" : "play_arrow"
            fill: 0
            iconSize: Appearance.font.pixelSize.hugeass
            color: Config.options.lunae.colorful ? Appearance.colors.colTertiary : Appearance.colors.colOnLayer0
        }
    }
}
