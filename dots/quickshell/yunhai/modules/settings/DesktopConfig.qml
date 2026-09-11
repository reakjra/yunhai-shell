import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.desktop
import qs.modules.common.widgets
import qs.modules.common.functions

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "wallpaper"
        title: Translation.tr("Desktop icons")

        ConfigSwitch {
            buttonIcon: "desktop_windows"
            text: Translation.tr("Show desktop icons")
            checked: Config.options.desktop.enable
            onCheckedChanged: Config.options.desktop.enable = checked
        }
        ConfigSwitch {
            enabled: Config.options.desktop.enable
            buttonIcon: "visibility_off"
            text: Translation.tr("Show hidden files")
            checked: Config.options.desktop.showHidden
            onCheckedChanged: Config.options.desktop.showHidden = checked
        }
        ConfigSwitch {
            enabled: Config.options.desktop.enable
            buttonIcon: "label"
            text: Translation.tr("Show file extensions")
            checked: Config.options.desktop.showExtensions
            onCheckedChanged: Config.options.desktop.showExtensions = checked
        }

        ContentSubsection {
            title: Translation.tr("Icon size")
            ConfigSelectionArray {
                currentValue: Config.options.desktop.iconSize
                onSelected: newValue => Config.options.desktop.iconSize = newValue
                options: [
                    { value: 48, displayName: Translation.tr("Small") },
                    { value: 64, displayName: Translation.tr("Medium") },
                    { value: 96, displayName: Translation.tr("Large") }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Sort by")
            ConfigSelectionArray {
                currentValue: Config.options.desktop.sortBy
                onSelected: newValue => Config.options.desktop.sortBy = newValue
                options: [
                    { value: "name", displayName: Translation.tr("Name"), icon: "sort_by_alpha" },
                    { value: "date", displayName: Translation.tr("Date"), icon: "schedule" },
                    { value: "size", displayName: Translation.tr("Size"), icon: "straighten" },
                    { value: "type", displayName: Translation.tr("Type"), icon: "category" }
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Grid spacing")
            ConfigRow {
                uniform: true
                ConfigSpinBox {
                    icon: "swap_horiz"
                    text: Translation.tr("Horizontal")
                    value: Config.options.desktop.iconSpacingX
                    from: 0
                    to: 120
                    stepSize: 4
                    onValueChanged: Config.options.desktop.iconSpacingX = value
                }
                ConfigSpinBox {
                    icon: "swap_vert"
                    text: Translation.tr("Vertical")
                    value: Config.options.desktop.iconSpacingY
                    from: 0
                    to: 120
                    stepSize: 4
                    onValueChanged: Config.options.desktop.iconSpacingY = value
                }
            }
            ConfigSpinBox {
                icon: "crop_free"
                text: Translation.tr("Screen edge padding")
                value: Config.options.desktop.edgePadding
                from: 0
                to: 120
                stepSize: 4
                onValueChanged: Config.options.desktop.edgePadding = value
            }
        }
    }

    ContentSection {
        icon: "widgets"
        title: Translation.tr("Desktop widgets")

        ConfigSwitch {
            buttonIcon: "dashboard"
            text: Translation.tr("Show widgets")
            checked: Config.options.desktop.showWidgets
            onCheckedChanged: Config.options.desktop.showWidgets = checked
        }
        ConfigSwitch {
            buttonIcon: "vibration"
            text: Translation.tr("Wobble while editing")
            checked: Config.options.desktop.widgetWobble
            onCheckedChanged: Config.options.desktop.widgetWobble = checked
        }
        ConfigSwitch {
            buttonIcon: "filter_drama"
            text: Translation.tr("Drop shadow")
            checked: Config.options.desktop.widgetShadow
            onCheckedChanged: Config.options.desktop.widgetShadow = checked
        }

        ConfigSpinBox {
            icon: "opacity"
            text: Translation.tr("Shadow strength (%)")
            enabled: Config.options.desktop.widgetShadow
            value: Math.round(Config.options.desktop.widgetShadowStrength * 100)
            from: 0
            to: 100
            stepSize: 5
            onValueChanged: Config.options.desktop.widgetShadowStrength = value / 100
        }
    }

    ContentSection {
        id: widgetsSection
        icon: "tune"
        title: Translation.tr("Widgets on the desktop")

        function positionOf(widget, screenName) {
            const screen = Quickshell.screens.find(s => s.name === screenName);
            if (!screen || widget.x === undefined)
                return "";
            const h = widget.x + widget.w / 2 < screen.width / 3 ? Translation.tr("left") : (widget.x + widget.w / 2 > screen.width * 2 / 3 ? Translation.tr("right") : Translation.tr("centre"));
            const v = widget.y + widget.h / 2 < screen.height / 3 ? Translation.tr("top") : (widget.y + widget.h / 2 > screen.height * 2 / 3 ? Translation.tr("bottom") : Translation.tr("middle"));
            return `${v} ${h}`;
        }

        // rebuilt only when widgets are added/removed, so editing a property
        // does not churn the delegates and kill the switch animation
        readonly property string structure: {
            DesktopWidgets.revision;
            return DesktopWidgets.screens().map(sc => `${sc}:${DesktopWidgets.widgetsFor(sc).map(w => w.id).join(",")}`).join("|");
        }
        property var rows: []
        onStructureChanged: {
            const out = [];
            for (const screen of DesktopWidgets.screens()) {
                const widgets = DesktopWidgets.widgetsFor(screen);
                for (let i = 0; i < widgets.length; i++)
                    out.push({ id: widgets[i].id, screen: screen, number: i + 1, firstOfScreen: i === 0 });
            }
            widgetsSection.rows = out;
        }

        StyledText {
            Layout.fillWidth: true
            visible: widgetsSection.rows.length === 0
            text: Translation.tr("No widgets yet. Right-click the desktop while editing to add one.")
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
        }

        Repeater {
            model: widgetsSection.rows

            ColumnLayout {
                id: rowGroup
                required property var modelData
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    Layout.bottomMargin: 4
                    visible: rowGroup.modelData.firstOfScreen
                    text: rowGroup.modelData.screen
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.weight: Font.Medium
                    color: Appearance.colors.colOnLayer0
                }

            ContentSubsection {
                id: row
                readonly property var modelData: rowGroup.modelData
                readonly property var widget: {
                    DesktopWidgets.revision;
                    return DesktopWidgets.get(row.modelData.id) ?? ({});
                }
                readonly property string detail: (row.widget.type === "image" && (row.widget.source ?? "") !== "") ? FileUtils.fileNameForPath(row.widget.source) : ""
                readonly property string place: widgetsSection.positionOf(row.widget, row.modelData.screen)

                sectionId: row.modelData.id
                Layout.bottomMargin: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    MaterialSymbol {
                        text: WidgetTypes.iconFor(row.widget.type)
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOnLayer0
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: `${row.modelData.number}. ${WidgetTypes.nameFor(row.widget.type)}${row.detail === "" ? "" : " · " + row.detail}${row.place === "" ? "" : " · " + row.place}`
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnLayer0
                        elide: Text.ElideRight
                    }
                }

                ContentSubsection {
                    title: Translation.tr("Shape")
                    ConfigSelectionArray {
                        currentValue: row.widget.shape ?? WidgetShapes.fallback
                        options: WidgetShapes.options
                        onSelected: newValue => DesktopWidgets.setProp(row.modelData.id, "shape", newValue)
                    }
                }

                ContentSubsection {
                    visible: WidgetTypes.hasChip(row.widget.type)
                    title: Translation.tr("Chip shape")
                    ConfigSelectionArray {
                        currentValue: row.widget.chipShape ?? WidgetShapes.fallback
                        options: WidgetShapes.chipOptions
                        onSelected: newValue => DesktopWidgets.setProp(row.modelData.id, "chipShape", newValue)
                    }
                }

                ContentSubsection {
                    visible: WidgetStyles.has(row.widget.type)
                    title: Translation.tr("Style")
                    ConfigSelectionArray {
                        currentValue: row.widget.style ?? WidgetStyles.defaultFor(row.widget.type)
                        options: WidgetStyles.forType(row.widget.type)
                        onSelected: newValue => DesktopWidgets.setProp(row.modelData.id, "style", newValue)
                    }
                }

                ConfigSwitch {
                    buttonIcon: "format_color_fill"
                    text: Translation.tr("Background")
                    checked: row.widget.background ?? true
                    onCheckedChanged: DesktopWidgets.setProp(row.modelData.id, "background", checked)
                }
            }
            }
        }
    }
}
