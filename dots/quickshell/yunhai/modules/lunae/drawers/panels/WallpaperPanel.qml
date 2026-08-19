pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.modules.common
import qs.modules.lunae
import qs.modules.lunae.drawers.panels
import qs.modules.lunae.wallpaperSelector

Item {
    id: root

    required property real frameInset

    readonly property real drawerWidth: Appearance.sizes.wallpaperSelectorWidth
    readonly property real contentHeight: Appearance.sizes.wallpaperSelectorHeight
    readonly property real armpitSize: LunaeAppearance.rounding.armpit
    readonly property real cornerSize: LunaeAppearance.rounding.panelLarge
    readonly property real naturalHeight: contentHeight + armpitSize

    readonly property bool shouldShow: GlobalStates.wallpaperSelectorOpen
    property real progress: 0
    property bool contentNeeded: false

    property alias hoverHandler: hoverHandler

    function focusContent() {
        contentLoader.item?.forceActiveFocus();
    }

    onShouldShowChanged: {
        if (shouldShow) {
            GlobalStates.overviewOpen = false
            const ready = contentLoader.status === Loader.Ready
            contentNeeded = true
            if (ready) {
                progress = 1
                focusContent()
            } else {
                openDefer.restart()
            }
        } else {
            openDefer.stop()
            progress = 0
        }
    }

    onProgressChanged: {
        if (progress === 0 && !shouldShow)
            contentNeeded = false
    }

    Timer {
        id: openDefer
        interval: 120
        onTriggered: {
            root.progress = 1
            root.focusContent()
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
    anchors.bottomMargin: root.frameInset - (root.naturalHeight + 8) * (1 - root.progress)

    implicitWidth: drawerWidth + armpitSize * 2
    implicitHeight: naturalHeight
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

    Loader {
        id: contentLoader
        active: root.contentNeeded || (Config.options.wallpaperSelector?.keepLoaded ?? false)
        x: root.armpitSize
        anchors.top: parent.top
        width: root.drawerWidth
        height: root.contentHeight
        sourceComponent: WallpaperSelectorContent {}
    }

    HoverHandler { id: hoverHandler }
}
