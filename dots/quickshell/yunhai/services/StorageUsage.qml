pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Yunhai

Singleton {
    id: root

    property string selectedDevice: ""

    readonly property list<var> devices: {
        const out = [];
        for (let i = 0; i < SysMon.storageDevices.length; i++) {
            out.push({
                device: SysMon.storageDevices[i],
                mountPoint: SysMon.storageMounts[i],
                total: SysMon.storageTotal[i],
                used: SysMon.storageUsed[i],
                usage: SysMon.storageUsages[i]
            });
        }
        return out;
    }

    readonly property var selected: root.devices.find(d => d.device === root.selectedDevice) ?? root.devices[0] ?? null

    function formatGiB(bytes: real): string {
        return (Math.max(0, bytes) / (1024 * 1024 * 1024)).toFixed(1);
    }

    Binding {
        target: SysMon
        property: "pollStorage"
        value: true
    }
}
