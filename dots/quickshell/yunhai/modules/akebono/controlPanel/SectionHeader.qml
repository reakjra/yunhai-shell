import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RowLayout {
    id: root

    property string title: ""
    property bool busy: false
    default property alias trailing: trailingRow.data

    Layout.fillWidth: true
    Layout.leftMargin: 6
    spacing: 10

    StyledText {
        text: root.title
        font.pixelSize: Appearance.font.pixelSize.larger
        font.weight: Font.DemiBold
        color: Appearance.colors.colOnLayer0
    }
    MaterialLoadingIndicator {
        visible: root.busy
        implicitSize: Appearance.font.pixelSize.larger * 1.4
    }
    Item {
        Layout.fillWidth: true
    }
    RowLayout {
        id: trailingRow
        spacing: 6
    }
}
