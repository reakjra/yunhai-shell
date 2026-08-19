import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono
import QtQuick
import Quickshell
import Quickshell.Hyprland

Squircle {
    id: root

    property real barHeight: 54

    implicitWidth: workspaces.implicitWidth + 16
    implicitHeight: root.barHeight * 0.55
    radius: height / 2
    color: AkebonoAppearance.shelfPillColor

    WheelHandler {
        onWheel: event => {
            if (event.angleDelta.y < 0)
                Hyprland.dispatch(`hl.dsp.focus({workspace = "r+1"})`);
            else if (event.angleDelta.y > 0)
                Hyprland.dispatch(`hl.dsp.focus({workspace = "r-1"})`);
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    Workspaces {
        id: workspaces
        anchors.centerIn: parent
        crossAxisSize: root.height

        iconBoxWrapperSize: Math.round(root.barHeight * 0.42)
        individualIconBoxHeight: Math.round(root.barHeight * 0.36)

        dotSize: Math.round(root.barHeight * 0.17)
        dotActiveSize: Math.round(root.barHeight * 0.4)
        dotSpacing: 6
        dotPillPaddingSide: 0
        dotPillPaddingLength: 0
        dotPillBackground: false

        windowCellLength: Math.round(root.barHeight * 0.62)
        windowCellThickness: Math.round(root.barHeight * 0.42)
    }
}
