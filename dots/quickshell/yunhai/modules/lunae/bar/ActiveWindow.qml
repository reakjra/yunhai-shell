pragma ComponentBehavior: Bound

import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: root
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

    property bool focusingThisMonitor: (HyprlandData.activeWorkspace?.monitor ?? "") == (monitor?.name ?? "")
    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(HyprlandData.monitors[root.monitor?.id]?.activeWorkspace.id)

    readonly property bool hasWindow: root.focusingThisMonitor && (root.activeWindow?.activated ?? false) && !!root.biggestWindow

    property string classText: hasWindow
        ? root.activeWindow?.appId
        : (root.biggestWindow?.class) ?? ""

    property string titleText: hasWindow
        ? root.activeWindow?.title
        : (root.biggestWindow?.title) ?? Translation.tr("Desktop")

    readonly property var categoryIcons: ({
        WebBrowser: "web",
        Printing: "print",
        Security: "security",
        Network: "chat",
        Archiving: "archive",
        Compression: "archive",
        Development: "code",
        IDE: "code",
        TextEditor: "edit_note",
        Audio: "music_note",
        Music: "music_note",
        Player: "music_note",
        Recorder: "mic",
        Game: "sports_esports",
        FileTools: "files",
        FileManager: "files",
        Filesystem: "files",
        FileTransfer: "files",
        Settings: "settings",
        DesktopSettings: "settings",
        HardwareSettings: "settings",
        TerminalEmulator: "terminal",
        ConsoleOnly: "terminal",
        Utility: "build",
        Monitor: "monitor_heart",
        Midi: "graphic_eq",
        Mixer: "graphic_eq",
        AudioVideoEditing: "video_settings",
        AudioVideo: "music_video",
        Video: "videocam",
        Building: "construction",
        Graphics: "photo_library",
        "2DGraphics": "photo_library",
        RasterGraphics: "photo_library",
        TV: "tv",
        System: "host",
        Office: "content_paste",
    })

    function getAppCategoryIcon(name) {
        if (!name) return "desktop_windows"
        if (name.startsWith("steam_app_")) return "sports_esports"
        const categories = DesktopEntries.heuristicLookup(name)?.categories
        if (categories)
            for (const [key, value] of Object.entries(categoryIcons))
                if (categories.includes(key))
                    return value
        return "desktop_windows"
    }

    readonly property string iconText: getAppCategoryIcon(classText)
    readonly property color widgetColor: Config.options.lunae.colorful ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1

    implicitWidth: Math.max(icon1.implicitWidth, titleWrapper.width)
    implicitHeight: icon1.implicitHeight + titleWrapper.height + 4

    property Item currentIcon: icon1
    onIconTextChanged: {
        const next = currentIcon === icon1 ? icon2 : icon1
        next.text = iconText
        currentIcon = next
    }

    MaterialSymbol {
        id: icon1
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.iconText
        iconSize: Appearance.font.pixelSize.larger
        color: root.widgetColor
        opacity: root.currentIcon === this ? 1 : 0

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    MaterialSymbol {
        id: icon2
        anchors.horizontalCenter: parent.horizontalCenter
        iconSize: icon1.iconSize
        color: root.widgetColor
        opacity: root.currentIcon === this ? 1 : 0

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }
    }

    property Item currentTitle: title1
    onTitleTextChanged: {
        const next = currentTitle === title1 ? title2 : title1
        next.text = root.titleText
        currentTitle = next
    }

    Item {
        id: titleWrapper
        anchors.top: icon1.bottom
        anchors.topMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.currentTitle.implicitHeight
        height: Math.min(root.currentTitle.implicitWidth, 150)
        clip: true

        StyledText {
            id: title1
            x: implicitHeight
            y: 0
            text: root.titleText
            font.pixelSize: Appearance.font.pixelSize.small
            font.family: Appearance.font.family.main
            color: root.widgetColor
            rotation: 90
            transformOrigin: Item.TopLeft
            opacity: root.currentTitle === this ? 1 : 0

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        StyledText {
            id: title2
            x: implicitHeight
            y: 0
            font: title1.font
            color: root.widgetColor
            rotation: 90
            transformOrigin: Item.TopLeft
            opacity: root.currentTitle === this ? 1 : 0

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }
    }
}
