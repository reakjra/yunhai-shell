pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell

Singleton {
    id: root

    readonly property string revision: store.revision

    signal reloaded()

    function cellOf(screenName, fileName) {
        const s = store.all()[screenName];
        return (s && s[fileName]) ? s[fileName] : null;
    }

    function setCell(screenName, fileName, col, row) {
        const all = store.all();
        if (!all[screenName])
            all[screenName] = ({});
        all[screenName][fileName] = { "col": col, "row": row };
        store.save(all);
    }

    function setCells(screenName, assignments) {
        const all = store.all();
        if (!all[screenName])
            all[screenName] = ({});
        for (const k in assignments)
            all[screenName][k] = assignments[k];
        store.save(all);
    }

    function forget(screenName, fileName) {
        const all = store.all();
        if (all[screenName] && (fileName in all[screenName])) {
            delete all[screenName][fileName];
            store.save(all);
        }
    }

    function prune(screenName, names) {
        if (names.length === 0)
            return;
        const all = store.all();
        const s = all[screenName];
        if (!s)
            return;
        const live = new Set(names);
        let changed = false;
        for (const k of Object.keys(s)) {
            if (live.has(k))
                continue;
            delete s[k];
            changed = true;
        }
        if (changed)
            store.save(all);
    }

    function clearScreen(screenName) {
        const all = store.all();
        all[screenName] = ({});
        store.save(all);
    }

    JsonStateFile {
        id: store
        onReloaded: root.reloaded()
        path: Directories.desktopLayoutPath(Config.options.panelFamily)
    }
}
