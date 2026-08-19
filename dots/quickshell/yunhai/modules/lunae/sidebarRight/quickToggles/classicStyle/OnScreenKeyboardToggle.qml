import qs
import qs.services
import qs.modules.common.widgets

QuickToggleButton {
    toggled: GlobalStates.oskOpen
    buttonIcon: toggled ? "keyboard_hide" : "keyboard"

    altAction: () => {}

    onClicked: {
        GlobalStates.oskOpen = !GlobalStates.oskOpen
    }
    StyledToolTip {
        text: Translation.tr("On-screen keyboard")
    }
}
