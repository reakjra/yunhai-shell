pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var extensionOverrides: ({
            "luau": "text/x-lua"
        })

    property bool globsLoaded: false
    property var suffixMimes: root.extensionOverrides
    property var literalMimes: ({})
    property var explicitIcons: ({})
    property var genericIcons: ({})

    function mimeFor(fileName: string): string {
        const name = fileName.toLowerCase();
        if (root.literalMimes[name])
            return root.literalMimes[name];
        for (let dot = name.indexOf("."); dot !== -1; dot = name.indexOf(".", dot + 1)) {
            const mime = root.suffixMimes[name.slice(dot + 1)];
            if (mime)
                return mime;
        }
        return "";
    }

    function iconForMime(mime: string): string {
        if (mime.length === 0)
            return "";
        const candidates = [root.explicitIcons[mime], mime.replace("/", "-"), root.genericIcons[mime], `${mime.split("/")[0]}-x-generic`];
        return candidates.find(name => name && Quickshell.hasThemeIcon(name)) ?? "";
    }

    function iconFor(fileName: string): string {
        return root.iconForMime(root.mimeFor(fileName));
    }

    function parseIconMap(text: string): var {
        const map = {};
        for (const line of text.split("\n")) {
            const sep = line.indexOf(":");
            if (sep > 0)
                map[line.slice(0, sep)] = line.slice(sep + 1).trim();
        }
        return map;
    }

    FileView {
        path: "/usr/share/mime/globs2"
        onLoadedChanged: {
            if (!this.loaded)
                return;
            const suffixes = {};
            const literals = {};
            const wildcards = /[*?[]/;
            for (const line of this.text().split("\n")) {
                const parts = line.split(":");
                if (line.startsWith("#") || parts.length < 3)
                    continue;
                const mime = parts[1];
                const pattern = parts[2].toLowerCase();
                // globs2 is sorted by descending weight, so the first match for a key wins
                if (pattern.startsWith("*.") && !wildcards.test(pattern.slice(2))) {
                    const suffix = pattern.slice(2);
                    if (!suffixes[suffix])
                        suffixes[suffix] = mime;
                } else if (!wildcards.test(pattern) && !literals[pattern]) {
                    literals[pattern] = mime;
                }
            }
            root.suffixMimes = Object.assign(suffixes, root.extensionOverrides);
            root.literalMimes = literals;
            root.globsLoaded = true;
        }
    }

    FileView {
        path: "/usr/share/mime/icons"
        onLoadedChanged: if (this.loaded) root.explicitIcons = root.parseIconMap(this.text())
    }

    FileView {
        path: "/usr/share/mime/generic-icons"
        onLoadedChanged: if (this.loaded) root.genericIcons = root.parseIconMap(this.text())
    }
}
