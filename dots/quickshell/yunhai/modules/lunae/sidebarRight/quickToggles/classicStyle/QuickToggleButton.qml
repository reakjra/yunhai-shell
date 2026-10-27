import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae
import QtQuick

GroupButton {
    id: button
    property string buttonIcon
    baseWidth: 40
    baseHeight: 40
    clickedWidth: baseWidth + 20
    toggled: false
    buttonRadius: toggled ? Appearance?.rounding.small : Appearance?.rounding.verysmall
    buttonRadiusPressed: Appearance?.rounding?.unsharpenmore

    MotionBehavior on radius {
        motion: Motion.spatialFast
    }

    contentItem: MaterialSymbol {
        anchors.centerIn: parent
        iconSize: 22
        fill: toggled ? 1 : 0
        color: toggled ? Appearance.m3colors.m3onPrimary : Appearance.colors.colOnLayer1
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: buttonIcon

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        Behavior on fill {
            NumberAnimation {
                duration: Motion.spatialFast.duration
                easing.type: Easing.OutCubic
            }
        }
    }
}
