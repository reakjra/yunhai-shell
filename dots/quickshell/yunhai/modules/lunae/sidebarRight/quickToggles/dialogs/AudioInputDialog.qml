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
        model: ScriptModel { values: Audio.inputAppNodes }
        delegate: VolumeMixerEntry {
            required property var modelData
            node: modelData
            width: ListView.view?.width ?? 0
        }
    }

    StyledText {
        visible: Audio.inputAppNodes.length === 0
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        topPadding: 12
        bottomPadding: 12
        text: Translation.tr("No applications")
        color: Appearance.colors.colSubtext
    }

    StyledComboBox {
        id: inputDeviceCombo
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.8
        implicitHeight: 30
        buttonRadius: Appearance.rounding.small
        buttonIcon: "mic_external_on"
        font.pixelSize: Appearance.font.pixelSize.small
        model: Audio.inputDevices.map(node => Audio.friendlyDeviceName(node))
        currentIndex: Audio.inputDevices.findIndex(item => item.id === Audio.source?.id)
        onActivated: (index) => Audio.setDefaultSource(Audio.inputDevices[index])
        Component.onCompleted: popup.y = Qt.binding(() => -popup.height - 4)
        Connections {
            target: inputDeviceCombo.popup
            function onVisibleChanged() {
                GlobalStates.sidebarRightPinned = inputDeviceCombo.popup.visible
            }
        }
    }
}
