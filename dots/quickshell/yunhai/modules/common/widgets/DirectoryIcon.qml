import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.functions
import qs.services

// From https://github.com/caelestia-dots/shell with modifications.
// License: GPLv3

Image {
    id: root
    required property var fileModelData
    asynchronous: true
    fillMode: Image.PreserveAspectFit
    sourceSize.width: root.width * root.Screen.devicePixelRatio
    sourceSize.height: root.height * root.Screen.devicePixelRatio

    readonly property string filePath: fileModelData.filePath
    onFilePathChanged: {
        root.probedMime = "";
        root.desktopFileIcon = "";
    }

    readonly property bool isPlainFile: !fileModelData.fileIsDir && !root.isDesktopFile
    readonly property string knownMime: root.isPlainFile ? MimeIcons.mimeFor(fileModelData.fileName) : ""
    readonly property string mimeProbeTarget: (root.isPlainFile && MimeIcons.globsLoaded && root.knownMime.length === 0) ? fileModelData.filePath : ""
    property string probedMime: ""
    readonly property string detectedMime: root.knownMime.length > 0 ? root.knownMime : root.probedMime

    readonly property bool isDesktopFile: !fileModelData.fileIsDir && fileModelData.fileName.endsWith(".desktop")
    readonly property string desktopBaseId: root.isDesktopFile ? fileModelData.fileName.slice(0, -8) : ""
    readonly property var desktopEntry: root.isDesktopFile ? (DesktopEntries.byId(root.desktopBaseId) ?? DesktopEntries.heuristicLookup(root.desktopBaseId)) : null
    property string desktopFileIcon: ""

    source: {
        if (fileModelData.fileIsDir) {
            if ([Directories.documents, Directories.downloads, Directories.music, Directories.pictures, Directories.videos].some(dir => FileUtils.trimFileProtocol(dir) === fileModelData.filePath))
                return Quickshell.iconPath(`folder-${fileModelData.fileName.toLowerCase()}`);
            return Quickshell.iconPath("inode-directory");
        }
        if (root.isDesktopFile) {
            if (root.desktopEntry?.icon)
                return Quickshell.iconPath(root.desktopEntry.icon, "application-x-executable");
            if (root.desktopFileIcon.length > 0)
                return root.desktopFileIcon.startsWith("/") ? `file://${root.desktopFileIcon}` : Quickshell.iconPath(root.desktopFileIcon, "application-x-executable");
            return Quickshell.iconPath("application-x-executable");
        }
        if (root.detectedMime.length > 0) {
            if (Images.validImageTypes.some(t => root.detectedMime === `image/${t}`))
                return fileModelData.fileUrl;
            const themeIcon = MimeIcons.iconForMime(root.detectedMime);
            return Quickshell.iconPath(themeIcon.length > 0 ? themeIcon : "text-x-generic");
        }
        return Quickshell.iconPath("application-x-zerosize");
    }

    Image {
        anchors.fill: parent
        visible: root.status === Image.Error
        asynchronous: true
        fillMode: Image.PreserveAspectFit
        source: Quickshell.iconPath("error")
    }

    Process {
        id: mimeProc
        command: ["xdg-mime", "query", "filetype", root.mimeProbeTarget]
        running: root.mimeProbeTarget.length > 0
        stdout: StdioCollector {
            onStreamFinished: {
                const mime = text.trim().split(";")[0];
                if (mime.length > 0)
                    root.probedMime = mime;
            }
        }
    }

    FileView {
        id: desktopFileView
        path: (root.isDesktopFile && !root.desktopEntry?.icon) ? root.fileModelData.filePath : ""
        onLoadedChanged: {
            if (!desktopFileView.loaded)
                return;
            const m = desktopFileView.text().match(/^Icon=(.+)$/m);
            root.desktopFileIcon = m ? m[1].trim() : "";
        }
    }
}
