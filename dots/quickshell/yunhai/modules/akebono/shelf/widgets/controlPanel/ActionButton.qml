import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono

Squircle {
    id: bt
    property string icon: ""
    property bool danger: false
    property bool flat: false
    property real size: 46
    property int iconSize: Math.round(size * 0.46)
    signal clicked()
    implicitWidth: size
    implicitHeight: size
    radius: size * 0.35
    smoothing: AkebonoAppearance.squircleSmoothing
    color: bt.flat ? "transparent" : Appearance.colors.colLayer2

    MaterialSymbol {
        anchors.centerIn: parent
        text: bt.icon
        iconSize: bt.iconSize
        color: bt.danger ? Appearance.colors.colError : Appearance.colors.colOnLayer2
    }
    RippleArea {
        shapeRadius: bt.radius
        rippleColor: bt.danger ? Appearance.colors.colError : Appearance.colors.colOnLayer2
        onClicked: bt.clicked()
    }
}
