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
    readonly property real naturalWidth: armpitSize + contentWidth

    property alias hoverHandler: hoverHandler

    axis: Panel.Axis.Horizontal
    shouldShow: !(Config.options.lunae?.sidebar?.splitMode ?? false) && GlobalStates.sidebarRightOpen
    naturalSize: naturalWidth
    deformAmount: 0.03

    anchors.right: parent.right
    anchors.rightMargin: root.frameInset - root.slideOffset
    anchors.top: parent.top
    anchors.topMargin: root.frameInset
    anchors.bottom: parent.bottom
    anchors.bottomMargin: root.frameInset

    Loader {
        active: GlobalStates.sidebarRightOpen || root.visible
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: root.naturalWidth
        sourceComponent: SidebarRightDrawer {
            sidebarVisible: GlobalStates.sidebarRightOpen
            contentWidth: root.contentWidth
            armpitSize: root.armpitSize
        }
    }

    HoverHandler { id: hoverHandler; margin: root.frameInset + 2 }
}
