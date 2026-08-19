import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.modules.ii.verticalBar as Vertical
import qs.modules.ii.bar.weather

Item {
    id: rootItem

    property int barSection // 0: left, 1: center, 2: right
    property var list
    required property var modelData
    required property int index
    property var originalIndex: index
    property bool vertical: false

    readonly property int backgroundStyle: Config.options.bar.componentBackgroundStyle

    implicitWidth: wrapper.implicitWidth
    implicitHeight: wrapper.implicitHeight

    function toggleVisible(visibility) {
        visible = visibility
        if (barSection == 0) Config.options.bar.layouts.left[originalIndex].visible = visibility
        else if (barSection == 1) Config.options.bar.layouts.center[originalIndex].visible = visibility
        else if (barSection == 2) Config.options.bar.layouts.right[originalIndex].visible = visibility
    }

    property var compMap: ({ // [horizontal, vertical]
        "workspaces": [workspaceComp,workspaceComp],
        "music_player": [musicPlayerComp, musicPlayerCompVert],
        "system_monitor": [systemMonitorComp, systemMonitorCompVert],
        "clock": [clockComp, clockCompVert],
        "battery": [batteryComp, batteryCompVert],
        "utility_buttons": [utilityButtonsComp, utilityButtonsCompVert],
        "system_tray": [systemTrayComp, systemTrayCompVert],
        "active_window": [activeWindowComp, activeWindowCompVert],
        "date": [dateCompVert, dateCompVert],
        "record_indicator": [recordIndicatorComp, recordIndicatorCompVert],
        "screen_share_indicator": [screenshareIndicatorComp, screenshareIndicatorComp],
        "timer": [timerComp, timerCompVert],
        "caps_lock": [capsLockComp, capsLockComp],
        "weather": [weatherComp, weatherCompVert],
        "equalizer": [equalizerComp, equalizerComp]
    })

    
    property real startRadius: {
        if (barSection === 0) {
            return Appearance.rounding.verysmall
        } else if (barSection === 2) {
            let hasVisibleLeft = list.slice(0, originalIndex).some(item => item.visible !== false)
            return hasVisibleLeft ? Appearance.rounding.verysmall : Appearance.rounding.full
        } else { // barSection 1 
            if (list.length === 1) return Appearance.rounding.full
            let hasVisibleLeft = list.slice(0, originalIndex).some(item => item.visible !== false)
            return hasVisibleLeft ? Appearance.rounding.verysmall : Appearance.rounding.full
        }
    }

    property real endRadius: {
        if (barSection === 2) {
            return Appearance.rounding.verysmall
        } else if (barSection === 0) {
            let hasVisibleRight = list.slice(originalIndex + 1).some(item => item.visible !== false)
            return hasVisibleRight ? Appearance.rounding.verysmall : Appearance.rounding.full
        } else { // barSection 1 
            if (list.length === 1) return Appearance.rounding.full
            let hasVisibleRight = list.slice(originalIndex + 1).some(item => item.visible !== false)
            return hasVisibleRight ? Appearance.rounding.verysmall : Appearance.rounding.full
        }
    }

    BarGroup {
        id: wrapper
        vertical: rootItem.vertical
        anchors {
            verticalCenter: root.vertical ? rootItem.verticalCenter : undefined
            horizontalCenter: root.vertical ? undefined : rootItem.horizontalCenter
        }

        startRadius: rootItem.startRadius
        endRadius: rootItem.endRadius
        colBackground: {
            if (modelData.id === "record_indicator") return Appearance.m3colors.m3primary
            if (modelData.id === "screen_share_indicator") return Appearance.m3colors.m3primary
            if (modelData.id === "timer") return Appearance.m3colors.m3primary
            return itemLoader.item?.colBackground ?? (backgroundStyle == 0 ? Appearance.colors.colLayer2 : Appearance.m3colors.m3surfaceContainerHighest)
        }

        items: Loader {
            id: itemLoader
            active: true
            sourceComponent: compMap[modelData.id][vertical ? 1 : 0]
        }
    }

    Component { id: timerComp; TimerWidget {} }
    Component { id: timerCompVert; Vertical.VerticalTimerWidget {} }

    Component { id: capsLockComp; CapsLockIndicator {} }

    Component {
        id: equalizerComp
        Item {
            id: eqHost
            readonly property bool playing: MprisController.activePlayer?.isPlaying ?? false
            readonly property color colBackground: "transparent"
            implicitWidth: rootItem.vertical ? eqBars.implicitHeight : eqBars.implicitWidth
            implicitHeight: rootItem.vertical ? eqBars.implicitWidth : eqBars.implicitHeight
            Component.onCompleted: rootItem.toggleVisible(eqHost.playing)
            onPlayingChanged: rootItem.toggleVisible(eqHost.playing)
            CavaBars {
                id: eqBars
                anchors.centerIn: parent
                running: eqHost.playing
                rotation: rootItem.vertical ? -90 : 0
                color: Appearance.colors.colPrimary
            }
        }
    }

    Component { id: screenshareIndicatorComp; ScreenShareIndicator {} }

    Component { id: recordIndicatorComp; RecordIndicator {} }
    Component { id: recordIndicatorCompVert; RecordIndicator { vertical: true } }

    Component { id: activeWindowCompVert; ActiveWindow { vertical: true } }
    Component { id: activeWindowComp; ActiveWindow {} }

    Component { id: systemMonitorComp; Resources {} }
    Component { id: systemMonitorCompVert; Vertical.Resources {} }

    Component { id: musicPlayerCompVert; Vertical.VerticalMedia {} }
    Component { id: musicPlayerComp; Media {} }

    Component { id: utilityButtonsCompVert; UtilButtons { vertical: true } }
    Component { id: utilityButtonsComp; UtilButtons {} }

    Component { id: batteryComp; BatteryIndicator {} }
    Component { id: batteryCompVert; Vertical.BatteryIndicator {} }

    Component { id: clockCompVert; Vertical.VerticalClockWidget {} }
    Component { id: clockComp; ClockWidget {} }

    Component { id: systemTrayCompVert; SysTray { vertical: true; rootItem: rootItem } }
    Component { id: systemTrayComp; SysTray { rootItem: rootItem } }

    Component { id: dateCompVert; Vertical.VerticalDateWidget {} }

    Component { id: weatherComp; WeatherBar {} }
    Component { id: weatherCompVert; Vertical.VerticalWeatherWidget {} }

    Component {
        id: workspaceComp
        Workspaces {
            vertical: rootItem.vertical
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton

                onPressed: event => {
                    if (event.button === Qt.RightButton) {
                        GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                    }
                }
            }
        }
    }
}