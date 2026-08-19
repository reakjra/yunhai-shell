pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.services

Item {
    id: root

    component ResourceBar: Item {
        id: resBar
        required property string icon
        required property real value
        required property color colour

        implicitWidth: 22
        height: parent.height

        Rectangle {
            id: barTrack
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: resIcon.top
            anchors.bottomMargin: 4
            width: 10
            radius: Appearance.rounding.full
            color: Appearance.colors.colLayer2

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Math.max(0, resBar.value * parent.height)
                radius: Appearance.rounding.full
                color: resBar.colour

                Behavior on height {
                    NumberAnimation {
                        duration: Appearance.animation.elementMove.duration
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }

        MaterialSymbol {
            id: resIcon
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            text: resBar.icon
            iconSize: 14
            color: resBar.colour
        }
    }

    Row {
        anchors.centerIn: parent
        height: parent.height
        spacing: 6

        ResourceBar {
            icon: "memory"
            value: ResourceUsage.cpuUsage
            colour: Appearance.colors.colPrimary
        }

        ResourceBar {
            icon: "memory_alt"
            value: ResourceUsage.memoryUsedPercentage
            colour: Appearance.m3colors.m3secondary
        }

        ResourceBar {
            icon: "swap_horiz"
            value: ResourceUsage.swapUsedPercentage
            colour: Appearance.m3colors.m3tertiary
        }
    }
}
