import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.akebono

Squircle {
    id: card
    default property alias content: cardCol.data
    property real contentMargin: 15
    radius: 22
    smoothing: AkebonoAppearance.squircleSmoothing
    color: Appearance.colors.colLayer2
    implicitHeight: cardCol.implicitHeight + 26

    ColumnLayout {
        id: cardCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: card.contentMargin
        anchors.rightMargin: card.contentMargin
        spacing: 12
    }
}
