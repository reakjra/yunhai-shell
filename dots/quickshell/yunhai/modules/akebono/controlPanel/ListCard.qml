import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono.shelf.widgets.controlPanel

Card {
    id: root

    property var values: []
    property Component delegate
    property string emptyText: ""

    Layout.fillWidth: true
    contentMargin: 6

    ColumnLayout {
        Layout.fillWidth: true
        visible: root.values.length > 0
        spacing: 2

        Repeater {
            model: ScriptModel {
                values: root.values
            }
            delegate: root.delegate
        }
    }

    StyledText {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 8
        Layout.bottomMargin: 8
        visible: root.values.length === 0
        text: root.emptyText
        font.pixelSize: Appearance.font.pixelSize.normal
        color: Appearance.colors.colSubtext
    }
}
