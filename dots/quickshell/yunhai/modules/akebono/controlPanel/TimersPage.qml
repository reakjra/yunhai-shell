import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono.shelf.widgets.controlPanel

Item {
    id: root

    property bool durationsDialogOpen: false
    property bool countdownDialogOpen: false
    readonly property var countdownPresets: [5, 10, 15, 30]
    readonly property var laps: TimerService.stopwatchLaps.map((time, i, all) => ({
                number: i + 1,
                time: time,
                split: time - (i > 0 ? all[i - 1] : 0)
            })).reverse()

    component TimerButton: ActionButton {
        size: Appearance.font.pixelSize.huge * 1.7
    }

    component PlayPauseButton: TimerButton {
        property bool running: false
        filled: true
        icon: running ? "pause" : "play_arrow"
        tooltip: running ? Translation.tr("Pause") : Translation.tr("Start")
    }

    StyledFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.implicitHeight
        clip: true

        ColumnLayout {
            id: column
            width: flickable.width
            spacing: 16

            SectionHeader {
                title: Translation.tr("Pomodoro")
            }

            TimerCard {
                time: TimerService.formatClock(TimerService.pomodoroSecondsLeft)
                caption: Translation.tr("%1, cycle %2 of %3")
                    .arg(TimerService.pomodoroLongBreak ? Translation.tr("Long break") : TimerService.pomodoroBreak ? Translation.tr("Break") : Translation.tr("Focus"))
                    .arg(TimerService.pomodoroCycle + 1)
                    .arg(TimerService.cyclesBeforeLongBreak)
                progress: 1 - TimerService.pomodoroSecondsLeft / TimerService.pomodoroLapDuration

                actions: [
                    PlayPauseButton {
                        running: TimerService.pomodoroRunning
                        onClicked: TimerService.togglePomodoro()
                    },
                    TimerButton {
                        icon: "restart_alt"
                        tooltip: Translation.tr("Reset")
                        onClicked: TimerService.resetPomodoro()
                    }
                ]

                footer: ListRow {
                    Layout.fillWidth: true
                    icon: "tune"
                    title: Translation.tr("Durations")
                    subtitle: Translation.tr("%1 / %2 / %3 min, %4 cycles")
                        .arg(TimerService.focusTime / 60)
                        .arg(TimerService.breakTime / 60)
                        .arg(TimerService.longBreakTime / 60)
                        .arg(TimerService.cyclesBeforeLongBreak)
                    trailingIcon: "edit"
                    onClicked: root.durationsDialogOpen = true
                }
            }

            SectionHeader {
                title: Translation.tr("Countdown")
            }

            TimerCard {
                time: TimerService.formatClock(TimerService.countdownSecondsLeft)
                caption: TimerService.countdownDuration > 0 ? Translation.tr("of %1").arg(TimerService.formatClock(TimerService.countdownDuration)) : Translation.tr("Pick a duration below")
                progress: TimerService.countdownDuration > 0 ? 1 - TimerService.countdownSecondsLeft / TimerService.countdownDuration : -1

                actions: [
                    PlayPauseButton {
                        enabled: TimerService.countdownSecondsLeft > 0
                        running: TimerService.countdownRunning
                        onClicked: TimerService.toggleCountdown()
                    },
                    TimerButton {
                        enabled: TimerService.countdownDuration > 0
                        icon: "restart_alt"
                        tooltip: Translation.tr("Reset")
                        onClicked: TimerService.resetCountdown()
                    }
                ]

                footer: Flow {
                    Layout.fillWidth: true
                    Layout.margins: 6
                    spacing: 6

                    Repeater {
                        model: root.countdownPresets
                        delegate: Pill {
                            required property int modelData
                            clickable: true
                            text: Translation.tr("%1 min").arg(modelData)
                            onClicked: TimerService.startCountdown(modelData * 60)
                        }
                    }
                    Pill {
                        clickable: true
                        icon: "add"
                        text: Translation.tr("Custom")
                        onClicked: root.countdownDialogOpen = true
                    }
                }
            }

            SectionHeader {
                title: Translation.tr("Stopwatch")
            }

            TimerCard {
                time: TimerService.formatStopwatch(TimerService.stopwatchTime)

                actions: [
                    PlayPauseButton {
                        running: TimerService.stopwatchRunning
                        onClicked: TimerService.toggleStopwatch()
                    },
                    TimerButton {
                        enabled: TimerService.stopwatchRunning
                        icon: "flag"
                        tooltip: Translation.tr("Lap")
                        onClicked: TimerService.stopwatchRecordLap()
                    },
                    TimerButton {
                        enabled: TimerService.stopwatchTime > 0 || root.laps.length > 0
                        icon: "restart_alt"
                        tooltip: Translation.tr("Reset")
                        onClicked: TimerService.stopwatchReset()
                    }
                ]
            }

            ListCard {
                Layout.bottomMargin: 8
                values: root.laps
                emptyText: Translation.tr("No laps yet")
                delegate: ListRow {
                    required property var modelData
                    Layout.fillWidth: true
                    icon: "flag"
                    title: Translation.tr("Lap %1").arg(modelData.number)
                    subtitle: TimerService.formatStopwatch(modelData.time)
                    trailingText: TimerService.formatStopwatch(modelData.split)
                }
            }
        }
    }

    Item {
        parent: root.Window.window?.contentItem ?? root
        anchors.fill: parent
        z: 1

        WindowDialogLoader {
            shown: root.durationsDialogOpen
            onDismissed: root.durationsDialogOpen = false
            dialog: PomodoroDurationsDialog {}
        }

        WindowDialogLoader {
            shown: root.countdownDialogOpen
            onDismissed: root.countdownDialogOpen = false
            dialog: CountdownDialog {}
        }
    }
}
