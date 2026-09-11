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
    readonly property bool macColors: cfg.macColors

    function run(action) {
        Quickshell.execDetached(["bash", root.script, action, root.barFont, root.glyphs ? "glyphs" : "semaphore", root.macColors ? "mac" : "themed"]);
    }

    onDesiredChanged: run(desired ? "load" : "disable")
    onBarFontChanged: if (desired) fontApply.restart()
    onGlyphsChanged: if (desired) run("reload")
    onMacColorsChanged: if (desired) run("reload")
    Component.onCompleted: if (desired) run("load")

    Timer {
        id: fontApply
        interval: 600
        onTriggered: root.run("font")
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                root.run(root.desired ? "style" : "disable");
        }
    }
}
