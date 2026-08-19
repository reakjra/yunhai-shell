pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.lunae
import qs.modules.lunae.drawers.panels
import qs.modules.lunae.overview

Item {
    id: root

    required property real frameInset
    required property bool searchShowWorkspaces
    required property bool dontAutoCancelSearch
    required property var screen

    readonly property real drawerWidth: 550
    readonly property real armpitSize: LunaeAppearance.rounding.armpit
    readonly property real cornerSize: LunaeAppearance.rounding.panelLarge
    readonly property real naturalHeight: searchDrawer.naturalHeight

    readonly property bool shouldShow: GlobalStates.overviewOpen && !root.searchShowWorkspaces
    property real progress: 0

    property alias searchDrawer: searchDrawer

    property real _frozenH: 0
    onNaturalHeightChanged: if (naturalHeight > 0) _frozenH = naturalHeight
    readonly property real _effH: naturalHeight > 0 ? naturalHeight : _frozenH

    onShouldShowChanged: {
        if (shouldShow) {
            GlobalStates.wallpaperSelectorOpen = false
            if (!dontAutoCancelSearch)
                searchDrawer.cancelSearch()
            progress = 1
            searchDrawer.focusInput()
        } else {
            _frozenH = naturalHeight
            progress = 0
        }
    }

    onProgressChanged: {
        if (progress === 0 && !shouldShow) {
            searchDrawer.cancelSearch()
            LauncherSearch.activeCategory = ""
        }
    }

    Behavior on progress {
        NumberAnimation {
            duration: LunaeAppearance.drawerOpenDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: LunaeAppearance.drawerOpenCurve
        }
    }

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: root.frameInset - (root._effH + 8) * (1 - root.progress)

    implicitWidth: drawerWidth + armpitSize * 2
    implicitHeight: _effH
    visible: progress > 0.004
    opacity: progress
    transform: Matrix4x4 { matrix: deform.matrix }

    readonly property alias deformX: deform.sx
    readonly property alias deformY: deform.sy

    DeformTracker {
        id: deform
        target: root
        amount: 0.1
    }

    SearchDrawer {
        id: searchDrawer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.naturalHeight
        open: GlobalStates.overviewOpen && !root.searchShowWorkspaces
        drawerWidth: root.drawerWidth
        armpitSize: root.armpitSize
    }
}
