import QtQuick

Loader {
    id: root

    required property MouseArea area
    property string text: ""

    anchors.fill: parent
    active: root.text !== ""

    sourceComponent: StyledToolTip {
        text: root.text
        extraVisibleCondition: false
        alternativeVisibleCondition: root.area.containsMouse
    }
}
