import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.akebono.shelf.widgets.controlPanel

Item {
    id: root

    StyledFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.implicitHeight
        clip: true

        ColumnLayout {
            id: column
            width: flickable.width
            spacing: 16

            SongRecHero {
                Layout.fillWidth: true
            }

            SectionHeader {
                title: Translation.tr("Listen to")
            }

            Card {
                Layout.fillWidth: true
                contentMargin: 6

                ListRow {
                    Layout.fillWidth: true
                    icon: "speaker"
                    title: Translation.tr("System audio")
                    subtitle: Translation.tr("Whatever is playing on this computer")
                    selectable: true
                    selected: SongRec.monitorSource === SongRec.MonitorSource.Monitor
                    onClicked: SongRec.toggleMonitorSource(SongRec.MonitorSource.Monitor)
                }
                ListRow {
                    Layout.fillWidth: true
                    icon: "mic"
                    title: Translation.tr("Microphone")
                    subtitle: Translation.tr("Music playing around you")
                    selectable: true
                    selected: SongRec.monitorSource === SongRec.MonitorSource.Input
                    onClicked: SongRec.toggleMonitorSource(SongRec.MonitorSource.Input)
                }
            }

            SectionHeader {
                title: Translation.tr("Timing")
            }

            Card {
                Layout.fillWidth: true
                contentMargin: 6

                SliderRow {
                    icon: "timer"
                    title: Translation.tr("Give up after")
                    valueText: Translation.tr("%1 s").arg(Config.options.musicRecognition.timeout)
                    from: 5
                    to: 60
                    value: Config.options.musicRecognition.timeout
                    onMoved: value => Config.options.musicRecognition.timeout = Math.round(value)
                }
                SliderRow {
                    icon: "update"
                    title: Translation.tr("Try every")
                    valueText: Translation.tr("%1 s").arg(Config.options.musicRecognition.interval)
                    from: 1
                    to: 10
                    value: Config.options.musicRecognition.interval
                    onMoved: value => Config.options.musicRecognition.interval = Math.round(value)
                }
            }

            SectionHeader {
                title: Translation.tr("History")

                Pill {
                    visible: SongRec.history.length > 0
                    clickable: true
                    icon: "clear_all"
                    text: Translation.tr("Clear")
                    onClicked: SongRec.clearHistory()
                }
            }

            ListCard {
                Layout.bottomMargin: 8
                values: SongRec.history
                emptyText: Translation.tr("Recognized songs show up here")
                delegate: ListRow {
                    required property var modelData
                    Layout.fillWidth: true
                    icon: "music_note"
                    title: modelData.title
                    subtitle: modelData.subtitle
                    trailingText: NotificationUtils.getFriendlyNotifTimeString(modelData.time)
                    hoverActionAvailable: true
                    hoverActionIcon: "delete"
                    hoverActionTooltip: Translation.tr("Remove")
                    onHoverActionClicked: SongRec.removeFromHistory(modelData.time)
                    onClicked: SongRec.openShazam(modelData)
                }
            }
        }
    }
}
