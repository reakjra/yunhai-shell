pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae.bar

Row {
    id: root
    spacing: 12

    Repeater {
        model: TrayService.unpinnedItems

        delegate: SysTrayItem {
            required property SystemTrayItem modelData
            item: modelData
        }
    }
}
