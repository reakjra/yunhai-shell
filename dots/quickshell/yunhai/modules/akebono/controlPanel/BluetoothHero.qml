import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

HeroCard {
    id: root

    readonly property bool discoverable: BluetoothStatus.adapter?.discoverable ?? false

    title: {
        if (!BluetoothStatus.available)
            return Translation.tr("No Bluetooth adapter");
        if (!BluetoothStatus.enabled)
            return Translation.tr("Bluetooth is off");
        return BluetoothStatus.adapter?.name ?? "";
    }
    subtitle: {
        if (!BluetoothStatus.enabled)
            return Translation.tr("Turn it on to connect your devices");
        if (BluetoothStatus.activeDeviceCount > 0)
            return Translation.tr("%1 connected").arg(BluetoothStatus.activeDeviceCount);
        return Translation.tr("No devices connected");
    }
    switchChecked: BluetoothStatus.enabled
    onSwitchToggled: checked => BluetoothStatus.setEnabled(checked)

    glyph: MaterialSymbol {
        anchors.centerIn: parent
        text: !BluetoothStatus.enabled ? "bluetooth_disabled" : BluetoothStatus.connected ? "bluetooth_connected" : "bluetooth"
        iconSize: root.glyphSize
        fill: 1
        color: Appearance.colors.colOnPrimaryContainer
    }

    Flow {
        Layout.fillWidth: true
        visible: BluetoothStatus.enabled
        spacing: 6

        Pill {
            clickable: true
            icon: root.discoverable ? "visibility" : "visibility_off"
            text: root.discoverable ? Translation.tr("Visible to nearby devices") : Translation.tr("Hidden from nearby devices")
            tooltip: root.discoverable ? Translation.tr("Hide this computer from other devices") : Translation.tr("Let other devices find this computer")
            onClicked: BluetoothStatus.adapter.discoverable = !root.discoverable
        }
    }
}
