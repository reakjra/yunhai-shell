pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property int barCount: 50
    property var bars: new Array(root.barCount).fill(0)

    property var _consumers: new Set()
    property int _demand: 0
    readonly property bool active: root._demand > 0

    function acquire(obj) {
        root._consumers.add(obj);
        root._demand = root._consumers.size;
    }
    function release(obj) {
        root._consumers.delete(obj);
        root._demand = root._consumers.size;
    }

    onActiveChanged: {
        if (!root.active)
            root.bars = new Array(root.barCount).fill(0);
    }

    Process {
        running: root.active
        command: ["cava", "-p", Quickshell.shellPath("scripts/cava/raw_output_config.txt").replace("file://", "")]
        stdout: SplitParser {
            onRead: data => {
                const raw = data.split(";").map(x => parseFloat(x)).filter(x => !isNaN(x));
                if (raw.length < 2)
                    return;
                root.bars = raw.map(x => Math.min(1, x / 256));
            }
        }
    }
}
