import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 16

    readonly property var colorGroups: [
        {
            title: Translation.tr("Primary"),
            colors: [
                { key: "m3primary", name: Translation.tr("Primary") },
                { key: "m3onPrimary", name: Translation.tr("On Primary") },
                { key: "m3primaryContainer", name: Translation.tr("Container") },
                { key: "m3onPrimaryContainer", name: Translation.tr("On Container") },
            ]
        },
        {
            title: Translation.tr("Secondary"),
            colors: [
                { key: "m3secondary", name: Translation.tr("Secondary") },
                { key: "m3onSecondary", name: Translation.tr("On Secondary") },
                { key: "m3secondaryContainer", name: Translation.tr("Container") },
                { key: "m3onSecondaryContainer", name: Translation.tr("On Container") },
            ]
        },
        {
            title: Translation.tr("Tertiary"),
            colors: [
                { key: "m3tertiary", name: Translation.tr("Tertiary") },
                { key: "m3onTertiary", name: Translation.tr("On Tertiary") },
                { key: "m3tertiaryContainer", name: Translation.tr("Container") },
                { key: "m3onTertiaryContainer", name: Translation.tr("On Container") },
            ]
        },
        {
            title: Translation.tr("Surface"),
            colors: [
                { key: "m3background", name: Translation.tr("Background") },
                { key: "m3onBackground", name: Translation.tr("On Background") },
                { key: "m3surface", name: Translation.tr("Surface") },
                { key: "m3onSurface", name: Translation.tr("On Surface") },
                { key: "m3surfaceVariant", name: Translation.tr("Variant") },
                { key: "m3onSurfaceVariant", name: Translation.tr("On Variant") },
                { key: "m3surfaceDim", name: Translation.tr("Dim") },
                { key: "m3surfaceBright", name: Translation.tr("Bright") },
            ]
        },
        {
            title: Translation.tr("Inverse & Outline"),
            colors: [
                { key: "m3inverseSurface", name: Translation.tr("Inverse Surface") },
                { key: "m3inverseOnSurface", name: Translation.tr("Inv. On Surface") },
                { key: "m3inversePrimary", name: Translation.tr("Inverse Primary") },
                { key: "m3outline", name: Translation.tr("Outline") },
                { key: "m3outlineVariant", name: Translation.tr("Outline Variant") },
            ]
        },
        {
            title: Translation.tr("Containers"),
            colors: [
                { key: "m3surfaceContainerLowest", name: Translation.tr("Lowest") },
                { key: "m3surfaceContainerLow", name: Translation.tr("Low") },
                { key: "m3surfaceContainer", name: Translation.tr("Default") },
                { key: "m3surfaceContainerHigh", name: Translation.tr("High") },
                { key: "m3surfaceContainerHighest", name: Translation.tr("Highest") },
            ]
        },
        {
            title: Translation.tr("Error"),
            colors: [
                { key: "m3error", name: Translation.tr("Error") },
                { key: "m3onError", name: Translation.tr("On Error") },
                { key: "m3errorContainer", name: Translation.tr("Container") },
                { key: "m3onErrorContainer", name: Translation.tr("On Container") },
            ]
        },
        {
            title: Translation.tr("Success"),
            colors: [
                { key: "m3success", name: Translation.tr("Success") },
                { key: "m3onSuccess", name: Translation.tr("On Success") },
                { key: "m3successContainer", name: Translation.tr("Container") },
                { key: "m3onSuccessContainer", name: Translation.tr("On Container") },
            ]
        },
        {
            title: Translation.tr("Terminal"),
            colors: [
                { key: "term0", name: Translation.tr("Black") },
                { key: "term1", name: Translation.tr("Red") },
                { key: "term2", name: Translation.tr("Green") },
                { key: "term3", name: Translation.tr("Yellow") },
                { key: "term4", name: Translation.tr("Blue") },
                { key: "term5", name: Translation.tr("Magenta") },
                { key: "term6", name: Translation.tr("Cyan") },
                { key: "term7", name: Translation.tr("White") },
                { key: "term8", name: Translation.tr("Bright Black") },
                { key: "term9", name: Translation.tr("Bright Red") },
                { key: "term10", name: Translation.tr("Bright Green") },
                { key: "term11", name: Translation.tr("Bright Yellow") },
                { key: "term12", name: Translation.tr("Bright Blue") },
                { key: "term13", name: Translation.tr("Bright Magenta") },
                { key: "term14", name: Translation.tr("Bright Cyan") },
                { key: "term15", name: Translation.tr("Bright White") },
            ]
        },
        {
            title: Translation.tr("Qt Apps"),
            colors: [
                { key: "kdeViewBg", name: Translation.tr("View") },
                { key: "kdeViewAltBg", name: Translation.tr("View Alt") },
                { key: "kdeWindowBg", name: Translation.tr("Window") },
                { key: "kdeWindowAltBg", name: Translation.tr("Window Alt") },
                { key: "kdeButtonBg", name: Translation.tr("Button") },
                { key: "kdeButtonAltBg", name: Translation.tr("Button Alt") },
                { key: "kdeSelectionBg", name: Translation.tr("Selection") },
                { key: "kdeSelectionText", name: Translation.tr("Select Text") },
                { key: "kdeTitlebarBg", name: Translation.tr("Titlebar") },
                { key: "kdeTitlebarText", name: Translation.tr("Titlebar Text") },
                { key: "kdeInactiveTitlebarBg", name: Translation.tr("Inactive Bar") },
                { key: "kdeInactiveTitlebarText", name: Translation.tr("Inactive Text") },
                { key: "kdeViewText", name: Translation.tr("View Text") },
                { key: "kdeWindowText", name: Translation.tr("Window Text") },
                { key: "kdeInactiveText", name: Translation.tr("Disabled") },
                { key: "kdeLinkText", name: Translation.tr("Link") },
                { key: "kdeVisitedText", name: Translation.tr("Visited") },
                { key: "kdeErrorText", name: Translation.tr("Error") },
                { key: "kdeWarningText", name: Translation.tr("Warning") },
                { key: "kdeSuccessText", name: Translation.tr("Success") },
                { key: "kdeAccent", name: Translation.tr("Accent") },
                { key: "kdeTooltipBg", name: Translation.tr("Tooltip") },
                { key: "kdeTooltipText", name: Translation.tr("Tooltip Text") },
                { key: "kdeComplementaryBg", name: Translation.tr("Complement") },
                { key: "kdeComplementaryText", name: Translation.tr("Complement Text") },
            ]
        },
        {
            title: Translation.tr("GTK Apps"),
            colors: [
                { key: "gtkWindowBg", name: Translation.tr("Window") },
                { key: "gtkWindowFg", name: Translation.tr("Window Text") },
                { key: "gtkHeaderbarBg", name: Translation.tr("Headerbar") },
                { key: "gtkHeaderbarFg", name: Translation.tr("Headerbar Text") },
                { key: "gtkViewBg", name: Translation.tr("View") },
                { key: "gtkViewFg", name: Translation.tr("View Text") },
                { key: "gtkCardBg", name: Translation.tr("Card") },
                { key: "gtkCardFg", name: Translation.tr("Card Text") },
                { key: "gtkPopoverBg", name: Translation.tr("Popover") },
                { key: "gtkPopoverFg", name: Translation.tr("Popover Text") },
                { key: "gtkAccent", name: Translation.tr("Accent") },
                { key: "gtkAccentFg", name: Translation.tr("Accent Text") },
            ]
        }
    ]

    property string editingKey: ""
    property color _originalColor: "black"   // color before user started dragging (for Cancel)
    property bool _pickerHandled: false

    // Reactive tracker for override changes
    property string _currentOverrides: ColorOverrideStore.data?.colorOverrides ?? "{}"

    // ── Preset state ──
    property string presetMode: "normal"  // "normal" | "creating" | "editing"
    property var selectedColorKeys: ({})
    property string presetName: ""
    property string presetIcon: "palette"
    property int editingPresetIndex: -1

    // All presets from config
    property var presetsArray: {
        const raw = ColorOverrideStore.data?.customPresets ?? ""
        if (!raw || raw === "") return []
        try {
            const parsed = JSON.parse(raw)
            return Array.isArray(parsed) ? parsed : []
        } catch (e) {
            return []
        }
    }

    // Preset options for ConfigSelectionArray
    property var presetOptions: {
        const presets = root.presetsArray
        return presets.map((preset, i) => ({
            displayName: preset.name,
            icon: preset.icon,
            value: i,
            middleClickAction: () => root.deletePreset(i)
        }))
    }

    // Which preset is currently active (-1 if none). Stored persistently.
    property int activePresetIndex: ColorOverrideStore.data?.activePresetIndex ?? -1

    // Resolve preset colors for the current mode, with backward compat for old format
    function getPresetColors(preset) {
        const isDark = Appearance.m3colors.darkmode
        if (preset.dark || preset.light)
            return (isDark ? preset.dark : preset.light) ?? preset.dark ?? preset.light ?? {}
        return preset.colors ?? {}
    }

    function applyPreset(colors) {
        const overrides = {}
        const keys = Object.keys(colors)
        for (let j = 0; j < keys.length; j++) overrides[keys[j]] = colors[keys[j]]
        ColorOverrideStore.data.colorOverrides = JSON.stringify(overrides)
    }

    function removePreset(colors) {
        let overrides = {}
        try { overrides = JSON.parse(_currentOverrides) } catch (e) {}
        const keys = Object.keys(colors)
        for (let j = 0; j < keys.length; j++) delete overrides[keys[j]]
        ColorOverrideStore.data.colorOverrides = JSON.stringify(overrides)
    }

    function togglePresetByIndex(index) {
        if (index < 0 || index >= presetsArray.length) return
        if (activePresetIndex === index) {
            // Deactivate: clear all overrides and rerun switchwall for clean state
            ColorOverrideStore.data.activePresetIndex = -1
            ColorOverrideStore.data.colorOverrides = "{}"
            const dark = Appearance.m3colors.darkmode
            Quickshell.execDetached(["bash", "-c",
                `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`])
            MaterialThemeLoader.scheduleForceReload()
        } else {
            const preset = presetsArray[index]
            applyPreset(getPresetColors(preset))
            ColorOverrideStore.data.activePresetIndex = index
        }
    }

    function switchMode(dark) {
        MaterialThemeLoader.switchDarkLightMode(dark)
    }

    function colorToHex(c) {
        function h(v) { return Math.round(v * 255).toString(16).padStart(2, '0') }
        const rgb = h(c.r) + h(c.g) + h(c.b)
        if (c.a < 1) return "#" + h(c.a) + rgb
        return "#" + rgb
    }

    function setOverride(key, color) {
        let overrides = {}
        try { overrides = JSON.parse(_currentOverrides) } catch (e) {}
        overrides[key] = color
        ColorOverrideStore.data.colorOverrides = JSON.stringify(overrides)
    }

    function removeOverride(key) {
        let overrides = {}
        try { overrides = JSON.parse(_currentOverrides) } catch (e) {}
        delete overrides[key]
        ColorOverrideStore.data.colorOverrides = JSON.stringify(overrides)
    }

    function resetAll() {
        const hadPreset = activePresetIndex >= 0
        ColorOverrideStore.data.colorOverrides = "{}"
        ColorOverrideStore.data.activePresetIndex = -1
        if (hadPreset) {
            const dark = Appearance.m3colors.darkmode
            Quickshell.execDetached(["bash", "-c",
                `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`])
            MaterialThemeLoader.scheduleForceReload()
        }
    }

    // ── Custom preset CRUD ──

    function savePresets(arr) {
        ColorOverrideStore.data.customPresets = JSON.stringify(arr)
    }

    // Derive GTK keys from M3 colors (same mapping as switchwall.sh)
    function deriveGtkColors(m3Colors) {
        const gtkMapping = {
            "gtkAccent": "m3primary", "gtkAccentFg": "m3onPrimary",
            "gtkWindowBg": "m3background", "gtkWindowFg": "m3onBackground",
            "gtkHeaderbarBg": "m3surfaceDim", "gtkHeaderbarFg": "m3onSurface",
            "gtkViewBg": "m3surface", "gtkViewFg": "m3onSurface",
            "gtkCardBg": "m3surface", "gtkCardFg": "m3onSurface",
            "gtkPopoverBg": "m3surfaceDim", "gtkPopoverFg": "m3onSurface",
        }
        for (const [gtkKey, m3Key] of Object.entries(gtkMapping)) {
            if (m3Colors[m3Key]) m3Colors[gtkKey] = m3Colors[m3Key]
        }
        return m3Colors
    }

    function addPreset(name, icon, colors) {
        const arr = presetsArray.slice()
        const modeKey = Appearance.m3colors.darkmode ? "dark" : "light"
        arr.push({ name: name, icon: icon, [modeKey]: colors })
        savePresets(arr)
    }

    function deletePreset(index) {
        const arr = presetsArray.slice()
        const wasActive = activePresetIndex === index
        arr.splice(index, 1)
        savePresets(arr)
        if (wasActive) {
            // Full reset: clear overrides, index, and rerun switchwall
            // to regenerate correct colors for current mode
            ColorOverrideStore.data.activePresetIndex = -1
            ColorOverrideStore.data.colorOverrides = "{}"
            const dark = Appearance.m3colors.darkmode
            Quickshell.execDetached(["bash", "-c",
                `${Directories.wallpaperSwitchScriptPath} --mode ${dark ? "dark" : "light"} --noswitch`])
            MaterialThemeLoader.scheduleForceReload()
        } else if (activePresetIndex > index) {
            ColorOverrideStore.data.activePresetIndex = activePresetIndex - 1
        }
    }

    function updatePreset(index, name, icon) {
        const arr = presetsArray.slice()
        arr[index] = Object.assign({}, arr[index], { name: name, icon: icon })
        savePresets(arr)
    }

    function saveCurrentModeColors(index) {
        const arr = presetsArray.slice()
        const modeKey = Appearance.m3colors.darkmode ? "dark" : "light"
        let overrides = {}
        try { overrides = JSON.parse(_currentOverrides) } catch (e) {}
        arr[index] = Object.assign({}, arr[index], { [modeKey]: overrides })
        savePresets(arr)
    }

    // ── Selection helpers ──

    function toggleColorKeySelection(key) {
        let sel = {}
        for (const k in selectedColorKeys) sel[k] = true
        if (sel[key]) delete sel[key]; else sel[key] = true
        selectedColorKeys = sel
    }

    function selectAllColorKeys() {
        var sel = {}
        for (var i = 0; i < colorGroups.length; i++)
            for (var j = 0; j < colorGroups[i].colors.length; j++)
                sel[colorGroups[i].colors[j].key] = true
        selectedColorKeys = sel
    }

    function deselectAllColorKeys() {
        selectedColorKeys = ({})
    }

    // ── Creation flow ──

    function beginCreatingPreset() {
        presetMode = "creating"
        presetName = "Preset " + (presetsArray.length + 1)
        presetIcon = "palette"
        selectedColorKeys = ({})
    }

    function cancelPresetMode() {
        presetMode = "normal"
        selectedColorKeys = ({})
        editingPresetIndex = -1
    }

    function confirmPresetCreation() {
        var colors = {}
        var keys = Object.keys(selectedColorKeys)
        for (var j = 0; j < keys.length; j++)
            colors[keys[j]] = colorToHex(Appearance.m3colors[keys[j]])
        if (Object.keys(colors).length === 0) return
        const newIndex = presetsArray.length
        addPreset(presetName, presetIcon, colors)
        applyPreset(colors)
        ColorOverrideStore.data.activePresetIndex = newIndex
        cancelPresetMode()
    }

    // ── Edit flow ──

    function beginEditingPreset(index) {
        if (index < 0 || index >= presetsArray.length) return
        presetMode = "editing"
        editingPresetIndex = index
        presetName = presetsArray[index].name
        presetIcon = presetsArray[index].icon
    }

    function confirmPresetEdit() {
        if (editingPresetIndex >= 0)
            updatePreset(editingPresetIndex, presetName, presetIcon)
        cancelPresetMode()
    }

    // ── Selected key count (for creation mode) ──
    property int selectedKeyCount: {
        let count = 0
        for (const k in selectedColorKeys) count++
        return count
    }

    property bool allKeysSelected: {
        var total = 0
        for (var i = 0; i < colorGroups.length; i++)
            total += colorGroups[i].colors.length
        return selectedKeyCount === total
    }

    // ── UI ──

    RippleButtonWithIcon {
        materialIcon: "restart_alt"
        mainText: Translation.tr("Reset all overrides")
        onClicked: root.resetAll()
    }

    // ── Presets section ──
    ContentSubsection {
        title: Translation.tr("Presets")
        Layout.fillWidth: true

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ConfigSelectionArray {
                Layout.fillWidth: true
                currentValue: root.presetMode === "editing" ? root.editingPresetIndex : root.activePresetIndex
                onSelected: newValue => {
                    if (root.presetMode === "editing") {
                        root.beginEditingPreset(newValue)
                    } else {
                        root.togglePresetByIndex(newValue)
                    }
                }
                options: root.presetOptions
            }

            ConfigSelectionArray {
                Layout.fillWidth: false
                currentValue: root.presetMode === "editing" ? "edit" : (root.presetMode === "creating" ? "add" : -1)
                options: [
                    {
                        displayName: "",
                        icon: "edit",
                        value: "edit",
                        releaseAction: () => {
                            if (root.presetMode === "editing") {
                                root.cancelPresetMode()
                            } else if (root.presetsArray.length > 0) {
                                const activeIdx = root.activePresetIndex
                                if (activeIdx >= 0) {
                                    root.beginEditingPreset(activeIdx)
                                } else {
                                    root.beginEditingPreset(0)
                                }
                            }
                        }
                    },
                    {
                        displayName: "",
                        icon: Appearance.m3colors.darkmode ? "dark_mode" : "light_mode",
                        value: "mode",
                        releaseAction: () => root.switchMode(!Appearance.m3colors.darkmode)
                    },
                    {
                        displayName: "",
                        icon: "add",
                        value: "add",
                        releaseAction: () => {
                            if (root.presetMode === "creating") root.cancelPresetMode()
                            else root.beginCreatingPreset()
                        }
                    }
                ]
            }
        }

    }

    // ── Edit/Create preset section (animated) ──
    Item {
        id: presetFormContainer
        Layout.fillWidth: true
        clip: true

        property bool isOpen: root.presetMode === "creating" || root.presetMode === "editing"

        implicitHeight: isOpen ? presetFormSection.implicitHeight : 0

        Behavior on implicitHeight {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        ContentSubsection {
            id: presetFormSection
            width: parent.width
            title: root.presetMode === "editing"
                ? Translation.tr("Edit Preset")
                : Translation.tr("New Preset")

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                // Row 1: Input fields
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    MaterialTextArea {
                        id: formIconInput
                        implicitWidth: 140
                        text: root.presetIcon
                        placeholderText: Translation.tr("Icon")
                        onTextChanged: root.presetIcon = text.split("\n")[0]
                    }

                    MaterialTextArea {
                        id: formNameInput
                        implicitWidth: 150
                        Layout.fillWidth: true
                        text: root.presetName
                        placeholderText: Translation.tr("Name")
                        onTextChanged: root.presetName = text.split("\n")[0]
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (root.presetMode === "editing") root.confirmPresetEdit()
                                else root.confirmPresetCreation()
                            }
                        }
                    }
                }

                // Row 2: Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Creation mode: select/deselect all + count
                    RippleButtonWithIcon {
                        visible: root.presetMode === "creating"
                        materialIcon: root.allKeysSelected ? "deselect" : "select_all"
                        mainText: root.allKeysSelected ? Translation.tr("Deselect all") : Translation.tr("Select all")
                        onClicked: {
                            if (root.allKeysSelected) root.deselectAllColorKeys()
                            else root.selectAllColorKeys()
                        }
                    }

                    StyledText {
                        visible: root.presetMode === "creating"
                        text: root.selectedKeyCount + " " + Translation.tr("selected")
                        color: Appearance?.colors.colOnSurfaceVariant ?? "#cbc5ca"
                        font.pixelSize: Appearance?.font.pixelSize.small ?? 15
                    }

                    // Edit mode: delete button
                    RippleButtonWithIcon {
                        visible: root.presetMode === "editing"
                        materialIcon: "delete"
                        mainText: Translation.tr("Delete")
                        onClicked: {
                            if (root.editingPresetIndex >= 0) {
                                root.deletePreset(root.editingPresetIndex)
                                root.cancelPresetMode()
                            }
                        }
                    }

                    // Edit mode: save current colors into preset for current mode
                    RippleButtonWithIcon {
                        visible: root.presetMode === "editing" && root.editingPresetIndex >= 0
                        materialIcon: "palette"
                        mainText: Appearance.m3colors.darkmode
                            ? Translation.tr("Save dark colors")
                            : Translation.tr("Save light colors")
                        onClicked: {
                            root.saveCurrentModeColors(root.editingPresetIndex)
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RippleButtonWithIcon {
                        materialIcon: "close"
                        mainText: Translation.tr("Cancel")
                        onClicked: root.cancelPresetMode()
                    }

                    RippleButtonWithIcon {
                        materialIcon: "check"
                        mainText: Translation.tr("Save")
                        onClicked: {
                            if (root.presetMode === "editing") root.confirmPresetEdit()
                            else root.confirmPresetCreation()
                        }
                    }
                }
            }
        }
    }

    Repeater {
        model: root.colorGroups

        ContentSubsection {
            required property var modelData
            required property int index
            title: modelData.title
            Layout.fillWidth: true

            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: modelData.colors

                    RippleButton {
                        id: colorDelegate
                        required property var modelData
                        required property int index

                        width: Math.floor((parent.width - 8 * 3) / 4)
                        implicitHeight: 38
                        buttonRadius: Appearance?.rounding.small ?? 12
                        colBackground: ColorUtils.transparentize(Appearance?.colors.colLayer2 ?? "#333")
                        colBackgroundHover: Appearance?.colors.colLayer2Hover ?? "#444"
                        colRipple: Appearance?.colors.colLayer2Active ?? "#555"

                        property bool isSelectedForPreset: root.presetMode === "creating" && !!root.selectedColorKeys[modelData.key]

                        // Resolve the current display color reactively
                        property color displayColor: {
                            const raw = root._currentOverrides
                            let overrides = {}
                            try { overrides = JSON.parse(raw) } catch (e) {}
                            const override = overrides[modelData.key]
                            return override ?? Appearance.m3colors[modelData.key] ?? "#808080"
                        }

                        property bool isOverridden: {
                            const raw = root._currentOverrides
                            let overrides = {}
                            try { overrides = JSON.parse(raw) } catch (e) {}
                            if (!overrides[modelData.key]) return false
                            // If a preset is active, only show indicator for keys
                            // the user manually changed (not auto-populated ones)
                            const idx = root.activePresetIndex
                            if (idx >= 0 && idx < root.presetsArray.length) {
                                const preset = root.presetsArray[idx]
                                const presetColors = root.getPresetColors(preset)
                                if (presetColors[modelData.key] &&
                                    presetColors[modelData.key].toLowerCase() === overrides[modelData.key].toLowerCase())
                                    return false
                            }
                            return true
                        }

                        onClicked: {
                            if (root.presetMode === "creating") {
                                root.toggleColorKeySelection(modelData.key)
                                return
                            }
                            root.editingKey = modelData.key
                            root._originalColor = Appearance.m3colors[modelData.key]
                            root._pickerHandled = false
                            // Pass theme-file color as default for "Default" preview
                            const themeCol = MaterialThemeLoader.themeColors[modelData.key]
                            const defaultCol = themeCol ? Qt.color(themeCol) : undefined
                            colorPicker.openWithColor(Appearance.m3colors[modelData.key], defaultCol)
                        }

                        contentItem: RowLayout {
                            spacing: 8

                            Rectangle {
                                width: 22
                                height: 22
                                radius: 11
                                color: colorDelegate.displayColor
                                border.width: colorDelegate.isSelectedForPreset ? 2 : (colorDelegate.isOverridden ? 2 : 0)
                                border.color: colorDelegate.isSelectedForPreset
                                    ? (Appearance?.m3colors.m3success ?? "#4caf50")
                                    : (Appearance?.colors.colPrimary ?? "#cbc4cb")

                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }

                            }

                            StyledText {
                                text: colorDelegate.modelData.name
                                font.pixelSize: Appearance?.font.pixelSize.small ?? 15
                                color: Appearance?.colors.colOnSurfaceVariant ?? "#cbc5ca"
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }
    }

    // Live preview: apply color to shell as user drags in the picker
    Connections {
        target: colorPicker
        function onSelectedColorChanged() {
            if (root.presetMode !== "normal") return
            if (root.editingKey && colorPicker.opened) {
                Appearance.m3colors[root.editingKey] = colorPicker.selectedColor
            }
        }
    }

    ColorPickerPopup {
        id: colorPicker
        onAccepted: (chosenColor) => {
            root._pickerHandled = true
            root.setOverride(root.editingKey, root.colorToHex(chosenColor))
        }
        onResetRequested: {
            root._pickerHandled = true
            root.removeOverride(root.editingKey)
        }
        onClosed: {
            if (!root._pickerHandled && root.editingKey) {
                // Cancel: revert to original color
                Appearance.m3colors[root.editingKey] = root._originalColor
            }
            root.editingKey = ""
        }
    }

}
