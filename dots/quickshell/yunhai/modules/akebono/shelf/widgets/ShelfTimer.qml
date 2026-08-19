import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono
import qs.services
import QtQuick

Item {
    id: root
    property real barHeight: 54
    readonly property int segIconSize: Math.round(barHeight * 0.36)

    readonly property bool pRunning: TimerService.pomodoroRunning ?? false
    readonly property bool sRunning: TimerService.stopwatchRunning ?? false
    readonly property bool cRunning: TimerService.countdownRunning ?? false
    readonly property bool hasStop: TimerService.stopwatchTime > 0
    readonly property bool hasPomo: TimerService.pomodoroSecondsLeft > 0 && (TimerService.pomodoroSecondsLeft < TimerService.pomodoroLapDuration || pRunning)
    readonly property bool hasCountdown: TimerService.countdownSecondsLeft > 0

    readonly property bool showStop: (hasStop || sRunning) && Config.options.bar.timers.showStopwatch
    readonly property bool showPomo: (pRunning || hasPomo) && Config.options.bar.timers.showPomodoro
    readonly property bool showCount: (cRunning || hasCountdown) && (Config.options.bar.timers.showCountdown ?? true)

    readonly property bool shelfEmpty: !(showStop || showPomo || showCount)

    implicitWidth: pill.implicitWidth
    implicitHeight: barHeight * 0.7

    function fmtClock(totalSec) {
        return Math.floor(totalSec / 60).toString().padStart(2, "0") + ":" + (totalSec % 60).toString().padStart(2, "0");
    }
    function fmtStopwatch(t) {
        const sec = Math.floor(t / 100);
        return Math.floor(sec / 60).toString().padStart(2, "0") + ":" + (sec % 60).toString().padStart(2, "0") + "." + (t % 100).toString().padStart(2, "0");
    }

    Squircle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: segRow.implicitWidth + 18
        implicitHeight: root.barHeight * 0.7
        radius: height / 2
        color: AkebonoAppearance.shelfPillColor

        Row {
            id: segRow
            anchors.centerIn: parent
            spacing: 10

            Seg {
                visible: root.showStop
                icon: root.sRunning ? "timer" : "timer_pause"
                label: root.fmtStopwatch(TimerService.stopwatchTime)
                maxLabel: "00:00.00"
                running: root.sRunning
                iconSize: root.segIconSize
                onToggle: TimerService.toggleStopwatch()
            }
            Seg {
                visible: root.showPomo
                icon: root.pRunning ? "search_activity" : "pause_circle"
                label: root.fmtClock(TimerService.pomodoroSecondsLeft)
                running: root.pRunning
                iconSize: root.segIconSize
                onToggle: TimerService.togglePomodoro()
            }
            Seg {
                visible: root.showCount
                icon: root.cRunning ? "hourglass_empty" : "hourglass_disabled"
                label: root.fmtClock(TimerService.countdownSecondsLeft)
                running: root.cRunning
                iconSize: root.segIconSize
                onToggle: TimerService.toggleCountdown()
            }
        }
    }

    component Seg: Item {
        id: seg
        property string icon: ""
        property string label: ""
        property string maxLabel: "00:00"
        property bool running: false
        property int iconSize: 18
        signal toggle()

        implicitWidth: segContent.implicitWidth
        implicitHeight: segContent.implicitHeight
        visible: false

        TextMetrics {
            id: tm
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.DemiBold
            text: seg.maxLabel
        }

        Row {
            id: segContent
            anchors.centerIn: parent
            spacing: 4

            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                text: seg.icon
                iconSize: seg.iconSize
                fill: 1
                color: seg.running ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                width: tm.width
                text: seg.label
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.DemiBold
                color: seg.running ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: seg.toggle()
        }
    }
}
