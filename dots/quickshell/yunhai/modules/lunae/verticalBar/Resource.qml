import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import QtQuick

Item {
    id: root
    required property string iconName
    required property double percentage
    property int warningThreshold: 100
    implicitHeight: resourceProgress.implicitHeight
    implicitWidth: Appearance.sizes.verticalBarWidth

    property bool warning: percentage * 100 >= warningThreshold

    CircularProgress {
        id: resourceProgress
        anchors.centerIn: parent
        implicitSize: Math.round(Appearance.sizes.verticalBarWidth * 0.55)
        lineWidth: 3
        value: percentage
        enableAnimation: false
        colPrimary: root.warning ? Appearance.colors.colError : Appearance.colors.colOnSecondaryContainer
        colSecondary: Qt.alpha(root.warning ? Appearance.colors.colError : Appearance.colors.colOnSecondaryContainer, 0.3)

        MaterialSymbol {
            anchors.centerIn: parent
            font.weight: Font.Medium
            fill: 1
            text: root.iconName
            iconSize: 12
            color: Config.options.lunae.colorful ? Appearance.colors.colSecondary : Appearance.colors.colOnSecondaryContainer
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        enabled: root.visible
    }
}
