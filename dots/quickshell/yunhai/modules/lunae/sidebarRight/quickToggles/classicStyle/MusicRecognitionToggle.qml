import qs
import qs.services
import qs.modules.common.widgets

QuickToggleButton {
    toggled: SongRec.running
    property bool sourceIsMonitor: SongRec.monitorSource === SongRec.MonitorSource.Monitor
    buttonIcon: toggled ? "music_cast" : (sourceIsMonitor ? "music_note" : "frame_person_mic")

    altAction: () => {
        SongRec.toggleMonitorSource()
    }

    onClicked: {
        SongRec.toggleRunning()
    }
    StyledToolTip {
        text: Translation.tr("Recognize music")
    }
}
