import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono.shelf.widgets
import QtQuick

Item {
    id: root
    property var shelf
    signal closeRequested()

    implicitWidth: 340
    implicitHeight: 336

    HubCalendar {
        anchors.fill: parent
        anchors.margins: 14
        anchors.bottomMargin: 16
    }
}
