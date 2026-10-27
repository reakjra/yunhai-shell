pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    enum MonitorSource { Monitor, Input }

    signal recognized(var track)

    readonly property int monitorSource: Config.options.musicRecognition.source
    property int timeoutInterval: Config.options.musicRecognition.interval
    property int timeoutDuration: Config.options.musicRecognition.timeout
    readonly property bool running: recognizeMusicProc.running
    readonly property var history: Persistent.states.musicRecognition.history.slice()
    readonly property int historyLimit: 50

    function toggleRunning(running) {
        if (recognizeMusicProc.running && !running === true) root.manuallyStopped = true;
        if (running != undefined) {
            recognizeMusicProc.running = running
        } else {
            recognizeMusicProc.running = !root.running
        }
        musicReconizedProc.running = false
    }

    function toggleMonitorSource(source) {
        if (source !== undefined) {
            Config.options.musicRecognition.source = source
            return
        }
        Config.options.musicRecognition.source = (root.monitorSource === SongRec.MonitorSource.Monitor) ? SongRec.MonitorSource.Input : SongRec.MonitorSource.Monitor
    }
    function monitorSourceToString(source) {
        if (source === SongRec.MonitorSource.Monitor) {
            return "monitor"
        } else {
            return "input"
        }
    }
    readonly property string monitorSourceString: monitorSourceToString(monitorSource)
    property var recognizedTrack: ({ title:"", subtitle:"", url:""})
    property bool manuallyStopped: false

    function openShazam(track) {
        Qt.openUrlExternally(track.url)
    }

    function openYoutube(track) {
        Qt.openUrlExternally(`https://www.youtube.com/results?search_query=${encodeURIComponent(`${track.title} - ${track.subtitle}`)}`)
    }

    function removeFromHistory(time) {
        Persistent.states.musicRecognition.history = root.history.filter(track => track.time !== time)
    }

    function clearHistory() {
        Persistent.states.musicRecognition.history = []
    }

    function handleRecognition(jsonText) {
        try {
            var obj = JSON.parse(jsonText)
            root.recognizedTrack = {
                title: obj.track.title,
                subtitle: obj.track.subtitle,
                url: obj.track.url
            }
            Persistent.states.musicRecognition.history = [Object.assign({ time: Date.now() }, root.recognizedTrack), ...root.history].slice(0, root.historyLimit)
            root.recognized(root.recognizedTrack)
            musicReconizedProc.running = true
        } catch(e) {
            Quickshell.execDetached(["notify-send", Translation.tr("Couldn't recognize music"), Translation.tr("Perhaps what you're listening to is too niche"), "-a", "Shell"])
        }
    }

    Process {
        id: recognizeMusicProc
        running: false
        command: [`${Directories.scriptPath}/musicRecognition/recognize-music.sh`, "-i", root.timeoutInterval, "-t", root.timeoutDuration, "-s", root.monitorSourceString]
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.manuallyStopped) {
                    root.manuallyStopped = false
                    return
                }
                handleRecognition(this.text)
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 1) {
                Quickshell.execDetached(["notify-send", Translation.tr("Couldn't recognize music"), Translation.tr("Make sure you have songrec installed"), "-a", "Shell"])
            }
        }
    }

    Process {
        id: musicReconizedProc
        running: false
        command: [
            "notify-send",
            Translation.tr("Music Recognized"), 
            root.recognizedTrack.title + " - " + root.recognizedTrack.subtitle, 
            "-A", "Shazam",
            "-A", "YouTube",
            "-a", "Shell"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text === "") return
                if (this.text == 0) {
                    root.openShazam(root.recognizedTrack);
                } else {
                    root.openYoutube(root.recognizedTrack);
                }
            }
        }
    }
}