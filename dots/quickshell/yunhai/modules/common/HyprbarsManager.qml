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
    readonly property string buttonColors: cfg.buttonColors
    readonly property int buttonSize: glyphs ? cfg.glyphSize : cfg.buttonSize
    readonly property string layoutKey: [barFont, cfg.height, cfg.textSize, cfg.buttonSize, cfg.glyphSize].join()

    function run(action) {
        Quickshell.execDetached(["bash", root.script, action, root.barFont, root.glyphs ? "glyphs" : "semaphore", root.buttonColors, cfg.height, cfg.textSize, root.buttonSize]);
    }

    onDesiredChanged: run(desired ? "load" : "disable")
    onLayoutKeyChanged: if (desired) layoutApply.restart()
    onGlyphsChanged: if (desired) run("reload")
    onButtonColorsChanged: if (desired) run("reload")
    Component.onCompleted: if (desired) run("load")

    Timer {
        id: layoutApply
        interval: 600
        onTriggered: root.run("layout")
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                root.run(root.desired ? "style" : "disable");
        }
    }
}
