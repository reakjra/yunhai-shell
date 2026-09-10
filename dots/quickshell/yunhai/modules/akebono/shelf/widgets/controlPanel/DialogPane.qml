import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: pane
    required property var panel
    spacing: 10

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        spacing: 8

        StyledText {
            Layout.fillWidth: true
            text: pane.panel.registry.titleFor(pane.panel.displayDialog)
            font.pixelSize: Appearance.font.pixelSize.huge
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer0
            elide: Text.ElideRight
        }
        ActionButton {
            size: 30
            iconSize: 19
            flat: true
            icon: "check"
            onClicked: pane.panel.activeDialog = ""
        }
    }
    Card {
        Layout.fillWidth: true
        contentMargin: 6

        Loader {
            Layout.fillWidth: true
            sourceComponent: pane.panel.registry.detailFor(pane.panel.displayDialog)
        }
    }
}
