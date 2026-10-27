import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono.shelf.widgets.controlPanel

Card {
    id: root

    property string time: ""
    property string caption: ""
    property real progress: -1
    property alias actions: actionRow.data
    property alias footer: footerColumn.data

    Layout.fillWidth: true
    contentMargin: 6

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 8
        spacing: 12

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                Layout.fillWidth: true
                text: root.time
                font.family: Appearance.font.family.numbers
                font.variableAxes: Appearance.font.variableAxes.numbers
                font.pixelSize: Appearance.font.pixelSize.huge * 2
                color: Appearance.colors.colOnLayer2
            }
            StyledText {
                Layout.fillWidth: true
                visible: root.caption !== ""
                text: root.caption
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
            }
        }

        RowLayout {
            id: actionRow
            spacing: 6
        }
    }

    StyledProgressBar {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        Layout.rightMargin: 12
        visible: root.progress >= 0
        value: Math.max(0, root.progress)
    }

    ColumnLayout {
        id: footerColumn
        Layout.fillWidth: true
        spacing: 2
        visible: children.length > 0
    }
}
