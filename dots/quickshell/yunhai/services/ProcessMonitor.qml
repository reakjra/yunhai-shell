pragma Singleton

import QtQuick
import Quickshell
import Yunhai.Sys

Singleton {
    id: root

    readonly property int sortByCpu: ProcessTable.Cpu
    readonly property int sortByMemory: ProcessTable.Memory
    readonly property int sortByName: ProcessTable.Name

    property bool active: false
    property string filter: ""
    property int sortKey: root.sortByCpu
    property bool sortDescending: true

    readonly property var processes: ProcessTable.processes
    readonly property int totalCount: ProcessTable.totalCount
    readonly property bool updating: false

    onActiveChanged: ProcessTable.active = root.active
    onFilterChanged: ProcessTable.filter = root.filter
    onSortKeyChanged: ProcessTable.sortKey = root.sortKey
    onSortDescendingChanged: ProcessTable.sortDescending = root.sortDescending

    function killProcess(pid) {
        ProcessTable.kill(Number(pid));
    }

    function forceKillProcess(pid) {
        ProcessTable.forceKill(Number(pid));
    }
}
