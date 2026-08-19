import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell

QuickToggleButton {
    id: root
    property bool _holdFired: false

    toggled: Persistent.states.screenRecord.active
    buttonIcon: "screen_record"

    altAction: () => {
        root._holdFired = true
        GlobalStates.sidebarRightOpen = false
        GlobalStates.sidebarToggleOpen = false
        regionDelay.start()
    }

    onClicked: {
        if (_holdFired) {
            _holdFired = false
            return
        }
        Quickshell.execDetached([Directories.recordScriptPath, "--fullscreen"])
    }

    Timer {
        id: regionDelay
        interval: 300
        onTriggered: Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "record"])
    }

    StyledToolTip {
        text: Persistent.states.screenRecord.active
            ? Translation.tr("Recording... %1\nClick to stop").arg(root.formatTime(Persistent.states.screenRecord.seconds))
            : Translation.tr("Record | Hold for region")
    }

    function formatTime(s) {
        const m = Math.floor(s / 60)
        const sec = s % 60
        return `${m}:${String(sec).padStart(2, '0')}`
    }
}
