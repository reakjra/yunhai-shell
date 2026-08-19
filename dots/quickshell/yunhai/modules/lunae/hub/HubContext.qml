pragma Singleton
pragma ComponentBehavior: Bound
import Quickshell
import qs.modules.common

Singleton {
    id: root

    readonly property var tabRegistry: ({
        "dash":    { icon: "dashboard",   label: "Dashboard" },
        "media":   { icon: "queue_music", label: "Media" },
        "weather": { icon: "cloud",       label: "Weather" },
    })

    readonly property list<var> availableTabs: {
        if (!Config?.ready) return []

        let result = []
        const configTabs = Config.options.lunae?.hub?.tabs ?? ["dash", "media", "weather"]

        for (let i = 0; i < configTabs.length; i++) {
            const id = configTabs[i]
            if (tabRegistry.hasOwnProperty(id)) {
                result.push({
                    identifier: id,
                    icon: tabRegistry[id].icon,
                    label: tabRegistry[id].label,
                })
            }
        }

        return result
    }

    readonly property int tabCount: availableTabs.length

    function tabIndex(identifier: string): int {
        for (let i = 0; i < availableTabs.length; i++) {
            if (availableTabs[i].identifier === identifier) return i
        }
        return -1
    }
}
