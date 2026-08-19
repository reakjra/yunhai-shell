import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.lunae.widgets

LunaeCard {
    id: root

    property var brightnessMonitor

    Layout.fillWidth: true
    visible: Config.options.lunae.sidebar.sliders.showBrightness || Config.options.lunae.sidebar.sliders.showVolume
    implicitHeight: sliderCol.implicitHeight + 16

    Column {
        id: sliderCol
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 12
            rightMargin: 12
        }
        spacing: 6

        SidebarSlider {
            anchors { left: parent.left; right: parent.right }
            visible: Config.options.lunae.sidebar.sliders.showVolume
            icon: "volume_up"
            value: Audio.sink?.audio?.volume ?? 0
            onMoved: if (Audio.sink?.audio) Audio.sink.audio.volume = value
        }

        SidebarSlider {
            anchors { left: parent.left; right: parent.right }
            visible: Config.options.lunae.sidebar.sliders.showBrightness
            icon: "brightness_6"
            value: root.brightnessMonitor?.brightness ?? 0
            onMoved: root.brightnessMonitor?.setBrightness(value)
        }
    }
}
