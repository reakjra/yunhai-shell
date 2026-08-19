import qs.modules.common.widgets
import qs.services

QuickToggleButton {
    toggled: !Audio.source?.audio?.muted
    buttonIcon: Audio.source?.audio?.muted ? "mic_off" : "mic"

    altAction: () => {}

    onClicked: Audio.toggleMicMute()

    StyledToolTip {
        text: Translation.tr("Microphone")
    }
}
