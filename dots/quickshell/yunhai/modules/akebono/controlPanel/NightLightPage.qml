import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono.shelf.widgets.controlPanel

Item {
    id: root

    property string scheduleEdge: ""

    StyledFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.implicitHeight
        clip: true

        ColumnLayout {
            id: column
            width: flickable.width
            spacing: 16

            NightLightHero {
                Layout.fillWidth: true
            }

            SectionHeader {
                title: Translation.tr("Schedule")
            }

            Card {
                Layout.fillWidth: true
                contentMargin: 6

                ListRow {
                    Layout.fillWidth: true
                    icon: "night_sight_auto"
                    title: Translation.tr("Automatic")
                    subtitle: Translation.tr("Follow the schedule below")
                    switchable: true
                    switchChecked: Config.options.light.night.automatic
                    onClicked: Config.options.light.night.automatic = !Config.options.light.night.automatic
                }
                ListRow {
                    Layout.fillWidth: true
                    visible: Config.options.light.night.automatic
                    icon: "wb_twilight"
                    title: Translation.tr("Turns on")
                    subtitle: Hyprsunset.from
                    trailingIcon: "edit"
                    onClicked: root.scheduleEdge = "from"
                }
                ListRow {
                    Layout.fillWidth: true
                    visible: Config.options.light.night.automatic
                    icon: "wb_sunny"
                    title: Translation.tr("Turns off")
                    subtitle: Hyprsunset.to
                    trailingIcon: "edit"
                    onClicked: root.scheduleEdge = "to"
                }
            }

            SectionHeader {
                title: Translation.tr("Color")
            }

            Card {
                Layout.fillWidth: true
                contentMargin: 6

                SliderRow {
                    icon: "thermostat"
                    title: Translation.tr("Intensity")
                    valueText: `${Hyprsunset.colorTemperature}K`
                    from: 6500
                    to: 1200
                    stopIndicatorValues: [5000, to]
                    value: Hyprsunset.colorTemperature
                    onMoved: value => Config.options.light.night.colorTemperature = Math.round(value)
                }
                SliderRow {
                    icon: "contrast"
                    title: Translation.tr("Gamma")
                    valueText: `${Hyprsunset.gamma}%`
                    from: Hyprsunset.gammaLowerLimit
                    to: 100
                    value: Hyprsunset.gamma
                    onMoved: value => Hyprsunset.setGamma(value)
                }
            }

            SectionHeader {
                title: Translation.tr("Brightness")
            }

            Card {
                Layout.fillWidth: true
                Layout.bottomMargin: 8
                contentMargin: 6

                Repeater {
                    model: Brightness.monitors
                    delegate: SliderRow {
                        required property var modelData
                        enabled: modelData.ready
                        icon: "brightness_6"
                        title: modelData.screen.name
                        valueText: `${Math.round(modelData.brightness * 100)}%`
                        value: modelData.brightness
                        onMoved: value => modelData.setBrightness(value)
                    }
                }
                ListRow {
                    Layout.fillWidth: true
                    icon: "filter"
                    title: Translation.tr("Adapt to content")
                    subtitle: Appearance.m3colors.darkmode ? Translation.tr("Dims the display while bright windows are on screen") : Translation.tr("Only works in dark mode")
                    switchable: true
                    switchChecked: Config.options.light.antiFlashbang.enable
                    onClicked: Config.options.light.antiFlashbang.enable = !Config.options.light.antiFlashbang.enable
                }
            }
        }
    }

    Item {
        parent: root.Window.window?.contentItem ?? root
        anchors.fill: parent
        z: 1

        WindowDialogLoader {
            shown: root.scheduleEdge !== ""
            onDismissed: root.scheduleEdge = ""
            dialog: NightLightScheduleDialog {
                requestedEdge: root.scheduleEdge
            }
        }
    }
}
