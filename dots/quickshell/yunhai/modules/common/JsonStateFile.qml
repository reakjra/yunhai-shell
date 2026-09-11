pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property string path
    readonly property string revision: adapter.data

    signal reloaded()

    function all() {
        try {
            return JSON.parse(adapter.data) ?? ({});
        } catch (e) {
            return ({});
        }
    }

    function save(value) {
        adapter.data = JSON.stringify(value);
    }

    FileView {
        id: view
        path: root.path
        watchChanges: true
        onFileChanged: reloadTimer.restart()
        onPathChanged: {
            writeTimer.stop();
            view.reload();
        }
        onAdapterUpdated: writeTimer.restart()
        onLoaded: root.reloaded()
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                return;
            adapter.data = "{}";
            view.writeAdapter();
        }
        JsonAdapter {
            id: adapter
            property string data: "{}"
        }
    }

    Timer {
        id: reloadTimer
        interval: 80
        onTriggered: view.reload()
    }

    Timer {
        id: writeTimer
        interval: 120
        onTriggered: view.writeAdapter()
    }
}
