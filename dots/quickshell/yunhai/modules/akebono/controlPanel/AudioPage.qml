import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono.shelf.widgets.controlPanel

Item {
    id: root

    readonly property bool micMuted: Audio.source?.audio.muted ?? false

    StyledFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.implicitHeight
        clip: true

        ColumnLayout {
            id: column
            width: flickable.width
            spacing: 16

            AudioHero {
                Layout.fillWidth: true
            }

            SectionHeader {
                title: Translation.tr("Output devices")
            }

            ListCard {
                values: Audio.outputDevices
                emptyText: Translation.tr("No output devices")
                delegate: ListRow {
                    required property var modelData
                    Layout.fillWidth: true
                    icon: "speaker"
                    title: Audio.friendlyDeviceName(modelData)
                    selectable: true
                    selected: modelData.id === Audio.sink?.id
                    onClicked: Audio.setDefaultSink(modelData)
                }
            }

            SectionHeader {
                title: Translation.tr("Apps")
            }

            ListCard {
                values: Audio.outputAppNodes
                emptyText: Translation.tr("No apps are playing audio")
                delegate: VolumeMixerEntry {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.margins: 6
                    node: modelData
                    labelColor: Appearance.colors.colOnLayer2
                }
            }

            SectionHeader {
                title: Translation.tr("Microphone")
            }

            Card {
                Layout.fillWidth: true
                visible: Audio.source !== null
                contentMargin: 6

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 12 - (micButton.size - micButton.iconSize) / 2
                    Layout.rightMargin: 8
                    spacing: 12

                    ActionButton {
                        id: micButton
                        flat: true
                        size: Appearance.font.pixelSize.huge * 1.6
                        iconSize: Appearance.font.pixelSize.huge
                        icon: root.micMuted ? "mic_off" : "mic"
                        tooltip: root.micMuted ? Translation.tr("Unmute") : Translation.tr("Mute")
                        onClicked: Audio.toggleMicMute()
                    }
                    StyledSlider {
                        Layout.fillWidth: true
                        configuration: StyledSlider.Configuration.S
                        value: Audio.source?.audio.volume ?? 0
                        onMoved: Audio.source.audio.volume = value
                    }
                    StyledText {
                        text: `${Math.round((Audio.source?.audio.volume ?? 0) * 100)}%`
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: Appearance.colors.colSubtext
                    }
                }
            }

            ListCard {
                Layout.bottomMargin: 8
                values: Audio.inputDevices
                emptyText: Translation.tr("No input devices")
                delegate: ListRow {
                    required property var modelData
                    Layout.fillWidth: true
                    icon: "mic"
                    title: Audio.friendlyDeviceName(modelData)
                    selectable: true
                    selected: modelData.id === Audio.source?.id
                    onClicked: Audio.setDefaultSource(modelData)
                }
            }
        }
    }
}
