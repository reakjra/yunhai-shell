pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.lunae
import qs.modules.lunae.drawers.panels
import qs.modules.lunae.widgets

Item {
    id: root

    required property real frameInset
    required property real screenHeight

    readonly property real armpitSize: LunaeAppearance.rounding.armpit
    readonly property real cornerSize: LunaeAppearance.rounding.panelSmall
    readonly property real contentWidth: Appearance.sizes.notificationPopupWidth
    readonly property real contentPadding: 12
    readonly property real contentTopMargin: contentPadding
    readonly property real contentBottomMargin: contentPadding

    readonly property real naturalWidth: armpitSize + contentPadding + contentWidth + contentPadding
    readonly property real naturalHeight: notifListview.contentHeight > 0
        ? notifListview.contentHeight + contentTopMargin + contentBottomMargin + armpitSize : 0

    readonly property bool hasPopups: Notifications.popupList.length > 0
    property real _heldHeight: 0
    onNaturalHeightChanged: if (naturalHeight > 0) _heldHeight = naturalHeight

    property alias hoverHandler: hoverHandler

    property real progress: hasPopups ? 1 : 0
    Behavior on progress {
        NumberAnimation {
            duration: LunaeAppearance.drawerOpenDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: LunaeAppearance.drawerOpenCurve
        }
    }

    anchors.right: parent.right
    anchors.rightMargin: root.frameInset - (root.naturalWidth + 8) * (1 - root.progress)
    anchors.top: parent.top
    anchors.topMargin: root.frameInset

    implicitWidth: naturalWidth
    implicitHeight: naturalHeight > 0 ? naturalHeight : _heldHeight
    visible: progress > 0.004
    opacity: progress
    transform: Matrix4x4 { matrix: deform.matrix }

    readonly property alias deformX: deform.sx
    readonly property alias deformY: deform.sy

    DeformTracker {
        id: deform
        target: root
        amount: 0.08
    }

    Behavior on implicitHeight {
        enabled: !notifListview.expanding
        LunaeAnim {}
    }

    onVisibleChanged: {
        if (!visible) notifListview.clearAll()
    }

    LunaeNotificationListView {
        id: notifListview
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: root.armpitSize + root.contentPadding
        anchors.topMargin: root.contentTopMargin
        width: root.contentWidth
        height: root.naturalHeight
        popup: true
        elevated: true
    }

    HoverHandler { id: hoverHandler }
}
