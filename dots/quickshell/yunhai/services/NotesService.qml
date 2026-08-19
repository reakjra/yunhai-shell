pragma Singleton
pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var tabs: [{ "title": "Notes", "icon": "article", "content": "" }]
    property bool _writing: false

    readonly property int count: root.tabs.length

    function _load() {
        try {
            const d = JSON.parse(noteFile.text());
            if (d && Array.isArray(d.tabs) && d.tabs.length > 0)
                root.tabs = d.tabs;
        } catch (e) {}
    }
    function _save() {
        root._writing = true;
        noteFile.setText(JSON.stringify({ "tabs": root.tabs }, null, 2));
        saveTimer.stop();
    }

    function setContent(index, text) {
        if (index < 0 || index >= root.tabs.length)
            return;
        const t = root.tabs.slice();
        t[index] = Object.assign({}, t[index], { "content": text });
        root.tabs = t;
        saveTimer.restart();
    }
    function setTitle(index, title) {
        if (index < 0 || index >= root.tabs.length)
            return;
        const t = root.tabs.slice();
        t[index] = Object.assign({}, t[index], { "title": title });
        root.tabs = t;
        root._save();
    }
    function addTab() {
        const t = root.tabs.slice();
        t.push({ "title": "Tab " + (t.length + 1), "icon": "article", "content": "" });
        root.tabs = t;
        root._save();
        return t.length - 1;
    }
    function closeTab(index) {
        if (root.tabs.length <= 1)
            return;
        const t = root.tabs.slice();
        t.splice(index, 1);
        root.tabs = t;
        root._save();
    }

    FileView {
        id: noteFile
        path: Qt.resolvedUrl(Directories.notesPath)
        watchChanges: true
        onLoaded: root._load()
        onFileChanged: {
            if (root._writing) {
                root._writing = false;
                return;
            }
            noteFile.reload();
            root._load();
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                root._save();
        }
    }

    Timer {
        id: saveTimer
        interval: 400
        onTriggered: root._save()
    }
}
