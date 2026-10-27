import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.common

Scope {
    id: root
    readonly property string script: Quickshell.shellPath("scripts/desktop/hyprbars.sh")
    readonly property var cfg: Config.options.hyprbars
    readonly property bool desired: cfg.enable
    readonly property string barFont: cfg.font || Appearance.font.family.title
    readonly property bool glyphs: cfg.glyphs
    readonly property int buttonSize: glyphs ? cfg.glyphSize : cfg.buttonSize
    readonly property string configKey: [barFont, glyphs, cfg.buttonColors, cfg.barColor, cfg.height, cfg.textSize, buttonSize].join()

    function run(action) {
        Quickshell.execDetached(["bash", root.script, action, root.barFont, root.glyphs ? "glyphs" : "semaphore", cfg.buttonColors, cfg.height, cfg.textSize, root.buttonSize, cfg.barColor]);
    }

    onDesiredChanged: run(desired ? "load" : "disable")
    onConfigKeyChanged: if (desired) applyTimer.restart()
    Component.onCompleted: if (desired) run("load")

    Timer {
        id: applyTimer
        interval: 600
        onTriggered: root.run("apply")
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded" && !root.desired)
                root.run("disable");
        }
    }
}
