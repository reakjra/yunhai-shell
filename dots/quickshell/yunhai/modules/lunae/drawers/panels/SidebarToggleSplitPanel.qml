pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.modules.common
import qs.modules.lunae
import qs.modules.lunae.sidebarRight

Panel {
    id: root

    required property real frameInset

    readonly property real contentWidth: Appearance.sizes.sidebarWidth
    readonly property real armpitSize: LunaeAppearance.rounding.armpit
    readonly property real cornerSize: LunaeAppearance.rounding.panelSmall
    readonly property real naturalWidth: armpitSize + contentWidth
    readonly property real naturalHeight: armpitSize * 2 + 16 + drawer.toggleSectionHeight

    property alias hoverHandler: hoverHandler

    axis: Panel.Axis.Horizontal
    shouldShow: (Config.options.lunae?.sidebar?.splitMode ?? false) && GlobalStates.sidebarToggleOpen
    naturalSize: naturalWidth
    deformAmount: 0.06

    anchors.right: parent.right
    anchors.rightMargin: root.frameInset - root.slideOffset
    anchors.bottom: parent.bottom
    anchors.bottomMargin: root.frameInset

    implicitHeight: naturalHeight

    SidebarRightDrawer {
        id: drawer
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: root.naturalWidth
        sidebarVisible: GlobalStates.sidebarToggleOpen
        contentWidth: root.contentWidth
        armpitSize: root.armpitSize
        mode: "toggles"
    }

    HoverHandler { id: hoverHandler; margin: root.frameInset + 2 }
}
