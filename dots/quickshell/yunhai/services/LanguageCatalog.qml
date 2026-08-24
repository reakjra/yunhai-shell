pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool loaded: false
    property var entries: []
    property var namesByCode: ({})
    property var codesByAlias: ({})

    function load() {
        if (root.loaded || listProc.running)
            return;
        listProc.running = true;
    }

    function nameFor(code: string): string {
        return root.namesByCode[code] ?? root.namesByCode[code.toLowerCase()] ?? code;
    }

    function codeFor(alias: string): string {
        return root.codesByAlias[alias.toLowerCase()] ?? alias;
    }

    Process {
        id: listProc
        command: ["trans", "-no-bidi", "-list-all"]
        property var lines: []

        stdout: SplitParser {
            onRead: data => listProc.lines.push(data)
        }

        onExited: (exitCode, exitStatus) => {
            const entries = [];
            const names = {};
            const aliases = {};
            for (const line of listProc.lines) {
                const columns = line.trim().split(/\s{2,}/);
                if (columns.length < 2)
                    continue;
                const entry = {
                    code: columns[0],
                    name: columns[1],
                    native: columns[2] ?? columns[1]
                };
                entries.push(entry);
                names[entry.code] = entry.name;
                aliases[entry.code.toLowerCase()] = entry.code;
                aliases[entry.name.toLowerCase()] = entry.code;
                aliases[entry.native.toLowerCase()] = entry.code;
            }
            listProc.lines = [];
            root.entries = entries;
            root.namesByCode = names;
            root.codesByAlias = aliases;
            root.loaded = true;
        }
    }
}
