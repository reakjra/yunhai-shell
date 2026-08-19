pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Automatically reloads generated material colors.
 * It is necessary to run reapplyTheme() on startup because Singletons are lazily loaded.
 */
Singleton {
    id: root
    property string filePath: Directories.generatedMaterialThemePath
    property string altFilePath: Directories.generatedMaterialThemePath.replace("colors.json", "colors_alt.json")

    // Original theme-file colors before any overrides are applied
    property var themeColors: ({})
    // Alt mode base colors (light if current is dark, dark if current is light)
    property var altThemeColors: ({})
    property bool _wallpaperChanging: false
    property bool _gtkDirty: false

    function reapplyTheme() {
        themeFileView.reload()
    }

    function scheduleForceReload() {
        pipelineCompleteTimer.restart()
    }

    // central dark/light mode switch
    function switchDarkLightMode(dark) {
        if (Appearance.m3colors.darkmode === dark) return
        Config.options.appearance.palette.mode = dark ? "dark" : "light"

        Quickshell.execDetached(["bash", "-c",
            `gsettings set org.gnome.desktop.interface color-scheme '${dark ? "prefer-dark" : "prefer-light"}'; ` +
            `gsettings set org.gnome.desktop.interface gtk-theme '${dark ? "adw-gtk3-dark" : "adw-gtk3"}'`])

        // Swap base colors to target mode
        if (Object.keys(root.altThemeColors).length > 0) {
            const oldTheme = root.themeColors
            root.themeColors = Object.assign({}, root.themeColors, root.altThemeColors)
            root.altThemeColors = oldTheme
        }

        if (tryApplyPresetForMode(dark)) {
            Appearance.m3colors.darkmode = dark
            Quickshell.execDetached(["bash", "-c",
                `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`])
            scheduleForceReload()
            return
        }

        const overrides = ColorOverrideStore.data?.colorOverrides ?? "{}"
        if (overrides !== "{}") {
            ColorOverrideStore.data.colorOverrides = "{}"
        } else {
            root.refreshColors()
        }

        Appearance.m3colors.darkmode = dark
        Quickshell.execDetached(["bash", "-c",
            `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`])
        scheduleForceReload()
    }

    // Transform raw colors.json keys to m3-prefixed camelCase
    function transformColorKeys(json) {
        const result = {}
        for (const key in json) {
            if (json.hasOwnProperty(key)) {
                const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
                const propKey = (key.startsWith("term") || key.startsWith("kde") || key.startsWith("gtk")) ? camelCaseKey : `m3${camelCaseKey}`
                result[propKey] = json[key]
            }
        }
        return result
    }

    function applyColors(fileContent) {
        let json
        try { json = JSON.parse(fileContent) } catch (e) { return }

        const originals = {}
        for (const key in json) {
            if (!json.hasOwnProperty(key)) continue
            const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
            const propKey = (key.startsWith("term") || key.startsWith("kde") || key.startsWith("gtk")) ? camelCaseKey : `m3${camelCaseKey}`
            Appearance.m3colors[propKey] = json[key]
            originals[propKey] = json[key]
        }

        // GTK fallback defaults
        const gtkDefaults = {
            gtkAccent: "#c9c4d6", gtkAccentFg: "#312f3c",
            gtkWindowBg: "#141315", gtkWindowFg: "#e5e1e3",
            gtkHeaderbarBg: "#141315", gtkHeaderbarFg: "#e5e1e3",
            gtkViewBg: "#141315", gtkViewFg: "#e5e1e3",
            gtkCardBg: "#141315", gtkCardFg: "#e5e1e3",
            gtkPopoverBg: "#141315", gtkPopoverFg: "#e5e1e3",
        }
        for (const k in gtkDefaults) {
            if (!(k in originals)) {
                Appearance.m3colors[k] = gtkDefaults[k]
                originals[k] = gtkDefaults[k]
            }
        }

        root.themeColors = originals
        root._gtkDirty = true
        applyColorOverrides()
    }

    function applyColorOverrides() {
        const raw = ColorOverrideStore.data?.colorOverrides
        let hasKdeOverride = false
        let hasGtkOverride = false
        if (raw && raw !== "{}") {
            try {
                const overrides = JSON.parse(raw)
                for (const key in overrides) {
                    if (overrides[key]) {
                        Appearance.m3colors[key] = overrides[key]
                        if (key.startsWith("kde")) hasKdeOverride = true
                        if (key.startsWith("gtk")) hasGtkOverride = true
                    }
                }
            } catch (e) {}
        }
        Appearance.m3colors.darkmode = (Appearance.m3colors.m3background.hslLightness < 0.5)

        if (Config.options?.appearance?.wallpaperTheming?.enableTerminal ?? true)
            terminalApplyTimer.restart()
        if (Config.options?.appearance?.wallpaperTheming?.enableQtApps ?? true)
            kdeApplyTimer.restart()
        if (Config.options?.appearance?.wallpaperTheming?.enableAppsAndShell ?? true)
            gtkApplyTimer.restart()
    }

    function refreshColors() {
        for (const key in root.themeColors) {
            Appearance.m3colors[key] = root.themeColors[key]
        }
        applyColorOverrides()
    }

    function resetOverridesUnlessPreserved() {
        if (ColorOverrideStore.data?.preserveOnWallpaperChange) return
        if ((ColorOverrideStore.data?.colorOverrides ?? "{}") !== "{}")
            ColorOverrideStore.data.colorOverrides = "{}"
        if ((ColorOverrideStore.data?.activePresetIndex ?? -1) !== -1)
            ColorOverrideStore.data.activePresetIndex = -1
    }

    // Check if active preset has a variant for the target mode and apply it
    function tryApplyPresetForMode(dark) {
        const idx = ColorOverrideStore.data?.activePresetIndex ?? -1
        if (idx < 0) return false
        let presets
        try { presets = JSON.parse(ColorOverrideStore.data?.customPresets ?? "[]") }
        catch (e) { return false }
        if (idx >= presets.length) return false
        const preset = presets[idx]
        const targetKey = dark ? "dark" : "light"
        const targetColors = preset[targetKey]
        if (!targetColors || Object.keys(targetColors).length === 0) return false
        ColorOverrideStore.data.colorOverrides = JSON.stringify(targetColors)
        return true
    }

    function ensureColor(c) {
        return (typeof c === 'string' || c instanceof String) ? Qt.color(c) : c
    }

    function toHex6(c) {
        c = ensureColor(c)
        function h(v) { return Math.round(v * 255).toString(16).padStart(2, '0') }
        return "#" + h(c.r) + h(c.g) + h(c.b)
    }

    function toHex6Plain(c) {
        c = ensureColor(c)
        function h(v) { return Math.round(v * 255).toString(16).padStart(2, '0') }
        return h(c.r) + h(c.g) + h(c.b)
    }

    function applyToActiveTerminals() {
        let seq = ""
        for (let i = 0; i < 16; i++) {
            const hex = toHex6Plain(Appearance.m3colors["term" + i])
            seq += `\\x1b]4;${i};#${hex}\\x07`
        }
        const fg = toHex6Plain(Appearance.m3colors.term7)
        const bg = toHex6Plain(Appearance.m3colors.term0)
        seq += `\\x1b]10;#${fg}\\x07\\x1b]11;#${bg}\\x07`
        const seqFile = `\${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/yunhai/user/generated/terminal/sequences.txt`
        Quickshell.execDetached(["bash", "-c",
            `printf '${seq}' > "${seqFile}"; for f in /dev/pts/[0-9]*; do printf '${seq}' > "$f" 2>/dev/null & done`])
    }

    // Override-aware kitty theme writer.
    // Mirrors scripts/colors/terminal/kitty-theme.conf but uses Appearance.m3colors
    // (which has manual color picker overrides applied), then SIGUSR1s kitty to reload.
    function applyToKitty() {
        function h(name) { return toHex6Plain(Appearance.m3colors[name]) }
        const lines = [
            `background            #${h("term0")}`,
            ``,
            `color0                #${h("term0")}`,
            `color1                #${h("term1")}`,
            `color2                #${h("term2")}`,
            `color3                #${h("term3")}`,
            `color4                #${h("term4")}`,
            `color5                #${h("term5")}`,
            `color6                #${h("term6")}`,
            `color7                #${h("term7")}`,
            `color8                #${h("term8")}`,
            `color9                #${h("term9")}`,
            `color10               #${h("term10")}`,
            `color11               #${h("term11")}`,
            `color12               #${h("term12")}`,
            `color13               #${h("term13")}`,
            `color14               #${h("term14")}`,
            `color15               #${h("term15")}`,
            ``,
            `cursor                #${h("term7")}`,
            ``,
            `foreground            #${h("term7")}`,
            ``,
            `selection_background  #${h("m3onSecondaryContainer")}`,
            `selection_foreground  #${h("m3secondaryContainer")}`,
            ``,
            `# Override obscure colors for starship prompt (these are greys at the end)`,
            `color255              #${h("m3primary")}`,
            `color254              #${h("m3primaryContainer")}`,
            `color253              #${h("m3secondary")}`,
            `color252              #${h("m3secondaryContainer")}`,
            `color251              #${h("m3tertiary")}`,
            `color250              #${h("m3tertiaryContainer")}`,
            `color249              #${h("m3error")}`,
            `color248              #${h("m3errorContainer")}`,
            ``,
            `color232              #${h("m3onPrimary")}`,
            `color233              #${h("m3onPrimaryContainer")}`,
            `color234              #${h("m3onSecondary")}`,
            `color235              #${h("m3onSecondaryContainer")}`,
            `color236              #${h("m3onTertiary")}`,
            `color237              #${h("m3onTertiaryContainer")}`,
            `color238              #${h("m3onError")}`,
            `color239              #${h("m3onErrorContainer")}`,
            `color240              #${h("m3onPrimary")} // Somehow 232 doesn't work so i gotta use another number`,
            ``,
            `# Some stuff should specifically use the colors in the middle so they look acceptable in both unthemed light/dark`,
            `color243              #${h("m3primary")}`,
            `color244              #${h("m3error")}`,
            `color245              #${h("m3outlineVariant")}`,
            ``,
        ]
        const contentB64 = Qt.btoa(lines.join("\n"))
        Quickshell.execDetached(["python3", "-c", `
import os, base64, signal, subprocess
content = base64.b64decode("${contentB64}").decode()
path = os.path.expanduser("~/.local/state/quickshell/yunhai/user/generated/terminal/kitty-theme.conf")
os.makedirs(os.path.dirname(path), exist_ok=True)
tmp = path + ".tmp"
with open(tmp, "w") as f:
    f.write(content)
os.replace(tmp, path)
try:
    out = subprocess.check_output(["pidof", "kitty"], stderr=subprocess.DEVNULL)
    for p in out.decode().split():
        try: os.kill(int(p), signal.SIGUSR1)
        except Exception: pass
except Exception: pass
`])
    }

    function applyToKdeglobals() {
        const toRgb = (c) => {
            c = ensureColor(c)
            return `${Math.round(c.r * 255)},${Math.round(c.g * 255)},${Math.round(c.b * 255)}`
        }
        const allSections = [
            "Colors:View", "Colors:Window", "Colors:Button",
            "Colors:Selection", "Colors:Complementary", "Colors:Header",
            "Colors:Header][Inactive", "Colors:Tooltip"
        ]
        const mapping = {
            kdeViewBg: [["Colors:View", "BackgroundNormal"]],
            kdeViewAltBg: [["Colors:View", "BackgroundAlternate"], ["Colors:Header", "BackgroundAlternate"], ["Colors:Header][Inactive", "BackgroundAlternate"]],
            kdeWindowBg: [["Colors:Window", "BackgroundNormal"], ["Colors:Header", "BackgroundNormal"], ["Colors:Header][Inactive", "BackgroundNormal"]],
            kdeWindowAltBg: [["Colors:Window", "BackgroundAlternate"]],
            kdeButtonBg: [["Colors:Button", "BackgroundNormal"]],
            kdeButtonAltBg: [["Colors:Button", "BackgroundAlternate"]],
            kdeSelectionBg: [["Colors:Selection", "BackgroundNormal"], ["Colors:Selection", "BackgroundAlternate"]],
            kdeSelectionText: [["Colors:Selection", "ForegroundNormal"]],
            kdeTitlebarBg: [["WM", "activeBackground"]],
            kdeTitlebarText: [["WM", "activeForeground"]],
            kdeInactiveTitlebarBg: [["WM", "inactiveBackground"]],
            kdeInactiveTitlebarText: [["WM", "inactiveForeground"]],
            kdeViewText: [["Colors:View", "ForegroundNormal"], ["Colors:Button", "ForegroundNormal"]],
            kdeWindowText: [["Colors:Window", "ForegroundNormal"], ["Colors:Header", "ForegroundNormal"], ["Colors:Header][Inactive", "ForegroundNormal"]],
            kdeTooltipBg: [["Colors:Tooltip", "BackgroundNormal"], ["Colors:Tooltip", "BackgroundAlternate"]],
            kdeTooltipText: [["Colors:Tooltip", "ForegroundNormal"]],
            kdeComplementaryBg: [["Colors:Complementary", "BackgroundNormal"], ["Colors:Complementary", "BackgroundAlternate"]],
            kdeComplementaryText: [["Colors:Complementary", "ForegroundNormal"]],
        }
        const broadKeys = {
            kdeInactiveText: "ForegroundInactive",
            kdeLinkText: "ForegroundLink",
            kdeVisitedText: "ForegroundVisited",
            kdeErrorText: "ForegroundNegative",
            kdeWarningText: "ForegroundNeutral",
            kdeSuccessText: "ForegroundPositive",
        }
        for (const kdeKey in broadKeys) {
            mapping[kdeKey] = allSections.map(s => [s, broadKeys[kdeKey]])
        }
        mapping.kdeAccent = [["General", "AccentColor"]]
        for (const s of allSections) {
            mapping.kdeAccent.push([s, "DecorationFocus"], [s, "DecorationHover"], [s, "ForegroundActive"])
        }

        const colors = {}
        for (const kdeKey in mapping) {
            const color = Appearance.m3colors[kdeKey]
            if (!color) continue
            colors[kdeKey] = { hex: toHex6(color), rgb: toRgb(color) }
        }

        const kdeUpdates = {}
        const schemeUpdates = {}
        for (const kdeKey in mapping) {
            if (!colors[kdeKey]) continue
            const { hex, rgb } = colors[kdeKey]
            for (const [section, iniKey] of mapping[kdeKey]) {
                const lookup = section + "|" + iniKey
                const useRgb = iniKey === "AccentColor" || iniKey === "DecorationFocus" ||
                               iniKey === "DecorationHover" || iniKey === "ForegroundActive" ||
                               section === "WM"
                kdeUpdates[lookup] = useRgb ? rgb : hex
                schemeUpdates[lookup] = section === "WM" ? "#ff" + hex.slice(1) : hex
            }
        }

        const kdeJson = JSON.stringify(kdeUpdates).replace(/'/g, "'\\''")
        const schemeJson = JSON.stringify(schemeUpdates).replace(/'/g, "'\\''")
        Quickshell.execDetached(["python3", "-c", `
import re, json, sys, os, subprocess
kde_updates = json.loads('${kdeJson}')
scheme_updates = json.loads('${schemeJson}')

def update_ini(path, updates):
    try:
        with open(path) as f:
            lines = f.readlines()
    except FileNotFoundError:
        return
    u = dict(updates)
    by_section = {}
    for lookup, val in list(u.items()):
        sec, key = lookup.split('|', 1)
        by_section.setdefault(sec, {})[key] = val
    section = ''
    out = []
    for line in lines:
        stripped = line.strip()
        m = re.match(r'^\\[(.+)\\]$', stripped)
        if m:
            if section in by_section:
                for key, val in by_section.pop(section).items():
                    out.append(key + '=' + val + '\\n')
            section = m.group(1)
            out.append(line)
        elif '=' in stripped and section:
            key = stripped.split('=', 1)[0]
            lookup = section + '|' + key
            if lookup in u:
                out.append(key + '=' + u.pop(lookup) + '\\n')
                by_section.get(section, {}).pop(key, None)
            else:
                out.append(line)
        else:
            out.append(line)
    if section in by_section:
        for key, val in by_section.pop(section).items():
            out.append(key + '=' + val + '\\n')
    with open(path, 'w') as f:
        f.writelines(out)

scheme_name = ''
try:
    with open(os.path.expanduser('~/.config/kdeglobals')) as f:
        in_general = False
        for line in f:
            if line.strip() == '[General]':
                in_general = True
            elif line.strip().startswith('['):
                in_general = False
            elif in_general and line.startswith('ColorScheme='):
                scheme_name = line.strip().split('=', 1)[1]
                break
except Exception:
    pass

accent_val = kde_updates.pop('General|AccentColor', '')
update_ini(os.path.expanduser('~/.config/kdeglobals'), kde_updates)
if scheme_name:
    scheme_path = os.path.expanduser(f'~/.local/share/color-schemes/{scheme_name}.colors')
    update_ini(scheme_path, scheme_updates)

if accent_val:
    subprocess.run(['kwriteconfig6', '--file', 'kdeglobals', '--group', 'General',
        '--key', 'AccentColor', '--notify', accent_val], check=False)
subprocess.run(['dbus-send', '--session', '--type=signal',
    '/KGlobalSettings', 'org.kde.KGlobalSettings.notifyChange',
    'int32:0', 'int32:0'], check=False)
`])
    }

    function applyToGtkCss() {
        const raw = ColorOverrideStore.data?.colorOverrides
        let hasGtkOverride = false
        if (raw && raw !== "{}") {
            try {
                const overrides = JSON.parse(raw)
                for (const key in overrides) {
                    if (key.startsWith("gtk")) { hasGtkOverride = true; break }
                }
            } catch (e) {}
        }
        if (!hasGtkOverride && !root._gtkDirty) return
        root._gtkDirty = hasGtkOverride

        const mapping = {
            gtkAccent: ["accent_color", "accent_bg_color"],
            gtkAccentFg: ["accent_fg_color"],
            gtkWindowBg: ["window_bg_color"],
            gtkWindowFg: ["window_fg_color"],
            gtkHeaderbarBg: ["headerbar_bg_color"],
            gtkHeaderbarFg: ["headerbar_fg_color"],
            gtkViewBg: ["view_bg_color"],
            gtkViewFg: ["view_fg_color"],
            gtkCardBg: ["card_bg_color"],
            gtkCardFg: ["card_fg_color"],
            gtkPopoverBg: ["popover_bg_color"],
            gtkPopoverFg: ["popover_fg_color"],
        }
        const updates = {}
        for (const gtkKey in mapping) {
            const color = Appearance.m3colors[gtkKey]
            if (!color) continue
            const hex = toHex6(color)
            for (const cssName of mapping[gtkKey]) {
                updates[cssName] = hex
            }
        }
        const updatesJson = JSON.stringify(updates).replace(/'/g, "'\\''")
        Quickshell.execDetached(["python3", "-c", `
import re, json, os
updates = json.loads('${updatesJson}')
def update_css(path):
    try:
        with open(path) as f:
            css = f.read()
    except FileNotFoundError:
        return
    for name, value in updates.items():
        # Replace ALL occurrences (matugen 4.x generates # prefixed hex)
        css = re.sub(
            r'(@define-color\\s+' + re.escape(name) + r'\\s+)#[0-9a-fA-F]{6}(\\s*;)',
            r'\\1' + value + r'\\2',
            css
        )
    with open(path, 'w') as f:
        f.write(css)
update_css(os.path.expanduser('~/.config/gtk-3.0/gtk.css'))
update_css(os.path.expanduser('~/.config/gtk-4.0/gtk.css'))
`])
    }

    // Upstream approach: reset file path when wallpaper changes
    Connections {
        id: resetFilePathNextWallpaperChange
        enabled: false
        target: Config.options?.background ?? null
        function onWallpaperPathChanged() {
            resetFilePathNextWallpaperChange.enabled = false
            root.filePath = ""
            root.filePath = Directories.generatedMaterialThemePath
        }
    }

    function resetFilePathNextTime() {
        resetFilePathNextWallpaperChange.enabled = true
    }

    // Small delay to let file finish writing before applying
    Timer {
        id: delayedFileRead
        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 100
        repeat: false
        running: false
        onTriggered: {
            root.applyColors(themeFileView.text())
        }
    }

    // Force re-read after switchwall completes
    Timer {
        id: pipelineCompleteTimer
        interval: 4000
        repeat: false
        onTriggered: {
            themeFileView.reload()
            altThemeFileView.reload()
        }
    }

    Timer {
        id: terminalApplyTimer
        interval: 50
        repeat: false
        onTriggered: {
            root.applyToActiveTerminals()
            root.applyToKitty()
        }
    }

    Timer {
        id: kdeApplyTimer
        interval: 100
        repeat: false
        onTriggered: root.applyToKdeglobals()
    }

    Timer {
        id: gtkApplyTimer
        interval: 100
        repeat: false
        onTriggered: root.applyToGtkCss()
    }

    Connections {
        target: ColorOverrideStore.data ?? null
        function onColorOverridesChanged() {
            root.refreshColors()
        }
    }

    Connections {
        target: Config.options?.background ?? null
        function onWallpaperPathChanged() {
            if (!Config.ready) return
            root.resetOverridesUnlessPreserved()
        }
    }

    FileView {
        id: themeFileView
        path: Qt.resolvedUrl(root.filePath)
        watchChanges: true
        onFileChanged: {
            this.reload()
            delayedFileRead.start()
        }
        onLoadedChanged: {
            const fileContent = themeFileView.text()
            root.applyColors(fileContent)
        }
        onLoadFailed: root.resetFilePathNextTime()
    }

    FileView {
        id: altThemeFileView
        path: Qt.resolvedUrl(root.altFilePath)
        watchChanges: true
        onFileChanged: this.reload()
        onLoadedChanged: {
            try {
                root.altThemeColors = root.transformColorKeys(JSON.parse(altThemeFileView.text()))
            } catch (e) {
                root.altThemeColors = {}
            }
        }
        onLoadFailed: {}
    }
}
