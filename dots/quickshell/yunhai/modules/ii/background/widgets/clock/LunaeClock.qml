pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property color colText: Appearance.colors.colOnSecondaryContainer

    // use contrasting M3 colors for the time digits
    readonly property bool useLightSet: Appearance.m3colors.darkmode
    readonly property color safePrimary: useLightSet ? Appearance.m3colors.m3primary : Appearance.m3colors.m3primaryContainer
    readonly property color safeSecondary: useLightSet ? Appearance.m3colors.m3secondary : Appearance.m3colors.m3secondaryContainer
    readonly property color safeTertiary: useLightSet ? Appearance.m3colors.m3tertiary : Appearance.m3colors.m3tertiaryContainer

    // follow the digital clock font settings
    readonly property real fontSize: Config.options.background.widgets.clock.digital.font.size
    readonly property int fontWeight: Config.options.background.widgets.clock.digital.font.weight
    readonly property string fontFamily: Config.options.background.widgets.clock.digital.font.family
    readonly property real fontWidth: Config.options.background.widgets.clock.digital.font.width
    readonly property real fontRoundness: Config.options.background.widgets.clock.digital.font.roundness
    readonly property real clockScale: fontSize / 120

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 0

        RowLayout {
            spacing: 24 * root.clockScale

            // Time: HH : MM
            RowLayout {
                id: timeRow
                spacing: 4 * root.clockScale

                ClockText {
                    text: DateTime.time.split(":")[0].padStart(2, "0")
                    color: root.safePrimary
                    font {
                        pixelSize: root.fontSize
                        weight: root.fontWeight
                        family: root.fontFamily
                        variableAxes: ({ "wdth": root.fontWidth, "ROND": root.fontRoundness })
                    }
                }

                ClockText {
                    text: ":"
                    color: root.safeTertiary
                    opacity: 0.8
                    Layout.topMargin: -16 * root.clockScale
                    font {
                        pixelSize: root.fontSize
                        weight: root.fontWeight
                        family: root.fontFamily
                        variableAxes: ({ "wdth": root.fontWidth, "ROND": root.fontRoundness })
                    }
                }

                ClockText {
                    text: DateTime.time.split(":")[1].split(" ")[0].padStart(2, "0")
                    color: root.safeSecondary
                    font {
                        pixelSize: root.fontSize
                        weight: root.fontWeight
                        family: root.fontFamily
                        variableAxes: ({ "wdth": root.fontWidth, "ROND": root.fontRoundness })
                    }
                }
            }

            // Vertical divider
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 4 * root.clockScale
                Layout.topMargin: 16 * root.clockScale
                Layout.bottomMargin: 16 * root.clockScale
                radius: Appearance.rounding.full
                color: root.safePrimary
                opacity: 0.8
            }

            // Date column: MONTH, day number, weekday
            ColumnLayout {
                spacing: 0

                ClockText {
                    text: Qt.locale().toString(DateTime.clock.date, "MMMM").toUpperCase()
                    color: root.safeSecondary
                    font {
                        pixelSize: 18 * root.clockScale
                        letterSpacing: 4
                        weight: Font.Bold
                        family: root.fontFamily
                        variableAxes: ({ "wdth": root.fontWidth, "ROND": root.fontRoundness })
                    }
                }

                ClockText {
                    text: Qt.locale().toString(DateTime.clock.date, "dd")
                    color: root.safePrimary
                    font {
                        pixelSize: 42 * root.clockScale
                        letterSpacing: 2
                        weight: Font.Medium
                        family: root.fontFamily
                        variableAxes: ({ "wdth": root.fontWidth, "ROND": root.fontRoundness })
                    }
                }

                ClockText {
                    text: Qt.locale().toString(DateTime.clock.date, "dddd")
                    color: root.safeSecondary
                    font {
                        pixelSize: 22 * root.clockScale
                        letterSpacing: 2
                        family: root.fontFamily
                        variableAxes: ({ "wdth": root.fontWidth, "ROND": root.fontRoundness })
                    }
                }
            }
        }

        // Quote — centered under the time digits (colon as midpoint)
        ClockText {
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignLeft
            Layout.leftMargin: timeRow.x + (timeRow.width - implicitWidth) / 2
            horizontalAlignment: Text.AlignHCenter
            visible: Config.options.background.widgets.clock.quote.enable && Config.options.background.widgets.clock.quote.text.length > 0
            text: Config.options.background.widgets.clock.quote.text
            color: root.safeSecondary
            animateChange: false
            font {
                pixelSize: Appearance.font.pixelSize.normal
                family: root.fontFamily
                weight: root.fontWeight
                variableAxes: ({ "wdth": root.fontWidth, "ROND": root.fontRoundness })
            }
        }
    }
}
