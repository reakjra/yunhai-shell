import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.lunae.sidebarRight.notifications

Rectangle {
    Layout.fillWidth: true
    Layout.fillHeight: true
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1

    NotificationList {
        anchors.fill: parent
        anchors.margins: 10
        showStatusRow: false
    }
}
