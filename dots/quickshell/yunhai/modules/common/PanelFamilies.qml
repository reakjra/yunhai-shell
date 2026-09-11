pragma Singleton

import Quickshell

Singleton {
    id: root

    readonly property var list: [
        { id: "ii",       name: "Illogical Impulse", icon: "dashboard",      blurb: "End-4's baby", desktop: true },
        { id: "waffle",   name: "Waffle",            icon: "grid_view",      blurb: "Winblows", desktop: true },
        { id: "lunae",    name: "Lunae",             icon: "bedtime",        blurb: "Caelestia copycat", desktop: true },
        { id: "akebono",  name: "Akebono",           icon: "sunny",          blurb: "I just wanted KDE inside me", desktop: true, settingsChrome: true },
    ]

    readonly property var ids: list.map(f => f.id)

    function metaFor(id) {
        return list.find(f => f.id === id) ?? ({ id: id, name: id, icon: "tab", blurb: "" });
    }

    function hasDesktop(id) {
        return root.metaFor(id).desktop === true;
    }

    function hasSettingsChrome(id) {
        return root.metaFor(id).settingsChrome === true;
    }
}
