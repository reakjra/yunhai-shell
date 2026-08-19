import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: countdownTab
    Layout.fillWidth: true
    Layout.fillHeight: true

    Item {
        anchors {
            fill: parent
            topMargin: 8
            leftMargin: 16
            rightMargin: 16
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16

            // Quick presets
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                visible: !TimerService.countdownRunning && TimerService.countdownSecondsLeft === 0

                component PresetButton: RippleButton {
                    required property int minutes
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 40
                    buttonRadius: Appearance.rounding.small
                    colBackground: Appearance.colors.colLayer2
                    colBackgroundHover: Appearance.colors.colLayer2Hover
                    colRipple: Appearance.colors.colLayer2Active

                    contentItem: StyledText {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Appearance.font.pixelSize.normal
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

            // Custom input
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8
                visible: !TimerService.countdownRunning && TimerService.countdownSecondsLeft === 0

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colSubtext
                    text: Translation.tr("Custom:")
                }

                component TimeInput: TextField {
                    id: timeField
                    required property int maxValue
                    property bool isValid: text.length === 0 || (!isNaN(parseInt(text)) && parseInt(text) >= 0 && parseInt(text) <= maxValue)
                    property int value: text.length > 0 ? parseInt(text) || 0 : 0

                    Layout.preferredWidth: 50
                    Layout.preferredHeight: 36
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
                }

                StyledText {
                    font.pixelSize: Appearance.font.pixelSize.large
                    text: ":"
                    color: Appearance.colors.colSubtext
                }

                TimeInput {
                    id: secInput
                    maxValue: 59
                }

                RippleButton {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 36
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

            // Timer display
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12
                visible: TimerService.countdownRunning || TimerService.countdownSecondsLeft > 0

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    font.pixelSize: 48
                    color: TimerService.countdownRunning ? Appearance.m3colors.m3onSurface : Appearance.colors.colSubtext
                    text: {
                        const mins = Math.floor(TimerService.countdownSecondsLeft / 60).toString().padStart(2, '0')
                        const secs = Math.floor(TimerService.countdownSecondsLeft % 60).toString().padStart(2, '0')
                        return `${mins}:${secs}`
                    }
                }

                StyledProgressBar {
                    Layout.alignment: Qt.AlignHCenter
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

            // Control buttons
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 10
                visible: TimerService.countdownRunning || TimerService.countdownSecondsLeft > 0

                RippleButton {
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 40
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
                        font.pixelSize: Appearance.font.pixelSize.larger
                        color: TimerService.countdownRunning
                            ? Appearance.colors.colOnSecondaryContainer
                            : Appearance.colors.colOnPrimary
                        text: TimerService.countdownRunning ? Translation.tr("Pause") : Translation.tr("Resume")
                    }
                }

                RippleButton {
                    Layout.preferredWidth: 90
                    Layout.preferredHeight: 40
                    buttonRadius: Appearance.rounding.small
                    onClicked: TimerService.resetCountdown()
                    colBackground: Appearance.colors.colErrorContainer
                    colBackgroundHover: Appearance.colors.colErrorContainerHover
                    colRipple: Appearance.colors.colErrorContainerActive

                    contentItem: StyledText {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnErrorContainer
                        text: Translation.tr("Reset")
                    }
                }
            }
        }
    }
}
