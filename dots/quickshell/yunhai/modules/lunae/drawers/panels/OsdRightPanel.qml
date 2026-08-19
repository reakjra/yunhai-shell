pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae
import qs.modules.lunae.widgets
import Quickshell
import Quickshell.Hyprland

Item {
    id: root

    required property real frameInset
    required property real sidebarWidth

    readonly property bool showBoth: Config.options.lunae?.osd?.showBoth ?? false
    readonly property string gifSource: Config.options.lunae?.osd?.gifSource ?? ""
    readonly property bool hasGif: gifSource !== ""
    readonly property real gifNudgeUp: Config.options.lunae?.osd?.gifNudgeUp ?? 0
    readonly property real gifNudgeRight: Config.options.lunae?.osd?.gifNudgeRight ?? 0

    readonly property real armpitSize: LunaeAppearance.rounding.armpit
    readonly property real cornerSize: LunaeAppearance.rounding.panelLarge
    readonly property real padding: 12
    readonly property real sliderThickness: 30
    readonly property real sliderHeight: 150
    readonly property real gifSize: 72

    readonly property real contentWidth: sliderThickness + padding * 2
    readonly property real contentHeight: {
        let h = (showBoth ? 2 : 1) * sliderHeight + padding * 2
        if (showBoth) h += padding
        if (hasGif) h += gifSize + padding
        return h
    }
    readonly property real naturalWidth: contentWidth
    readonly property real naturalHeight: contentHeight + armpitSize * 2

    readonly property bool shouldShow: GlobalStates.osdVolumeOpen
        && (Config.options.lunae?.osd?.positionRight ?? false)

    property alias hoverHandler: hoverHandler

    anchors.right: parent.right
    anchors.rightMargin: root.frameInset + root.sidebarWidth
    anchors.verticalCenter: parent.verticalCenter

    implicitWidth: shouldShow ? naturalWidth : 0
    implicitHeight: naturalHeight
    visible: width > 0
    clip: width < naturalWidth

    Behavior on implicitWidth {
        NumberAnimation {
            duration: LunaeAppearance.osd.duration
            easing.type: LunaeAppearance.osd.easingType
            easing.bezierCurve: LunaeAppearance.osd.curve
        }
    }

    property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
    property var brightnessMonitor: Brightness.getMonitorForScreen(focusedScreen)

    readonly property bool isVolume: GlobalStates.osdCurrentIndicator === "volume"
    readonly property bool isGamma: GlobalStates.osdCurrentIndicator === "gamma"
    readonly property real volumeValue: Audio.sink?.audio.volume ?? 0
    readonly property real brightnessValue: brightnessMonitor?.brightness ?? 0.5
    readonly property real gammaValue: Hyprsunset.gamma / 100
    readonly property string volumeIcon: (Audio.sink?.audio.muted || volumeValue === 0) ? "volume_off" : "volume_up"
    readonly property string brightnessIcon: Hyprsunset?.temperatureActive ? "routine" : "light_mode"
    readonly property string gammaIcon: "wb_twilight"

    readonly property string primaryIcon: showBoth || isVolume ? volumeIcon : isGamma ? gammaIcon : brightnessIcon
    readonly property real primaryValue: showBoth || isVolume ? volumeValue : isGamma ? gammaValue : brightnessValue

    function setPrimaryValue(v: real) {
        if (showBoth || isVolume)
            Audio.sink.audio.volume = v
        else if (isGamma)
            Hyprsunset.setGamma(v * 100)
        else
            brightnessMonitor?.setBrightness(v)
    }

    ColumnLayout {
        anchors.left: parent.left
        anchors.leftMargin: root.padding
        anchors.verticalCenter: parent.verticalCenter
        width: root.contentWidth - root.padding * 2
        height: root.contentHeight - root.padding * 2
        spacing: root.padding

            FilledSlider {
                orientation: Qt.Vertical
                Layout.preferredWidth: root.sliderThickness
                Layout.preferredHeight: root.sliderHeight
                Layout.alignment: Qt.AlignHCenter
                icon: root.primaryIcon
                value: root.primaryValue
                to: root.isVolume || root.showBoth ? Audio.maxVolume : 1
                onMoved: root.setPrimaryValue(value)
            }

            Item {
                visible: root.hasGif
                Layout.preferredWidth: root.sliderThickness
                Layout.preferredHeight: root.gifSize
                Layout.alignment: Qt.AlignHCenter

                AnimatedImage {
                    width: root.gifSize
                    height: root.gifSize
                    anchors.centerIn: parent
                    playing: root.visible
                    source: root.gifSource
                    asynchronous: true
                    fillMode: AnimatedImage.PreserveAspectFit
                    transform: Translate { x: -root.gifNudgeRight; y: -root.gifNudgeUp }
                }
            }

            Loader {
            active: root.showBoth
            visible: active
            Layout.preferredWidth: root.sliderThickness
            Layout.preferredHeight: root.sliderHeight
            Layout.alignment: Qt.AlignHCenter

            sourceComponent: FilledSlider {
                orientation: Qt.Vertical
                icon: root.brightnessIcon
                value: root.brightnessValue
                onMoved: root.brightnessMonitor?.setBrightness(value)
            }
        }
    }

    HoverHandler {
        id: hoverHandler
        onHoveredChanged: GlobalStates.osdHovered = hovered
    }
}
