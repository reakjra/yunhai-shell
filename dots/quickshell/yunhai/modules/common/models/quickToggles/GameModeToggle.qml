import QtQuick
import Quickshell.Io
import qs
import qs.services
import qs.modules.common

QuickToggleModel {
    id: root
    name: Translation.tr("Game mode")
    toggled: toggled
    icon: "gamepad"

    mainAction: () => {
        root.toggled = !root.toggled;
        if (root.toggled) {
            const opts = Config.options.gameMode
            const settings = {}
            if (opts.disableAnimations) settings["animations:enabled"] = 0
            if (opts.disableShadows) settings["decoration:shadow:enabled"] = 0
            if (opts.disableBlur) settings["decoration:blur:enabled"] = 0
            if (opts.removeGaps) {
                settings["general:gaps_in"] = 0
                settings["general:gaps_out"] = 0
            }
            if (opts.setBorderSize) settings["general:border_size"] = opts.borderSize
            if (opts.disableRounding) settings["decoration:rounding"] = 0
            if (opts.enableTearing) settings["general:allow_tearing"] = 1
            
            HyprlandConfig.setMany(settings)
        } else {
            const resetKeys = []
            const opts = Config.options.gameMode
            if (opts.disableAnimations) resetKeys.push("animations:enabled")
            if (opts.disableShadows) resetKeys.push("decoration:shadow:enabled")
            if (opts.disableBlur) resetKeys.push("decoration:blur:enabled")
            if (opts.removeGaps) {
                resetKeys.push("general:gaps_in")
                resetKeys.push("general:gaps_out")
            }
            if (opts.setBorderSize) resetKeys.push("general:border_size")
            if (opts.disableRounding) resetKeys.push("decoration:rounding")
            if (opts.enableTearing) resetKeys.push("general:allow_tearing")
            HyprlandConfig.resetMany(resetKeys)
        }
    }
    Process {
        id: fetchActiveState
        running: true
        command: ["bash", "-c", `test "$(hyprctl getoption animations:enabled -j | jq ".int")" -ne 0`]
        onExited: (exitCode, exitStatus) => {
            root.toggled = exitCode !== 0; // Inverted because enabled = nonzero exit
        }
    }
    hasMenu: true
    tooltipText: Translation.tr("Game mode | Right-click to configure")
}
