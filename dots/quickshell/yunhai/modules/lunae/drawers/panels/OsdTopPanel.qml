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
    required property real hubBottom

    readonly property bool showBoth: Config.options.lunae?.osd?.showBoth ?? false
    readonly property string gifSource: Config.options.lunae?.osd?.gifSource ?? ""
    readonly property bool hasGif: gifSource !== ""
    readonly property real gifNudgeUp: Config.options.lunae?.osd?.gifNudgeUp ?? 0
    readonly property real gifNudgeRight: Config.options.lunae?.osd?.gifNudgeRight ?? 0

    readonly property real armpitSize: LunaeAppearance.rounding.armpit
    readonly property real cornerSize: LunaeAppearance.rounding.panelLarge
    readonly property real padding: 12
    readonly property real sliderThickness: 30
    readonly property real sliderWidth: 150
    readonly property real gifSize: 72

    readonly property real contentWidth: {
        let w = (showBoth ? 2 : 1) * sliderWidth + padding * 2
        if (showBoth) w += padding
        if (hasGif) w += gifSize + padding
        return w
    }
    readonly property real contentHeight: sliderThickness + padding * 2
    readonly property real naturalHeight: contentHeight

    readonly property bool shouldShow: GlobalStates.osdVolumeOpen
        && !(Config.options.lunae?.osd?.positionRight ?? false)

    property alias hoverHandler: hoverHandler

    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.max(root.frameInset, root.hubBottom)

    implicitWidth: contentWidth + armpitSize * 2
    implicitHeight: shouldShow ? naturalHeight : 0
    visible: height > 0
    clip: height < naturalHeight

    Behavior on implicitHeight {
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

    RowLayout {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.padding
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.contentWidth - root.padding * 2
        height: root.contentHeight - root.padding * 2
        spacing: root.padding

        FilledSlider {
            orientation: Qt.Horizontal
            Layout.preferredWidth: root.sliderWidth
            Layout.preferredHeight: root.sliderThickness
            Layout.alignment: Qt.AlignVCenter
            icon: root.primaryIcon
            value: root.primaryValue
            to: root.isVolume || root.showBoth ? Audio.maxVolume : 1
            onMoved: root.setPrimaryValue(value)
        }

        Item {
            visible: root.hasGif
            Layout.preferredWidth: root.gifSize
            Layout.preferredHeight: root.sliderThickness
            Layout.alignment: Qt.AlignVCenter

            AnimatedImage {
                width: root.gifSize
                height: root.gifSize
                anchors.centerIn: parent
                playing: root.visible
                source: root.gifSource
                asynchronous: true
                fillMode: AnimatedImage.PreserveAspectFit
                transform: Translate { x: root.gifNudgeRight; y: -root.gifNudgeUp }
            }
        }

        Loader {
            active: root.showBoth
            visible: active
            Layout.preferredWidth: root.sliderWidth
            Layout.preferredHeight: root.sliderThickness
            Layout.alignment: Qt.AlignVCenter

            sourceComponent: FilledSlider {
                orientation: Qt.Horizontal
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
