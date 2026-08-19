pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Scope {
    id: root

    GlobalShortcut {
        name: "searchToggle"
        description: "Toggle the Akebono runner"
        onPressed: GlobalStates.desktopRunnerOpen = !GlobalStates.desktopRunnerOpen
    }
    GlobalShortcut {
        name: "searchToggleRelease"
        description: "Toggle the Akebono runner on release (tap Super)"
        onPressed: GlobalStates.superReleaseMightTrigger = true
        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true;
                return;
            }
            GlobalStates.desktopRunnerOpen = !GlobalStates.desktopRunnerOpen;
        }
    }
    GlobalShortcut {
        name: "searchToggleReleaseInterrupt"
        description: "Interrupts the tap-Super search toggle"
        onPressed: GlobalStates.superReleaseMightTrigger = false
    }
    GlobalShortcut {
        name: "overviewClipboardToggle"
        description: "Open the Akebono runner in clipboard mode"
        onPressed: {
            GlobalStates.desktopRunnerPendingQuery = Config.options.search.prefix.clipboard;
            GlobalStates.desktopRunnerOpen = true;
        }
    }
    GlobalShortcut {
        name: "overviewEmojiToggle"
        description: "Open the Akebono glyph picker, or the runner in emoji mode"
        onPressed: {
            if (Config.options.akebono.runner.glyphPicker) {
                GlobalStates.desktopGlyphPickerOpen = !GlobalStates.desktopGlyphPickerOpen;
                return;
            }
            GlobalStates.desktopRunnerPendingQuery = Config.options.search.prefix.emojis;
            GlobalStates.desktopRunnerOpen = true;
        }
    }

    IpcHandler {
        target: "akebonoRunner"
        function toggle(): void { GlobalStates.desktopRunnerOpen = !GlobalStates.desktopRunnerOpen }
        function open(): void { GlobalStates.desktopRunnerOpen = true }
        function close(): void { GlobalStates.desktopRunnerOpen = false }
    }
}
