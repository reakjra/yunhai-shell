import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae

RippleButton {
    id: root

    property string buttonIcon: ""
    property real iconSize: 20
    property real iconFill: root.toggled ? 1 : 0

    implicitWidth: 34
    implicitHeight: 34
    padding: 0

    buttonRadius: root.toggled ? Appearance.rounding.small : Appearance.rounding.verysmall
    buttonRadiusPressed: Appearance.rounding.unsharpenmore

    Behavior on buttonEffectiveRadius {
        NumberAnimation {
            duration: LunaeAppearance.morphDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: LunaeAppearance.morphCurve
        }
    }

    colBackground: "transparent"
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive

    contentItem: MaterialSymbol {
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        iconSize: root.iconSize
        text: root.buttonIcon
        fill: root.iconFill
        color: root.toggled ? Appearance.m3colors.m3onSecondaryContainer
                            : Appearance.colors.colOnLayer1

        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        Behavior on fill {
            NumberAnimation {
                duration: LunaeAppearance.morphDuration
                easing.type: Easing.OutCubic
            }
        }
    }
}
