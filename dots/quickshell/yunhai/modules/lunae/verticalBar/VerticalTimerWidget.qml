import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    readonly property bool pRunning: TimerService.pomodoroRunning ?? false
    readonly property bool sRunning: TimerService.stopwatchRunning ?? false
    readonly property bool cRunning: TimerService.countdownRunning ?? false
    readonly property bool hasStop: TimerService.stopwatchTime > 0
    readonly property bool hasPomo: TimerService.pomodoroSecondsLeft > 0 && (TimerService.pomodoroSecondsLeft < TimerService.pomodoroLapDuration || pRunning)
    readonly property bool hasCountdown: TimerService.countdownSecondsLeft > 0

    property bool showPomodoro: Config.options.bar.timers.showPomodoro
    property bool showStopwatch: Config.options.bar.timers.showStopwatch
    property bool showCountdown: Config.options.bar.timers.showCountdown ?? true

    implicitWidth: Appearance.sizes.verticalBarWidth
    implicitHeight: columnLayout.implicitHeight + columnLayout.spacing * 4

    property bool compVisible: ((hasStop || sRunning) && root.showStopwatch) || ((pRunning || hasPomo) && root.showPomodoro) || ((cRunning || hasCountdown) && root.showCountdown)

    onCompVisibleChanged: rootItem.toggleVisible(compVisible)
    Component.onCompleted: rootItem.toggleVisible(compVisible)

    Behavior on implicitWidth {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    function formatTime(time) {
        const sec = Math.floor(time/100)
        return (sec%60).toString().padStart(2,'0') + "\n" +
        (time%100).toString().padStart(2,'0')
    }

    ColumnLayout {
        id: columnLayout
        anchors.centerIn: parent
        spacing: 4

        Loader {
            active: hasStop && showStopwatch
            visible: active
            Layout.alignment: Qt.AlignHCenter
            sourceComponent: ColumnLayout {
                MaterialSymbol {
                    text: root.sRunning ? "timer" : "timer_pause"
                    color: Appearance.colors.colPrimary
                    iconSize: Appearance.font.pixelSize.large
                }

                StyledText {
                    Layout.preferredWidth: 10
                    text: formatTime(TimerService.stopwatchTime)
                    color: Appearance.colors.colPrimary
                }
            }  
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    TimerService.toggleStopwatch()
                }
            } 
        }

        Item {
            visible: hasStop && hasPomo
            Layout.preferredHeight: hasStop && hasPomo ? 2 : 0
        }

        Loader {
            active: hasPomo && showPomodoro
            visible: active
            Layout.preferredHeight: 50
            Layout.bottomMargin: 10
            Layout.alignment: Qt.AlignHCenter
            Layout.leftMargin: 2
            
            sourceComponent: ColumnLayout {
                MaterialSymbol {
                    text: root.pRunning ? "search_activity" : "pause_circle"
                    color: Appearance.colors.colPrimary
                    iconSize: Appearance.font.pixelSize.large
                }

                StyledText {
                    text: {
                        const t = TimerService.pomodoroSecondsLeft
                        return Math.floor(t/60).toString().padStart(2,'0') + "\n" + (t%60).toString().padStart(2,'0')
                    }
                    color: Appearance.colors.colPrimary
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    TimerService.togglePomodoro()
                }
            } 
        }

        Item {
            visible: (hasStop || sRunning) && hasCountdown || hasPomo && hasCountdown
            Layout.preferredHeight: visible ? 2 : 0
        }

        Loader {
            active: hasCountdown && showCountdown
            visible: active
            Layout.preferredHeight: 50
            Layout.bottomMargin: 10
            Layout.alignment: Qt.AlignHCenter
            Layout.leftMargin: 2
            
            sourceComponent: ColumnLayout {
                MaterialSymbol {
                    text: root.cRunning ? "hourglass_empty" : "hourglass_disabled"
                    color: Appearance.colors.colPrimary
                    iconSize: Appearance.font.pixelSize.large
                }

                StyledText {
                    text: {
                        const t = TimerService.countdownSecondsLeft
                        return Math.floor(t/60).toString().padStart(2,'0') + "\n" + (t%60).toString().padStart(2,'0')
                    }
                    color: Appearance.colors.colPrimary
                }
            }
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    TimerService.toggleCountdown()
                }
            } 
        }

    }
}