pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

GridLayout {
    id: root

    columns: 6
    rowSpacing: 8
    columnSpacing: 8

    component Cell: Rectangle {
        color: Appearance.colors.colLayer1
        radius: Appearance.rounding.normal
        clip: true
    }

    Cell {
        Layout.row: 0
        Layout.column: 0
        Layout.columnSpan: 2
        Layout.preferredWidth: 180
        Layout.preferredHeight: 115

        radius: Appearance.rounding.verylarge

        HubWeatherSmall {
            anchors.fill: parent
        }
    }

    Cell {
        Layout.row: 0
        Layout.column: 2
        Layout.columnSpan: 3
        Layout.fillWidth: true
        Layout.preferredHeight: 115

        radius: Appearance.rounding.large

        HubUserInfo {
            anchors.fill: parent
            anchors.margins: 12
        }
    }

    Cell {
        Layout.row: 0
        Layout.column: 5
        Layout.rowSpan: 2
        Layout.preferredWidth: 160
        Layout.fillHeight: true
        radius: Appearance.rounding.verylarge

        HubMediaSmall {
            anchors.fill: parent
            anchors.margins: 12
        }
    }

    Cell {
        Layout.row: 1
        Layout.column: 0
        Layout.preferredWidth: 110
        Layout.fillHeight: true

        HubDateTime {
            anchors.fill: parent
            anchors.margins: 8
        }
    }

    Cell {
        Layout.row: 1
        Layout.column: 1
        Layout.columnSpan: 3
        Layout.fillWidth: true
        Layout.fillHeight: true

        radius: Appearance.rounding.medlarge

        HubCalendar {
            anchors.fill: parent
            anchors.margins: 8
        }
    }

    Cell {
        Layout.row: 1
        Layout.column: 4
        Layout.preferredWidth: 90
        Layout.fillHeight: true

        HubResources {
            anchors.fill: parent
            anchors.margins: 8
        }
    }
}
