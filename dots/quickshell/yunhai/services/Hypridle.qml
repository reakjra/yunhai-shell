pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions

Singleton {
    id: root

    property string configPath: FileUtils.trimFileProtocol(`${Directories.home}/.config/hypr/hypridle.conf`)
    property bool ready: false
    property bool hasValidIdentifiers: false

    // Timeout properties in minutes
    property int lockTimeout: 5
    property int screenTimeout: 10
    property int suspendTimeout: 15

    // Internal state for preventing loops
    property bool isUpdating: false

    Component.onCompleted: {
        loadConfig()
    }

    function loadConfig() {
        configFileView.reload()
    }

    function parseConfig(content) {
        if (!content) return

        const lines = content.split('\n')
        let listenerIndex = 0

        // Check for all required identifiers
        const hasLockId = content.includes('# LOCK_TIMEOUT')
        const hasScreenId = content.includes('# SCREEN_TIMEOUT')
        const hasSuspendId = content.includes('# SUSPEND_TIMEOUT')

        root.hasValidIdentifiers = hasLockId && hasScreenId && hasSuspendId

        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()

            if (line.startsWith('timeout =')) {
                const match = line.match(/timeout\s*=\s*(\d+)/)
                if (match) {
                    const seconds = parseInt(match[1])
                    const minutes = Math.round(seconds / 60)

                    isUpdating = true
                    if (listenerIndex === 0) {
                        root.lockTimeout = minutes
                    } else if (listenerIndex === 1) {
                        root.screenTimeout = minutes
                    } else if (listenerIndex === 2) {
                        root.suspendTimeout = minutes
                    }
                    isUpdating = false

                    listenerIndex++
                }
            }
        }

        root.ready = true
    }

    function saveConfig() {
        if (isUpdating) return
        if (!root.ready) return

        const lockSeconds = root.lockTimeout * 60
        const screenSeconds = root.screenTimeout * 60
        const suspendSeconds = root.suspendTimeout * 60

        const lockMin = Math.round(lockSeconds / 60)
        const screenMin = Math.round(screenSeconds / 60)
        const suspendMin = Math.round(suspendSeconds / 60)

        // Use sed with range addressing to target specific listeners (smilar to overlay's fps limiter). I think its fine as long as the user follows the default config given with the rice, otherwise it'll just grey out
        const sedCmd1 = `sed -i '/# LOCK_TIMEOUT/,/}/{s/^[[:space:]]*timeout = .*/    timeout = ${lockSeconds} # ${lockMin}min${lockMin !== 1 ? 's' : ''}/}' '${root.configPath}'`
        const sedCmd2 = `sed -i '/# SCREEN_TIMEOUT/,/}/{s/^[[:space:]]*timeout = .*/    timeout = ${screenSeconds} # ${screenMin}min${screenMin !== 1 ? 's' : ''}/}' '${root.configPath}'`
        const sedCmd3 = `sed -i '/# SUSPEND_TIMEOUT/,/}/{s/^[[:space:]]*timeout = .*/    timeout = ${suspendSeconds} # ${suspendMin}min${suspendMin !== 1 ? 's' : ''}/}' '${root.configPath}'`

        const fullCmd = `${sedCmd1}; ${sedCmd2}; ${sedCmd3}; pkill hypridle; hypridle &`

        writeProcess.command = ["bash", "-c", fullCmd]
        writeProcess.startDetached()
    }

    onLockTimeoutChanged: saveConfig()
    onScreenTimeoutChanged: saveConfig()
    onSuspendTimeoutChanged: saveConfig()

    FileView {
        id: configFileView
        path: root.configPath
        onLoaded: {
            parseConfig(text())
        }
    }

    Process {
        id: writeProcess
    }
}
