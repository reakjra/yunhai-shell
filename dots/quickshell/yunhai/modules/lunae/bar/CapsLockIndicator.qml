import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets

MaterialSymbol {
    id: root
    property bool capsLockOn: false

    text: "font_download"
    fill: capsLockOn ? 1 : 0
    iconSize: Appearance.font.pixelSize.larger

    Timer {
        interval: 200
        running: true
        repeat: true
        onTriggered: checkCapsLock.running = true
    }

    Process {
        id: checkCapsLock
        command: ["bash", "-c", "cat /sys/class/leds/*capslock/brightness 2>/dev/null | head -n1"]

        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim()
                root.capsLockOn = (value === "1")
            }
        }
    }
}
