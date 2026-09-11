import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

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
}
