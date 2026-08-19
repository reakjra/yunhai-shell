pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property var modBits: [[4, "Ctrl"], [64, "Super"], [8, "Alt"], [1, "Shift"]]
    readonly property var categoryOrder: ["Shell", "Utilities", "Window", "Workspace", "App", "Misc"]
    readonly property int columnCount: 3
    property var keybinds: ({ children: [] })

    function decodeMods(mask) {
        return modBits.filter(m => mask & m[0]).map(m => m[1]);
    }

    function keyName(bind) {
        let key = bind.key;
        if (!key && bind.keycode)
            key = "code:" + bind.keycode;
        if (key.startsWith("code:")) {
            const code = parseInt(key.slice(5));
            if (code >= 10 && code <= 19)
                key = String((code - 9) % 10);
        }
        if (key === "SUPER_L") key = "Super_L";
        if (key === "SUPER_R") key = "Super_R";
        if (!key) key = "#";
        return key;
    }

    function rebuild(binds) {
        const sections = {};
        const seen = new Set();
        for (const bind of binds) {
            if (!bind.has_description || bind.submap !== "")
                continue;
            const sep = bind.description.indexOf(": ");
            const category = sep > 0 ? bind.description.slice(0, sep) : "Misc";
            const comment = sep > 0 ? bind.description.slice(sep + 2) : bind.description;
            const key = keyName(bind);
            const id = `${bind.modmask}|${key}|${bind.description}`;
            if (seen.has(id))
                continue;
            seen.add(id);
            if (!sections[category])
                sections[category] = [];
            sections[category].push({
                mods: decodeMods(bind.modmask),
                key: key,
                comment: comment,
            });
        }

        const names = [
            ...categoryOrder.filter(n => sections[n]),
            ...Object.keys(sections).filter(n => !categoryOrder.includes(n)).sort(),
        ];
        const secList = names.map(n => ({ name: n, keybinds: sections[n], children: [] }));

        const total = secList.reduce((acc, s) => acc + s.keybinds.length, 0);
        const target = total / columnCount;
        const columns = [];
        let col = [];
        let filled = 0;
        for (const sec of secList) {
            if (col.length && columns.length < columnCount - 1
                    && filled + sec.keybinds.length / 2 > target * (columns.length + 1)) {
                columns.push(col);
                col = [];
            }
            col.push(sec);
            filled += sec.keybinds.length;
        }
        if (col.length)
            columns.push(col);

        return { children: columns.map(c => ({ children: c })) };
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded")
                fetchBinds.running = true
        }
    }

    Process {
        id: fetchBinds
        running: true
        command: ["hyprctl", "binds", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.keybinds = root.rebuild(JSON.parse(text))
                } catch (e) {
                    console.error("[HyprlandKeybinds] failed to parse hyprctl binds:", e)
                }
            }
        }
    }
}
