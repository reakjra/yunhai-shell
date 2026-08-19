import qs.modules.common.widgets
import qs.services

QuickToggleButton {
    toggled: !Audio.sink?.audio?.muted
    buttonIcon: Audio.sink?.audio?.muted ? "volume_off" : "volume_up"

    altAction: () => {}

    onClicked: Audio.toggleMute()

    StyledToolTip {
        text: Translation.tr("Audio output")
    }
}
