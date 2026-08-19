import qs.modules.common
import qs.services
import qs.modules.akebono.shelf.widgets
import Quickshell

ShelfPrivacyPill {
    id: root
    active: Persistent.states.screenRecord.active
    icon: "screen_record"
    label: root.fmt(Persistent.states.screenRecord.seconds)
    tooltipText: Translation.tr("Recording • %1 • click to stop").arg(root.label)
    interactive: true
    onClicked: Quickshell.execDetached([Directories.recordScriptPath])

    function fmt(s) {
        const m = Math.floor(s / 60);
        const sec = s % 60;
        return String(m).padStart(2, "0") + ":" + String(sec).padStart(2, "0");
    }
}
