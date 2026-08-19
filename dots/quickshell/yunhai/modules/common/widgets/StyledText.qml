import qs.modules.common
import QtQuick

Text {
    id: root
    property bool animateChange: false
    property real animationDistanceX: 0
    property real animationDistanceY: 6

    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    property bool shouldUseNumberFont: /^\d+$/.test(root.text)
    property var defaultFont: shouldUseNumberFont ? Appearance.font.family.numbers : Appearance.font.family.main
    
    font {
        hintingPreference: Font.PreferDefaultHinting
        family: defaultFont
        pixelSize: Appearance?.font.pixelSize.small ?? 15
        variableAxes: shouldUseNumberFont ? ({}) : Appearance.font.variableAxes.main
    }
    color: Appearance?.m3colors.m3onBackground ?? "black"
    linkColor: Appearance?.m3colors.m3primary

    transform: Translate {
        id: animTranslate
    }

    component Anim: NumberAnimation {
        duration: 300 / 2
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
    }

    Behavior on text {
        id: textAnimationBehavior
        enabled: root.animateChange

        SequentialAnimation {
            alwaysRunToEnd: true
            ParallelAnimation {
                Anim {
                    target: animTranslate
                    property: "x"
                    to: -root.animationDistanceX
                    easing.type: Easing.InSine
                }
                Anim {
                    target: animTranslate
                    property: "y"
                    to: -root.animationDistanceY
                    easing.type: Easing.InSine
                }
                Anim {
                    target: root
                    property: "opacity"
                    to: 0
                    easing.type: Easing.InSine
                }
            }
            PropertyAction {} // Tie the text update to this point (we don't want it to happen during the first slide+fade)
            PropertyAction {
                target: animTranslate
                property: "x"
                value: root.animationDistanceX
            }
            PropertyAction {
                target: animTranslate
                property: "y"
                value: root.animationDistanceY
            }
            ParallelAnimation {
                Anim {
                    target: animTranslate
                    property: "x"
                    to: 0
                    easing.type: Easing.OutSine
                }
                Anim {
                    target: animTranslate
                    property: "y"
                    to: 0
                    easing.type: Easing.OutSine
                }
                Anim {
                    target: root
                    property: "opacity"
                    to: 1
                    easing.type: Easing.OutSine
                }
            }
        }
    }
}
