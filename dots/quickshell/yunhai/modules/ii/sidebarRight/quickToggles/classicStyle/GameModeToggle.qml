import qs.modules.common
import qs.modules.common.widgets
import qs.services

QuickToggleButton {
    buttonIcon: "gamepad"
    toggled: GameMode.active

    onClicked: GameMode.toggle()

    StyledToolTip {
        text: Translation.tr("Game mode")
    }
}
