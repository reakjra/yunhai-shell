import qs.modules.common
import qs.modules.akebono.shelf.widgets
import Quickshell.Io

ShelfPrivacyPill {
    id: root
    icon: "screen_share"
    active: root.appName.length > 0 && !root.appName.toLowerCase().includes("none")
    tooltipText: root.active ? Translation.tr("%1 is using your screen").arg(root.appName) : ""

    property string appName: ""

    Process {
        running: true
        command: ["bash", "-c", `exec ${Directories.screenshareStateScript}`]
    }

    FileView {
        id: stateFile
        path: Directories.screenshareStatePath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.appName = stateFile.text().trim()
    }
}
