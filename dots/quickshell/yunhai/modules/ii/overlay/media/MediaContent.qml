pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.mediaControls

Item {
    id: root
    anchors.fill: parent
    property real radius: 0

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    property list<real> visualizerPoints: []

    Process {
        id: cavaProc
        running: root.visible && root.activePlayer !== null
        onRunningChanged: {
            if (!cavaProc.running) {
                root.visualizerPoints = [];
            }
        }
        command: ["cava", "-p", `${FileUtils.trimFileProtocol(Directories.scriptPath)}/cava/raw_output_config.txt`]
        stdout: SplitParser {
            onRead: data => {
                let points = data.split(";").map(p => parseFloat(p.trim())).filter(p => !isNaN(p));
                root.visualizerPoints = points;
            }
        }
    }

    Loader {
        id: playerLoader
        anchors.fill: parent
        active: root.activePlayer !== null
        sourceComponent: PlayerControl {
            anchors.fill: parent
            player: root.activePlayer
            visualizerPoints: root.visualizerPoints
            radius: root.radius
        }
    }

    Loader {
        anchors.fill: parent
        active: root.activePlayer === null
        sourceComponent: Rectangle {
            anchors.fill: parent
            color: Appearance.colors.colSurfaceContainer
            radius: root.radius

            ColumnLayout {
                anchors.centerIn: parent

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "music_off"
                    iconSize: 32
                    color: Appearance.colors.colSubtext
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("No active player")
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.normal
                }
            }
        }
    }
}
