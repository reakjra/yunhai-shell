import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Quickshell
import Quickshell.Bluetooth

AkToggle {
    shown: BluetoothStatus.available
    on: BluetoothStatus.enabled
    icon: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
    onClicked: Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter?.enabled
    altAction: () => Quickshell.execDetached(["bash", "-c", `${Config.options.apps.bluetooth}`])
    StyledToolTip {
        text: Translation.tr("%1 | Right-click for devices, hold to configure").arg(
            (BluetoothStatus.firstActiveDevice?.name ?? Translation.tr("Bluetooth"))
            + (BluetoothStatus.activeDeviceCount > 1 ? ` +${BluetoothStatus.activeDeviceCount - 1}` : ""))
    }
}
