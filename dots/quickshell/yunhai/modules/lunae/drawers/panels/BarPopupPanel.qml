pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.modules.common
import qs.modules.lunae
import qs.modules.lunae.drawers.panels
import qs.modules.lunae.widgets

Item {
    id: root

    required property real frameInset
    required property real barWidth

    property alias hoverHandler: hoverHandler

    readonly property real contentPadding: 10
    readonly property real armpitSize: LunaeAppearance.rounding.armpit
    readonly property real cornerSize: LunaeAppearance.rounding.panelSmall
    readonly property real hugSize: Appearance.rounding.screenRounding

    readonly property bool hugBottom: {
        if (!visible || naturalHeight <= 0) return false
        const h = naturalHeight
        const centered = GlobalStates.barPopupY - h / 2
        const minY = Math.max(Appearance.rounding.screenRounding, frameInset)
        const maxY = parent.height - h - frameInset
        const targetY = Math.max(minY, Math.min(centered, maxY))
        return (targetY + h + frameInset) >= parent.height - 1
    }

    readonly property bool isOpen: GlobalStates.activeBarPopup !== ""

    property bool _effectivelyOpen: false
    onIsOpenChanged: {
        if (isOpen) {
            closeDebounce.stop()
            _effectivelyOpen = true
        } else {
            closeDebounce.restart()
        }
    }
    Timer {
        id: closeDebounce
        interval: 80
        onTriggered: root._effectivelyOpen = false
    }

    property string _lastPopup: ""
    Connections {
        target: GlobalStates
        function onActiveBarPopupChanged() {
            if (GlobalStates.activeBarPopup !== "")
                root._lastPopup = GlobalStates.activeBarPopup
        }
    }

    readonly property var currentPopout: {
        for (const c of slide.children)
            if (c.shouldBeActive && c.item) return c
        for (const c of slide.children)
            if (c.active && c.item) return c
        return null
    }

    property real contentWidth: 0
    property real contentHeight: 0

    function _updateContentDims() {
        if (currentPopout?.item) {
            contentWidth = currentPopout.item.implicitWidth + contentPadding * 2
            contentHeight = currentPopout.item.implicitHeight + contentPadding * 2
        } else if (!currentPopout) {
            contentWidth = 0
            contentHeight = 0
        }
    }
    onCurrentPopoutChanged: _updateContentDims()

    Connections {
        target: root.currentPopout?.item ?? null
        function onImplicitWidthChanged() { root._updateContentDims() }
        function onImplicitHeightChanged() { root._updateContentDims() }
    }
    readonly property real naturalWidth: armpitSize + contentWidth + (hugBottom ? hugSize : 0)
    readonly property real naturalHeight: armpitSize + contentHeight + armpitSize

    property real _targetWidth: 0
    onNaturalWidthChanged: if (currentPopout) _targetWidth = naturalWidth
    property real _animatedWidth: _targetWidth
    Behavior on _animatedWidth {
        LunaeAnim {}
    }

    property real _targetHeight: 0
    onNaturalHeightChanged: if (currentPopout) _targetHeight = naturalHeight
    property real _animatedHeight: _targetHeight
    Behavior on _animatedHeight {
        enabled: root.width > root.armpitSize
        LunaeAnim {}
    }

    property real _smoothPopupY: GlobalStates.barPopupY
    Behavior on _smoothPopupY {
        enabled: root.width > 0
        LunaeAnim {}
    }

    property real progress: _effectivelyOpen && !GlobalStates.screenLocked ? 1 : 0
    Behavior on progress {
        enabled: !GlobalStates.screenLocked
        LunaeAnim {}
    }

    readonly property alias deformX: deform.sx
    readonly property alias deformY: deform.sy

    DeformTracker {
        id: deform
        target: root
        amount: 0.12
    }

    x: barWidth
    y: {
        const h = _animatedHeight
        const centered = _smoothPopupY - h / 2
        const minY = Math.max(Appearance.rounding.screenRounding, root.frameInset)
        const maxY = parent.height - h - root.frameInset
        return Math.max(minY, Math.min(centered, maxY))
    }

    implicitWidth: _animatedWidth * progress
    implicitHeight: _animatedHeight
    visible: width > 0
    clip: true
    transform: Matrix4x4 { matrix: deform.matrix }

    readonly property real bodyX: x + slide.x
    readonly property real bodyWidth: _animatedWidth

    Item {
        id: slide
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root._animatedWidth
        x: -(root._animatedWidth + 5) * (1 - root.progress)
        opacity: root.progress

        Popout { name: "clock"; source: "../popups/ClockPopupContent.qml" }
        Popout { name: "resources"; source: "../popups/ResourcesPopupContent.qml" }
        Popout { name: "weather"; source: "../popups/WeatherPopupContent.qml" }
        Popout { name: "battery"; source: "../popups/BatteryPopupContent.qml" }
        Popout { name: "tray"; source: "../popups/TrayPopupContent.qml" }
        Popout { name: "tray_menu"; source: "../popups/TrayMenuPopupContent.qml" }
        Popout { name: "media"; source: "../popups/MediaPopupContent.qml" }
        Popout { name: "power"; source: "../popups/PowerPopupContent.qml" }
    }

    HoverHandler { id: hoverHandler }

    component Popout: Loader {
        id: popout

        required property string name
        readonly property bool shouldBeActive: GlobalStates.activeBarPopup === popout.name
            || (GlobalStates.activeBarPopup === "" && root._lastPopup === popout.name && root.visible)

        anchors.verticalCenter: parent.verticalCenter
        x: root.armpitSize + root.contentPadding

        opacity: 0
        scale: 0.8
        active: false

        states: State {
            name: "active"
            when: popout.shouldBeActive

            PropertyChanges {
                popout.active: true
                popout.opacity: 1
                popout.scale: 1
            }
        }

        transitions: [
            Transition {
                from: "active"
                to: ""

                SequentialAnimation {
                    NumberAnimation {
                        properties: "opacity,scale"
                        duration: 200
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.standard
                    }
                    PropertyAction {
                        target: popout
                        property: "active"
                    }
                }
            },
            Transition {
                from: ""
                to: "active"

                SequentialAnimation {
                    PropertyAction {
                        target: popout
                        property: "active"
                    }
                    NumberAnimation {
                        properties: "opacity,scale"
                        duration: 300
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.animationCurves.standardDecel
                    }
                }
            }
        ]
    }
}
