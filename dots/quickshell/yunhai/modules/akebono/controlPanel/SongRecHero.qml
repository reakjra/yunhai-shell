import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

HeroCard {
    id: root

    property var lastTrack: null
    readonly property string sourceName: SongRec.monitorSource === SongRec.MonitorSource.Monitor ? Translation.tr("system audio") : Translation.tr("the microphone")

    title: root.lastTrack && !SongRec.running ? root.lastTrack.title : Translation.tr("Song recognition")
    subtitle: {
        if (SongRec.running)
            return Translation.tr("Listening to %1...").arg(root.sourceName);
        if (root.lastTrack)
            return root.lastTrack.subtitle;
        return Translation.tr("Nothing recognized yet");
    }
    switchChecked: SongRec.running
    onSwitchToggled: checked => SongRec.toggleRunning(checked)

    Connections {
        target: SongRec

        function onRecognized(track) {
            root.lastTrack = track;
        }
    }

    glyph: MaterialSymbol {
        anchors.centerIn: parent
        text: SongRec.running ? "graphic_eq" : "music_note"
        iconSize: root.glyphSize
        fill: 1
        color: Appearance.colors.colOnPrimaryContainer
    }

    Flow {
        Layout.fillWidth: true
        visible: root.lastTrack !== null && !SongRec.running
        spacing: 6

        Pill {
            clickable: true
            icon: "open_in_new"
            text: "Shazam"
            onClicked: SongRec.openShazam(root.lastTrack)
        }
        Pill {
            clickable: true
            icon: "play_circle"
            text: "YouTube"
            onClicked: SongRec.openYoutube(root.lastTrack)
        }
    }
}
