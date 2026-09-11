pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono.desktop.widgets
import "../../../../common/functions/calendar_layout.js" as CalendarLayout

WidgetCard {
    id: root
    minSize: root.isDay ? 120 : 220

    property int monthShift: 0

    readonly property bool isMonth: root.styleId === "month"
    readonly property bool isSplit: root.styleId === "split"
    readonly property bool isDay: root.styleId === "day"
    readonly property bool gridShown: !root.isDay

    readonly property date today: {
        DateTime.date;
        return new Date();
    }
    readonly property date viewingDate: CalendarLayout.getDateInXMonthsTime(root.monthShift)
    readonly property var weeks: CalendarLayout.getCalendarLayout(root.viewingDate, root.monthShift === 0)
    readonly property var days: root.weeks.reduce((all, week) => all.concat(week), [])
    readonly property real cellSize: Math.min(grid.width / 7, grid.height / 6)
    readonly property int dayFontSize: Math.max(Appearance.font.pixelSize.smallest, Math.min(Appearance.font.pixelSize.large, Math.round(root.cellSize * 0.45)))
    readonly property int headerFontSize: Math.max(Appearance.font.pixelSize.smallest, root.dayFontSize - 3)
    readonly property real columnInset: Math.max(0, (root.cellSize - headerMetrics.width) / 2)

    TextMetrics {
        id: headerMetrics
        font.family: Appearance.font.family.main
        font.pixelSize: root.headerFontSize
        font.variableAxes: Appearance.font.variableAxes.main
        text: CalendarLayout.weekDays[0].day
    }

    WheelHandler {
        enabled: root.gridShown
        onWheel: event => root.monthShift += (event.angleDelta.y > 0 ? -1 : 1)
    }

    RowLayout {
        anchors.fill: parent
        visible: root.gridShown
        spacing: 24

        DateBlock {
            visible: root.isSplit
            Layout.fillWidth: true
            Layout.fillHeight: true
            numberSize: Math.max(Appearance.font.pixelSize.huge, Math.min(80, Math.round(root.height * 0.42)))
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: root.isSplit ? root.width * 0.58 : -1
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: root.columnInset
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: root.viewingDate.toLocaleDateString(Qt.locale(), "MMMM")
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.DemiBold
                        color: root.isSplit ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1
                        elide: Text.ElideRight
                    }
                    StyledText {
                        Layout.fillWidth: true
                        visible: !root.isSplit
                        text: root.viewingDate.toLocaleDateString(Qt.locale(), "yyyy")
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }

                RippleButton {
                    visible: root.monthShift !== 0
                    implicitWidth: 28
                    implicitHeight: 28
                    buttonRadius: Appearance.rounding.full
                    onClicked: root.monthShift = 0

                    contentItem: MaterialSymbol {
                        horizontalAlignment: Text.AlignHCenter
                        text: "today"
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colOnLayer1
                    }
                }
            }

            GridLayout {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7
                columnSpacing: 0
                rowSpacing: 0

                Repeater {
                    model: CalendarLayout.weekDays

                    StyledText {
                        id: dayHeader
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.cellSize * 0.7
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: dayHeader.modelData.day
                        font.pixelSize: root.headerFontSize
                        color: Appearance.colors.colSubtext
                    }
                }

                Repeater {
                    model: root.days

                    Item {
                        id: dayCell
                        required property var modelData
                        readonly property bool isToday: dayCell.modelData.today === 1
                        readonly property bool otherMonth: dayCell.modelData.today === -1
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ShapeSurface {
                            anchors.centerIn: parent
                            visible: dayCell.isToday
                            width: Math.min(parent.width, parent.height)
                            height: width
                            shape: root.chipShape
                            themeRadius: width * 0.34
                            color: Appearance.colors.colPrimary
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: dayCell.modelData.day
                            font.pixelSize: root.dayFontSize
                            font.weight: dayCell.isToday ? Font.DemiBold : Font.Normal
                            color: dayCell.isToday ? Appearance.colors.colOnPrimary : (dayCell.otherMonth ? Appearance.colors.colSubtext : Appearance.colors.colOnLayer1)
                            opacity: dayCell.otherMonth ? 0.45 : 1
                        }
                    }
                }
            }
        }
    }

    DateBlock {
        anchors.centerIn: parent
        width: parent.width
        visible: root.isDay
        centered: true
        showMonth: true
        numberSize: Math.max(Appearance.font.pixelSize.huge, Math.min(96, Math.round(Math.min(root.width, root.height) * 0.42)))
    }

    component DateBlock: ColumnLayout {
        id: block
        property bool centered: false
        property bool showMonth: false
        property real numberSize: Appearance.font.pixelSize.huge
        readonly property int align: block.centered ? Text.AlignHCenter : Text.AlignLeft
        spacing: 0

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: block.align
            text: root.today.toLocaleDateString(Qt.locale(), "dddd")
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.DemiBold
            color: Appearance.colors.colPrimary
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: block.align
            text: root.today.getDate()
            font.pixelSize: block.numberSize
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
        }

        StyledText {
            Layout.fillWidth: true
            visible: block.showMonth
            horizontalAlignment: block.align
            text: root.today.toLocaleDateString(Qt.locale(), "MMMM yyyy")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            elide: Text.ElideRight
        }

        Item {
            Layout.fillHeight: true
            visible: !block.centered
        }
    }
}
