import QtQuick
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae.sidebarRight.volumeMixer

Column {
    property real maxListHeight: 200
    width: parent?.width ?? 0
    spacing: 4
    topPadding: 4

    ListView {
        width: parent.width
        height: Math.min(contentHeight, maxListHeight)
        clip: true
        spacing: 4
        model: ScriptModel { values: Audio.outputAppNodes }
        delegate: VolumeMixerEntry {
            required property var modelData
            node: modelData
            width: ListView.view?.width ?? 0
        }
    }

    StyledText {
        visible: Audio.outputAppNodes.length === 0
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        topPadding: 12
        bottomPadding: 12
        text: Translation.tr("No applications")
        color: Appearance.colors.colSubtext
    }

    StyledComboBox {
        id: outputDeviceCombo
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.8
        implicitHeight: 30
        buttonRadius: Appearance.rounding.small
        buttonIcon: "media_output"
        font.pixelSize: Appearance.font.pixelSize.small
        model: Audio.outputDevices.map(node => Audio.friendlyDeviceName(node))
        currentIndex: Audio.outputDevices.findIndex(item => item.id === Audio.sink?.id)
        onActivated: (index) => Audio.setDefaultSink(Audio.outputDevices[index])
        Component.onCompleted: popup.y = Qt.binding(() => -popup.height - 4)
        Connections {
            target: outputDeviceCombo.popup
            function onVisibleChanged() {
                GlobalStates.sidebarRightPinned = outputDeviceCombo.popup.visible
            }
        }
    }
}
