pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell

Singleton {
    id: root

    property bool editMode: false
    property bool textEditing: false
    signal releaseEditing()
    readonly property string revision: store.revision

    signal reloaded()

    function _mutate(id, fn) {
        const all = store.all();
        for (const screen in all) {
            const arr = all[screen];
            if (!Array.isArray(arr))
                continue;
            for (let i = 0; i < arr.length; i++)
                if (arr[i].id === id) {
                    fn(arr[i]);
                    store.save(all);
                    return;
                }
        }
    }

    function screens() {
        const all = store.all();
        return Object.keys(all).filter(k => Array.isArray(all[k]) && all[k].length > 0);
    }

    function widgetsFor(screen) {
        const s = store.all()[screen];
        return Array.isArray(s) ? s : [];
    }
    function get(id) {
        const all = store.all();
        for (const screen in all)
            if (Array.isArray(all[screen]))
                for (const w of all[screen])
                    if (w.id === id)
                        return w;
        return null;
    }

    readonly property var defaultSizes: ({
            "calendar": { "w": 260, "h": 280 },
            "media": { "w": 240, "h": 240 },
            "weather": { "w": 230, "h": 230 },
            "deviceBattery": { "w": 190, "h": 200 },
            "user": { "w": 300, "h": 200 },
            "performance": { "w": 260, "h": 200 }
        })

    function add(screen, type, x, y) {
        const all = store.all();
        if (!Array.isArray(all[screen]))
            all[screen] = [];
        const id = "w" + Date.now();
        const size = root.defaultSizes[type] ?? ({ "w": 190, "h": 190 });
        all[screen].push({ "id": id, "type": type, "x": Math.round(x), "y": Math.round(y), "w": size.w, "h": size.h, "source": "" });
        store.save(all);
        return id;
    }
    function setPos(id, x, y) {
        root._mutate(id, w => {
            w.x = Math.round(x);
            w.y = Math.round(y);
        });
    }
    function setSize(id, w, h) {
        root._mutate(id, e => {
            e.w = Math.round(w);
            e.h = Math.round(h);
        });
    }
    function setProp(id, key, val) {
        root._mutate(id, w => w[key] = val);
    }
    function remove(id) {
        const all = store.all();
        for (const screen in all) {
            if (!Array.isArray(all[screen]))
                continue;
            const before = all[screen].length;
            all[screen] = all[screen].filter(w => w.id !== id);
            if (all[screen].length !== before) {
                store.save(all);
                return;
            }
        }
    }

    JsonStateFile {
        id: store
        onReloaded: root.reloaded()
        path: Directories.desktopWidgetsPath(Config.options.panelFamily)
    }
}
