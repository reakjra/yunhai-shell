pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    implicitHeight: contentCol.implicitHeight

    Column {
        id: contentCol
        width: parent.width
        spacing: 8

        Rectangle {
            anchors { left: parent.left; right: parent.right; leftMargin: 12; rightMargin: 12 }
            height: 1
            color: Appearance.colors.colOnLayer1
            opacity: 0.15
        }

        ToolbarTabBar {
            id: tabBar
            anchors.horizontalCenter: parent.horizontalCenter
            tabButtonList: [
                { name: Translation.tr("Pomodoro"), icon: "search_activity" },
                { name: Translation.tr("Stopwatch"), icon: "timer" },
                { name: Translation.tr("Timer"), icon: "hourglass_empty" },
            ]
        }

        SwipeView {
            id: swipeView
            anchors { left: parent.left; right: parent.right; leftMargin: 8; rightMargin: 8 }
            implicitHeight: Math.max(pomodoroCol.implicitHeight, stopwatchCol.implicitHeight)
            currentIndex: tabBar.currentIndex
            onCurrentIndexChanged: tabBar.setCurrentIndex(currentIndex)
            clip: true

            Item {
                implicitHeight: pomodoroCol.implicitHeight

                Column {
                    id: pomodoroCol
                    width: parent.width
                    spacing: 8

                    CircularProgress {
                        anchors.horizontalCenter: parent.horizontalCenter
                        lineWidth: 6
                        implicitSize: 160
                        enableAnimation: true
                        value: TimerService.pomodoroSecondsLeft / TimerService.pomodoroLapDuration

                        Column {
                            anchors.centerIn: parent
                            spacing: 0

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.pixelSize: 32
                                color: Appearance.m3colors.m3onSurface
                                text: {
                                    const mins = Math.floor(TimerService.pomodoroSecondsLeft / 60).toString().padStart(2, '0')
                                    const secs = Math.floor(TimerService.pomodoroSecondsLeft % 60).toString().padStart(2, '0')
                                    return `${mins}:${secs}`
                                }
                            }

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                text: TimerService.pomodoroLongBreak
                                    ? Translation.tr("Long break")
                                    : TimerService.pomodoroBreak
                                        ? Translation.tr("Break")
                                        : Translation.tr("Focus")
                            }
                        }

                        Rectangle {
                            anchors { right: parent.right; bottom: parent.bottom }
                            width: 28; height: 28
                            radius: Appearance.rounding.full
                            color: Appearance.colors.colLayer2

                            StyledText {
                                anchors.centerIn: parent
                                color: Appearance.colors.colOnLayer2
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                text: TimerService.pomodoroCycle + 1
                            }
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        RippleButton {
                            implicitWidth: 80; implicitHeight: 32
                            buttonRadius: Appearance.rounding.small
                            onClicked: TimerService.togglePomodoro()
                            colBackground: TimerService.pomodoroRunning
                                ? Appearance.colors.colSecondaryContainer
                                : Appearance.colors.colPrimary
                            colBackgroundHover: TimerService.pomodoroRunning
                                ? Appearance.colors.colSecondaryContainerHover
                                : Appearance.colors.colPrimaryHover
                            colRipple: TimerService.pomodoroRunning
                                ? Appearance.colors.colSecondaryContainerActive
                                : Appearance.colors.colPrimaryActive

                            contentItem: StyledText {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: TimerService.pomodoroRunning
                                    ? Appearance.colors.colOnSecondaryContainer
                                    : Appearance.colors.colOnPrimary
                                text: TimerService.pomodoroRunning
                                    ? Translation.tr("Pause")
                                    : TimerService.pomodoroSecondsLeft === TimerService.focusTime
                                        ? Translation.tr("Start")
                                        : Translation.tr("Resume")
                            }
                        }

                        RippleButton {
                            implicitWidth: 80; implicitHeight: 32
                            buttonRadius: Appearance.rounding.small
                            onClicked: TimerService.resetPomodoro()
                            enabled: TimerService.pomodoroSecondsLeft < TimerService.pomodoroLapDuration
                                || TimerService.pomodoroCycle > 0
                                || TimerService.pomodoroBreak
                            colBackground: Appearance.colors.colErrorContainer
                            colBackgroundHover: Appearance.colors.colErrorContainerHover
                            colRipple: Appearance.colors.colErrorContainerActive

                            contentItem: StyledText {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnErrorContainer
                                text: Translation.tr("Reset")
                            }
                        }
                    }
                }
            }

            Item {
                implicitHeight: stopwatchCol.implicitHeight

                Column {
                    id: stopwatchCol
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 0

                        StyledText {
                            font.pixelSize: 32
                            color: Appearance.m3colors.m3onSurface
                            text: {
                                const total = Math.floor(TimerService.stopwatchTime) / 100
                                const mins = Math.floor(total / 60).toString().padStart(2, '0')
                                const secs = Math.floor(total % 60).toString().padStart(2, '0')
                                return `${mins}:${secs}`
                            }
                        }
                        StyledText {
                            font.pixelSize: 32
                            color: Appearance.colors.colSubtext
                            text: `.${(Math.floor(TimerService.stopwatchTime) % 100).toString().padStart(2, '0')}`
                        }
                    }

                    Item {
                        anchors { left: parent.left; right: parent.right }
                        height: Math.min(lapsList.contentHeight, 120)
                        visible: TimerService.stopwatchLaps.length > 0
                        clip: true

                        ListView {
                            id: lapsList
                            anchors.fill: parent
                            spacing: 3
                            model: ScriptModel {
                                values: TimerService.stopwatchLaps.map((v, i, arr) => arr[arr.length - 1 - i])
                            }

                            delegate: Rectangle {
                                id: lapItem
                                required property int index
                                required property var modelData
                                width: lapsList.width
                                implicitHeight: lapRow.implicitHeight + 8
                                color: Appearance.colors.colLayer2
                                radius: Appearance.rounding.small

                                RowLayout {
                                    id: lapRow
                                    anchors {
                                        fill: parent
                                        leftMargin: 8; rightMargin: 8
                                        topMargin: 4; bottomMargin: 4
                                    }

                                    StyledText {
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colSubtext
                                        text: `${TimerService.stopwatchLaps.length - lapItem.index}.`
                                    }
                                    StyledText {
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        text: {
                                            const t = lapItem.modelData
                                            const cs = (Math.floor(t) % 100).toString().padStart(2, '0')
                                            const total = Math.floor(t) / 100
                                            const mins = Math.floor(total / 60).toString().padStart(2, '0')
                                            const secs = Math.floor(total % 60).toString().padStart(2, '0')
                                            return `${mins}:${secs}.${cs}`
                                        }
                                    }
                                    Item { Layout.fillWidth: true }
                                    StyledText {
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                        color: Appearance.colors.colPrimary
                                        text: {
                                            const origIdx = TimerService.stopwatchLaps.length - lapItem.index - 1
                                            const prev = origIdx > 0 ? TimerService.stopwatchLaps[origIdx - 1] : 0
                                            const delta = lapItem.modelData - prev
                                            const cs = (Math.floor(delta) % 100).toString().padStart(2, '0')
                                            const total = Math.floor(delta) / 100
                                            const mins = Math.floor(total / 60).toString().padStart(2, '0')
                                            const secs = Math.floor(total % 60).toString().padStart(2, '0')
                                            return `+${mins === "00" ? "" : mins + ":"}${secs}.${cs}`
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        RippleButton {
                            implicitWidth: 80; implicitHeight: 32
                            buttonRadius: Appearance.rounding.small
                            onClicked: TimerService.toggleStopwatch()
                            colBackground: TimerService.stopwatchRunning
                                ? Appearance.colors.colSecondaryContainer
                                : Appearance.colors.colPrimary
                            colBackgroundHover: TimerService.stopwatchRunning
                                ? Appearance.colors.colSecondaryContainerHover
                                : Appearance.colors.colPrimaryHover
                            colRipple: TimerService.stopwatchRunning
                                ? Appearance.colors.colSecondaryContainerActive
                                : Appearance.colors.colPrimaryActive

                            contentItem: StyledText {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: TimerService.stopwatchRunning
                                    ? Appearance.colors.colOnSecondaryContainer
                                    : Appearance.colors.colOnPrimary
                                text: TimerService.stopwatchRunning
                                    ? Translation.tr("Pause")
                                    : TimerService.stopwatchTime === 0
                                        ? Translation.tr("Start")
                                        : Translation.tr("Resume")
                            }
                        }

                        RippleButton {
                            implicitWidth: 80; implicitHeight: 32
                            buttonRadius: Appearance.rounding.small
                            enabled: TimerService.stopwatchTime > 0 || TimerService.stopwatchLaps.length > 0
                            onClicked: {
                                if (TimerService.stopwatchRunning)
                                    TimerService.stopwatchRecordLap()
                                else
                                    TimerService.stopwatchReset()
                            }
                            colBackground: TimerService.stopwatchRunning
                                ? Appearance.colors.colLayer2
                                : Appearance.colors.colErrorContainer
                            colBackgroundHover: TimerService.stopwatchRunning
                                ? Appearance.colors.colLayer2Hover
                                : Appearance.colors.colErrorContainerHover
                            colRipple: TimerService.stopwatchRunning
                                ? Appearance.colors.colLayer2Active
                                : Appearance.colors.colErrorContainerActive

                            contentItem: StyledText {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: TimerService.stopwatchRunning
                                    ? Appearance.colors.colOnLayer2
                                    : Appearance.colors.colOnErrorContainer
                                text: TimerService.stopwatchRunning
                                    ? Translation.tr("Lap")
                                    : Translation.tr("Reset")
                            }
                        }
                    }
                }
            }

            Item {
                implicitHeight: countdownCol.implicitHeight

                Column {
                    id: countdownCol
                    width: parent.width
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 16

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 12

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            visible: !TimerService.countdownRunning && TimerService.countdownSecondsLeft === 0

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colSubtext
                                text: Translation.tr("Quick:")
                            }

                            Row {
                                spacing: 6

                                component PresetButton: RippleButton {
                                    required property int minutes
                                    implicitWidth: 52; implicitHeight: 36
                                    buttonRadius: Appearance.rounding.small
                                    colBackground: Appearance.colors.colLayer2
                                    colBackgroundHover: Appearance.colors.colLayer2Hover
                                    colRipple: Appearance.colors.colLayer2Active

                                    contentItem: StyledText {
                                        anchors.centerIn: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnLayer2
                                        text: `${parent.minutes}m`
                                    }

                                    onClicked: TimerService.startCountdown(minutes * 60)
                                }

                                PresetButton { minutes: 1 }
                                PresetButton { minutes: 5 }
                                PresetButton { minutes: 10 }
                                PresetButton { minutes: 25 }
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            visible: !TimerService.countdownRunning && TimerService.countdownSecondsLeft === 0

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colSubtext
                                text: Translation.tr("Custom:")
                            }

                            Row {
                                spacing: 4

                                component TimeInput: TextField {
                                    id: timeField
                                    required property int maxValue
                                    required property string label
                                    property bool isValid: text.length === 0 || (!isNaN(parseInt(text)) && parseInt(text) >= 0 && parseInt(text) <= maxValue)
                                    property int value: text.length > 0 ? parseInt(text) || 0 : 0

                                    width: 50
                                    height: 36
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    color: isValid ? Appearance.colors.colOnLayer2 : Appearance.colors.colError
                                    placeholderText: "00"
                                    placeholderTextColor: Appearance.colors.colSubtext
                                    background: Rectangle {
                                        radius: Appearance.rounding.small
                                        color: Appearance.colors.colLayer2
                                    }
                                    validator: IntValidator { bottom: 0; top: maxValue }
                                    selectByMouse: true

                                    Keys.onReturnPressed: event => startTimerIfValid()
                                    Keys.onEnterPressed: event => startTimerIfValid()

                                    function startTimerIfValid() {
                                        if (minInput.isValid && secInput.isValid && (minInput.value > 0 || secInput.value > 0)) {
                                            TimerService.startCountdown(minInput.value * 60 + secInput.value)
                                            minInput.text = ""
                                            secInput.text = ""
                                        }
                                    }
                                }

                                TimeInput {
                                    id: minInput
                                    maxValue: 999
                                    label: "min"
                                }

                                StyledText {
                                    anchors.verticalCenter: parent.verticalCenter
                                    font.pixelSize: Appearance.font.pixelSize.large
                                    text: ":"
                                    color: Appearance.colors.colSubtext
                                }

                                TimeInput {
                                    id: secInput
                                    maxValue: 59
                                    label: "sec"
                                }

                                RippleButton {
                                    implicitWidth: 48; implicitHeight: 36
                                    buttonRadius: Appearance.rounding.small
                                    enabled: minInput.isValid && secInput.isValid && (minInput.value > 0 || secInput.value > 0)
                                    colBackground: Appearance.colors.colPrimary
                                    colBackgroundHover: Appearance.colors.colPrimaryHover
                                    colRipple: Appearance.colors.colPrimaryActive
                                    onClicked: {
                                        TimerService.startCountdown(minInput.value * 60 + secInput.value)
                                        minInput.text = ""
                                        secInput.text = ""
                                    }

                                    contentItem: Item {
                                        anchors.fill: parent
                                        MaterialSymbol {
                                            anchors.centerIn: parent
                                            text: "play_arrow"
                                            iconSize: 22
                                            fill: 1
                                            color: Appearance.colors.colOnPrimary
                                        }
                                    }
                                }
                            }
                        }

                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            visible: TimerService.countdownRunning || TimerService.countdownSecondsLeft > 0

                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.pixelSize: 40
                                color: TimerService.countdownRunning ? Appearance.m3colors.m3onSurface : Appearance.colors.colSubtext
                                text: {
                                    const mins = Math.floor(TimerService.countdownSecondsLeft / 60).toString().padStart(2, '0')
                                    const secs = Math.floor(TimerService.countdownSecondsLeft % 60).toString().padStart(2, '0')
                                    return `${mins}:${secs}`
                                }
                            }

                            StyledProgressBar {
                                anchors.horizontalCenter: parent.horizontalCenter
                                valueBarWidth: 180
                                valueBarHeight: 4
                                valueBarGap: 4
                                value: TimerService.countdownDuration > 0 
                                    ? TimerService.countdownSecondsLeft / TimerService.countdownDuration 
                                    : 0
                                highlightColor: TimerService.countdownRunning 
                                    ? Appearance.colors.colPrimary 
                                    : Appearance.colors.colSubtext
                                trackColor: Appearance.colors.colLayer2
                            }
                        }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10
                        visible: TimerService.countdownRunning || TimerService.countdownSecondsLeft > 0

                        RippleButton {
                            implicitWidth: 90; implicitHeight: 36
                            buttonRadius: Appearance.rounding.small
                            onClicked: TimerService.toggleCountdown()
                            colBackground: TimerService.countdownRunning
                                ? Appearance.colors.colSecondaryContainer
                                : Appearance.colors.colPrimary
                            colBackgroundHover: TimerService.countdownRunning
                                ? Appearance.colors.colSecondaryContainerHover
                                : Appearance.colors.colPrimaryHover
                            colRipple: TimerService.countdownRunning
                                ? Appearance.colors.colSecondaryContainerActive
                                : Appearance.colors.colPrimaryActive

                            contentItem: StyledText {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: TimerService.countdownRunning
                                    ? Appearance.colors.colOnSecondaryContainer
                                    : Appearance.colors.colOnPrimary
                                text: TimerService.countdownRunning ? Translation.tr("Pause") : Translation.tr("Resume")
                            }
                        }

                        RippleButton {
                            implicitWidth: 90; implicitHeight: 36
                            buttonRadius: Appearance.rounding.small
                            onClicked: TimerService.resetCountdown()
                            colBackground: Appearance.colors.colErrorContainer
                            colBackgroundHover: Appearance.colors.colErrorContainerHover
                            colRipple: Appearance.colors.colErrorContainerActive

                            contentItem: StyledText {
                                anchors.centerIn: parent
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: Appearance.font.pixelSize.normal
                                color: Appearance.colors.colOnErrorContainer
                                text: Translation.tr("Reset")
                            }
                        }
                    }
                }
            }
        }

        Item { width: 1; height: 4 }
    }
}
