import qs
import qs.services
import qs.modules.common.widgets
import QtQuick
import Quickshell

QuickToggleButton {
    toggled: false
    buttonIcon: "screenshot_region"

    altAction: () => {}

    onClicked: {
        GlobalStates.sidebarRightOpen = false
        GlobalStates.sidebarToggleOpen = false
        snipDelay.start()
    }

    Timer {
        id: snipDelay
        interval: 300
        onTriggered: Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "screenshot"])
    }

    StyledToolTip {
        text: Translation.tr("Screenshot region")
    }
}
