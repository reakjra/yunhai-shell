import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

ColumnLayout {
    id: root

    spacing: 2

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Item { Layout.fillHeight: true }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.locale().toString(clock.date, "hh")
        font.pixelSize: 42
        font.family: Appearance.font.family.numbers
        color: Appearance.m3colors.m3secondary
    }

    Row {
        Layout.alignment: Qt.AlignHCenter
        spacing: 7
        Repeater {
            model: 2
            Rectangle {
                width: 6
                height: 6
                radius: width / 2
                color: Appearance.m3colors.m3primary
            }
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: Qt.locale().toString(clock.date, "mm")
        font.pixelSize: 42
        font.family: Appearance.font.family.numbers
        color: Appearance.m3colors.m3secondary
    }

    Item { Layout.fillHeight: true }
}
