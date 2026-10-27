import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

HeroCard {
    id: root

    readonly property bool muted: Audio.sink?.audio.muted ?? false
    readonly property real volume: Audio.sink?.audio.volume ?? 0

    title: Audio.sink ? Audio.friendlyDeviceName(Audio.sink) : Translation.tr("No output device")
    subtitle: root.muted ? Translation.tr("Muted") : Translation.tr("Volume %1%").arg(Math.round(root.volume * 100))
    switchVisible: Audio.sink !== null
    switchChecked: !root.muted
    onSwitchToggled: Audio.toggleMute()

    glyph: MaterialSymbol {
        anchors.centerIn: parent
        text: root.muted || root.volume === 0 ? "volume_off" : root.volume < 0.34 ? "volume_mute" : root.volume < 0.67 ? "volume_down" : "volume_up"
        iconSize: root.glyphSize
        fill: 1
        color: Appearance.colors.colOnPrimaryContainer
    }

    StyledSlider {
        Layout.fillWidth: true
        visible: Audio.sink !== null
        configuration: StyledSlider.Configuration.M
        value: root.volume
        onMoved: Audio.sink.audio.volume = value
    }
}
