import QtQuick
import qs.modules.common
import qs.modules.lunae

NumberAnimation {
    id: root

    enum Kind {
        Open,
        Close,
        Popup,
        Morph,
        Effects
    }

    property int kind: LunaeAnim.Kind.Popup

    duration: {
        switch (root.kind) {
        case LunaeAnim.Kind.Open: return LunaeAppearance.drawerOpenDuration
        case LunaeAnim.Kind.Close: return LunaeAppearance.drawerCloseDuration
        case LunaeAnim.Kind.Morph: return LunaeAppearance.morphDuration
        case LunaeAnim.Kind.Effects: return Appearance.animationCurves.expressiveEffectsDuration
        default: return LunaeAppearance.popupDuration
        }
    }
    easing.type: Easing.BezierSpline
    easing.bezierCurve: {
        switch (root.kind) {
        case LunaeAnim.Kind.Open: return LunaeAppearance.drawerOpenCurve
        case LunaeAnim.Kind.Close: return LunaeAppearance.closeCurve
        case LunaeAnim.Kind.Morph: return LunaeAppearance.morphCurve
        case LunaeAnim.Kind.Effects: return Appearance.animationCurves.expressiveEffects
        default: return LunaeAppearance.popupCurve
        }
    }
}
