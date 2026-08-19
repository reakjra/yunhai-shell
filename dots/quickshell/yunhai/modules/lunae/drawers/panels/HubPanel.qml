pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.modules.common
import qs.modules.lunae
import qs.modules.lunae.hub

Panel {
    id: root

    required property real frameInset

    readonly property real drawerWidth: hubDrawer.drawerWidth
    readonly property real armpitSize: LunaeAppearance.rounding.armpit
    readonly property real cornerSize: LunaeAppearance.rounding.panelLarge
    readonly property real naturalHeight: armpitSize + hubDrawer.contentColumn.implicitHeight + 6

    property real _frozenW: 0
    onDrawerWidthChanged: if (drawerWidth > 0) _frozenW = drawerWidth
    readonly property real _effW: drawerWidth > 0 ? drawerWidth : _frozenW

    property alias hoverHandler: hoverHandler

    axis: Panel.Axis.Vertical
    shouldShow: GlobalStates.hubOpen
    naturalSize: naturalHeight

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: root.frameInset - root.slideOffset

    implicitWidth: _effW + armpitSize * 2

    HubDrawer {
        id: hubDrawer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root._effSize
        hubVisible: GlobalStates.hubOpen
        armpitSize: root.armpitSize
    }

    HoverHandler { id: hoverHandler; margin: root.frameInset + 2 }
}
