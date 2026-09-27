pragma Singleton

import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    // keyed by monitor name so callers can use screenName without resolving an HyprlandMonitor
    readonly property var byMonitor: {
        const out = {};
        for (const ws of Hyprland.workspaces.values) {
            if (!ws.active || !ws.monitor)
                continue;
            if (ws.toplevels.values.some(t => t.wayland?.fullscreen))
                out[ws.monitor.name] = true;
        }
        return out;
    }

    function active(screenName: string): bool {
        return root.byMonitor[screenName] === true;
    }
}
