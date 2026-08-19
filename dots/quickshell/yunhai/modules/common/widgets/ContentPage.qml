import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

StyledFlickable {
    id: root
    property real baseWidth: 600
    property bool forceWidth: false
    property real bottomContentPadding: 100

    default property alias data: contentColumn.data

    clip: true
    contentHeight: contentColumn.implicitHeight + root.bottomContentPadding // Add some padding at the bottom
    implicitWidth: contentColumn.implicitWidth
    
    ColumnLayout {
        id: contentColumn
        width: SettingsStyle.grouped ? undefined : (root.forceWidth ? root.baseWidth : Math.max(root.baseWidth, implicitWidth))
        anchors {
            top: parent.top
            left: SettingsStyle.grouped ? parent.left : undefined
            right: SettingsStyle.grouped ? parent.right : undefined
            horizontalCenter: SettingsStyle.grouped ? undefined : parent.horizontalCenter
            margins: SettingsStyle.grouped ? 6 : 20
        }
        spacing: SettingsStyle.grouped ? 18 : 30
    }

}
