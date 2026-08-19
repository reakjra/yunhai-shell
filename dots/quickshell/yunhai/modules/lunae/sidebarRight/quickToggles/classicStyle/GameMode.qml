import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import Quickshell.Io

QuickToggleButton {
    id: root
    buttonIcon: "gamepad"
    toggled: toggled

    altAction: () => {}

    onClicked: {
        root.toggled = !root.toggled
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
            
            let cmd = "hyprctl --batch \""
            const entries = Object.entries(settings)
            for (let i = 0; i < entries.length; i++) {
                const [key, value] = entries[i]
                cmd += `keyword ${key} ${value}`
                if (i < entries.length - 1) cmd += "; "
            }
            cmd += "\""
            Quickshell.execDetached(["bash", "-c", cmd])
        } else {
            Quickshell.execDetached(["hyprctl", "reload"])
        }
    }
    Process {
        id: fetchActiveState
        running: true
        command: ["bash", "-c", `test "$(hyprctl getoption animations:enabled -j | jq ".int")" -ne 0`]
        onExited: (exitCode, exitStatus) => {
            root.toggled = exitCode !== 0
        }
    }
    StyledToolTip {
        text: Translation.tr("Game mode")
    }
}
