import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Rectangle {
    id: root

    property bool show: false
    default property alias data: contentColumn.data
    property real backgroundHeight: contentColumn.implicitHeight + dialogBackground.radius * 2
    property real backgroundWidth: 350

    signal dismiss()
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            root.dismiss();
            event.accepted = true;
        }
    }

    color: root.show ? Appearance.colors.colScrim : ColorUtils.transparentize(Appearance.colors.colScrim)
    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }
    visible: root.show || dialogBackground.opacity > 0

    radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

    MouseArea { // Clicking outside the dialog should dismiss
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        onPressed: root.dismiss()
    }

    RevealSquircle {
        id: dialogBackground
        anchors.centerIn: parent
        radius: Appearance.rounding.large
        smoothing: Config.options.squircle.smoothing
        color: Appearance.m3colors.m3surfaceContainerHigh // Use opaque version of layer3
        shown: root.show

        implicitWidth: root.backgroundWidth
        implicitHeight: root.backgroundHeight
        Behavior on implicitHeight {
            enabled: dialogBackground.opacity === 1
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        MouseArea { // So clicking inside the dialog won't dismiss
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
        }

        ColumnLayout {
            id: contentColumn
            anchors {
                fill: parent
                margins: dialogBackground.radius
            }
            spacing: 16
        }
    }
}
