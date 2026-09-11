pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import Quickshell

Singleton {
    id: root

    readonly property string revision: store.revision

    function has(screenName, key) {
        const s = store.all()[screenName];
        return !!s && (key in s);
    }

    function resolve(screenName, key, inherited) {
        const s = store.all()[screenName];
        return (s && (key in s)) ? s[key] : inherited;
    }

    function setEffective(screenName, key, value, inherited) {
        if (value === inherited)
            root.clear(screenName, key);
        else
            root.set(screenName, key, value);
    }

    function set(screenName, key, value) {
        const all = store.all();
        if (!all[screenName])
            all[screenName] = ({});
        all[screenName][key] = value;
        store.save(all);
    }

    function clear(screenName, key) {
        const all = store.all();
        if (all[screenName] && (key in all[screenName])) {
            delete all[screenName][key];
            if (Object.keys(all[screenName]).length === 0)
                delete all[screenName];
            store.save(all);
        }
    }

    function clearScreen(screenName) {
        const all = store.all();
        if (screenName in all) {
            delete all[screenName];
            store.save(all);
        }
    }

    JsonStateFile {
        id: store
        path: Directories.screenOverridesPath(Config.options.panelFamily)
    }
}
