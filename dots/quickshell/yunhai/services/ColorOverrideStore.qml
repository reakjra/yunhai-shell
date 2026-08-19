pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root
    property string filePath: Directories.colorOverridesPath
    property alias data: overrideAdapter
    property bool ready: false
    property int readWriteDelay: 50

    Timer {
        id: fileReloadTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: overrideFileView.reload()
    }

    Timer {
        id: fileWriteTimer
        interval: root.readWriteDelay
        repeat: false
        onTriggered: overrideFileView.writeAdapter()
    }

    FileView {
        id: overrideFileView
        path: root.filePath
        watchChanges: true
        onFileChanged: fileReloadTimer.restart()
        onAdapterUpdated: fileWriteTimer.restart()
        onLoaded: root.ready = true
        onLoadFailed: error => {
            if (error == FileViewError.FileNotFound) {
                writeAdapter()
            }
        }

        JsonAdapter {
            id: overrideAdapter
            property string colorOverrides: "{}"
            property string customPresets: "[]"
            property bool preserveOnWallpaperChange: false
            property int activePresetIndex: -1
        }
    }
}
