import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

import QtQml.Models

ContentPage {
    id: page
    forceWidth: true

    property var componentMap: ({
        "active_window": activeWindow,
        "music_player": musicPlayer,
        "utility_buttons": utilityButtons,
        "system_tray": systemTray,
        "workspaces": workspaces,
        "timerAndPomodoro": timerAndPomodoro,
    })

    function scrollTo(stringId) {
        const item = componentMap[stringId]
        page.contentY = item.y
    }


    ContentSection {
        icon: "mobile_layout"
        title: Translation.tr("Bar layout")
        ContentSubsection {
            title: Translation.tr("Left layout")
            tooltip: Translation.tr("Top layout in vertical mode")
            ConfigListView {
                barSection: 0
                listModel: Config.options.bar.layouts.left
                sourceListModel: Config.options.bar.layouts.availableComps
                onUpdated: (newList) => {
                    Config.options.bar.layouts.left = newList
                } 
                onSourceUpdated: (newList) => {
                    Config.options.bar.layouts.availableComps = newList
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Center layout")
            tooltip: Translation.tr("Center the component with the button")
            ConfigListView {
                barSection: 1
                listModel: Config.options.bar.layouts.center
                sourceListModel: Config.options.bar.layouts.availableComps
                onUpdated: (newList) => {
                    Config.options.bar.layouts.center = newList
                } 
                onSourceUpdated: (newList) => {
                    Config.options.bar.layouts.availableComps = newList
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Right layout")
            tooltip: Translation.tr("Bottom layout in vertical mode")
            ConfigListView {
                barSection: 2
                listModel: Config.options.bar.layouts.right
                sourceListModel: Config.options.bar.layouts.availableComps
                onUpdated: (newList) => {
                    Config.options.bar.layouts.right = newList
                }
                onSourceUpdated: (newList) => {
                    Config.options.bar.layouts.availableComps = newList
                } 
            }
        }
    }

    ContentSection {
        icon: "open_in_full"
        title: Translation.tr("Bar sizes")

        ConfigSpinBox {
            icon: "height"
            text: Translation.tr("Bar height")
            value: Config.options.bar.sizes.height
            from: 30
            to: 50
            stepSize: 1
            onValueChanged: {
                Config.options.bar.sizes.height = value;
            }
        }
        ConfigSpinBox {
            icon: "width"
            text: Translation.tr("Bar width")
            value: Config.options.bar.sizes.width
            from: 30
            to: 50
            stepSize: 1
            onValueChanged: {
                Config.options.bar.sizes.width = value;
            }
        }
    }

    ContentSection {
        icon: "spoke"
        title: Translation.tr("Positioning")

        ConfigRow {
            ContentSubsection {
                title: Translation.tr("Bar position")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: (Config.options.bar.bottom ? 1 : 0) | (Config.options.bar.vertical ? 2 : 0)
                    onSelected: newValue => {
                        Config.options.bar.bottom = (newValue & 1) !== 0;
                        Config.options.bar.vertical = (newValue & 2) !== 0;
                    }
                    options: [
                        {
                            displayName: Translation.tr("Top"),
                            icon: "arrow_upward",
                            value: 0 // bottom: false, vertical: false
                        },
                        {
                            displayName: Translation.tr("Left"),
                            icon: "arrow_back",
                            value: 2 // bottom: false, vertical: true
                        },
                        {
                            displayName: Translation.tr("Bottom"),
                            icon: "arrow_downward",
                            value: 1 // bottom: true, vertical: false
                        },
                        {
                            displayName: Translation.tr("Right"),
                            icon: "arrow_forward",
                            value: 3 // bottom: true, vertical: true
                        }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Automatically hide")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.autoHide.enable
                    onSelected: newValue => {
                        Config.options.bar.autoHide.enable = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("No"),
                            icon: "close",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Yes"),
                            icon: "check",
                            value: true
                        }
                    ]
                }
            }
        }

        ConfigRow {
            Layout.fillHeight: false
            ContentSubsection {
                title: Translation.tr("Corner style")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.bar.cornerStyle
                    onSelected: newValue => {
                        Config.options.bar.cornerStyle = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Hug"),
                            icon: "line_curve",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Float"),
                            icon: "page_header",
                            value: 1
                        },
                        {
                            displayName: Translation.tr("Rect"),
                            icon: "toolbar",
                            value: 2
                        }
                    ]
                }
            }

            ContentSubsection {
                title: Translation.tr("Group style")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.borderless
                    onSelected: newValue => {
                        Config.options.bar.borderless = newValue; // Update local copy
                    }
                    options: [
                        {
                            displayName: Translation.tr("Pills"),
                            icon: "location_chip",
                            value: false
                        },
                        {
                            displayName: Translation.tr("Line-separated"),
                            icon: "split_scene",
                            value: true
                        }
                    ]
                }
            }
        }

        RowLayout {
            Layout.fillHeight: true
            ContentSubsection {
                title: Translation.tr("Component background style")
                Layout.fillWidth: true

                ConfigSelectionArray {
                    currentValue: Config.options.bar.componentBackgroundStyle
                    onSelected: newValue => {
                        Config.options.bar.componentBackgroundStyle = newValue;
                    }
                    options: [          
                        {
                            displayName: Translation.tr("Surface"),
                            icon: "texture",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Surface high"),
                            icon: "format_color_fill",
                            value: 1
                        }
                    ]
                }
            }
            ContentSubsection {
                title: Translation.tr("Bar background style")
                Layout.fillWidth: false

                ConfigSelectionArray {
                    currentValue: Config.options.bar.barBackgroundStyle
                    onSelected: newValue => {
                        Config.options.bar.barBackgroundStyle = newValue;
                    }
                    options: [          
                        {
                            displayName: Translation.tr("Transparent"),
                            icon: "opacity",
                            value: 0
                        },
                        {
                            displayName: Translation.tr("Visible"),
                            icon: "visibility",
                            value: 1
                        }
                    ]
                }
            }
        }
        
    }
    
    ContentSection {
        id: activeWindow
        icon: "ad"
        title: Translation.tr("Active window")
        ConfigSwitch {
            buttonIcon: "crop_free"
            text: Translation.tr("Use fixed size")
            checked: Config.options.bar.activeWindow.fixedSize
            onCheckedChanged: {
                Config.options.bar.activeWindow.fixedSize = checked;
            }
        }
    }

    ContentSection {
        id: musicPlayer
        icon: "music_cast"
        title: Translation.tr("Media player")
        ConfigSwitch {
            enabled: !Config.options.bar.vertical
            buttonIcon: "crop_free"
            text: Translation.tr("Use custom size")
            checked: Config.options.bar.mediaPlayer.useCustomSize
            onCheckedChanged: {
                Config.options.bar.mediaPlayer.useCustomSize = checked;
            }
            StyledToolTip {
                text: Translation.tr("Only available in horizontal mode")
            }
        }
        ConfigSpinBox {
            enabled: !Config.options.bar.vertical
            icon: "width_full"
            text: Translation.tr("Custom size")
            value: Config.options.bar.mediaPlayer.customSize
            from: 100
            to: 500
            stepSize: 25
            onValueChanged: {
                Config.options.bar.mediaPlayer.customSize = value;
            }
        }
    }

    ContentSection {
        icon: "notifications"
        title: Translation.tr("Notifications")
        ConfigSwitch {
            buttonIcon: "counter_2"
            text: Translation.tr("Unread indicator: show count")
            checked: Config.options.bar.indicators.notifications.showUnreadCount
            onCheckedChanged: {
                Config.options.bar.indicators.notifications.showUnreadCount = checked;
            }
        }
    }

    ContentSection {
        id: systemTray
        icon: "shelf_auto_hide"
        title: Translation.tr("Tray")

        ConfigSwitch {
            buttonIcon: "keep"
            text: Translation.tr('Make icons pinned by default')
            checked: Config.options.tray.invertPinnedItems
            onCheckedChanged: {
                Config.options.tray.invertPinnedItems = checked;
            }
        }
        
        ConfigSwitch {
            buttonIcon: "colors"
            text: Translation.tr('Tint icons')
            checked: Config.options.tray.monochromeIcons
            onCheckedChanged: {
                Config.options.tray.monochromeIcons = checked;
            }
        }
    }

    ContentSection {
        id: timerAndPomodoro
        icon: "timer_play"
        title: Translation.tr("Timer & Pomodoro")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "timer"
                text: Translation.tr("Show stopwatch")
                checked: Config.options.bar.timers.showStopwatch
                onCheckedChanged: {
                    Config.options.bar.timers.showStopwatch = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "search_activity"
                text: Translation.tr("Show pomodoro")
                checked: Config.options.bar.timers.showPomodoro
                onCheckedChanged: {
                    Config.options.bar.timers.showPomodoro = checked;
                }
            }
        }

    }

    ContentSection {
        id: utilityButtons
        icon: "widgets"
        title: Translation.tr("Utility buttons")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "content_cut"
                text: Translation.tr("Screen snip")
                checked: Config.options.bar.utilButtons.showScreenSnip
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenSnip = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "colorize"
                text: Translation.tr("Color picker")
                checked: Config.options.bar.utilButtons.showColorPicker
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showColorPicker = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "keyboard"
                text: Translation.tr("Keyboard toggle")
                checked: Config.options.bar.utilButtons.showKeyboardToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showKeyboardToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "mic"
                text: Translation.tr("Mic toggle")
                checked: Config.options.bar.utilButtons.showMicToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showMicToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "dark_mode"
                text: Translation.tr("Dark/Light toggle")
                checked: Config.options.bar.utilButtons.showDarkModeToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showDarkModeToggle = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "speed"
                text: Translation.tr("Performance Profile toggle")
                checked: Config.options.bar.utilButtons.showPerformanceProfileToggle
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showPerformanceProfileToggle = checked;
                }
            }
        }
        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "videocam"
                text: Translation.tr("Record")
                checked: Config.options.bar.utilButtons.showScreenRecord
                onCheckedChanged: {
                    Config.options.bar.utilButtons.showScreenRecord = checked;
                }
            }
        }
    }

    ContentSection {
        id: workspaces
        icon: "workspaces"
        title: Translation.tr("Workspaces")

        ContentSubsection {
            title: Translation.tr("Style")

            ConfigSelectionArray {
                currentValue: Config.options.bar.workspaces.style
                onSelected: newValue => {
                    Config.options.bar.workspaces.style = newValue
                }
                options: [
                    {
                        displayName: Translation.tr("Classic"),
                        icon: "view_list",
                        value: 0
                    },
                    {
                        displayName: Translation.tr("Balls"),
                        icon: "more_horiz",
                        value: 1
                    }
                ]
            }
        }

        ConfigSwitch {
            buttonIcon: "keyboard"
            text: Translation.tr('Show numbers on Super hold')
            checked: Config.options.bar.workspaces.showNumberOnSuperHold
            onCheckedChanged: {
                Config.options.bar.workspaces.showNumberOnSuperHold = checked;
            }
        }

        ConfigSwitch {
            buttonIcon: "counter_1"
            text: Translation.tr('Always show numbers')
            checked: Config.options.bar.workspaces.alwaysShowNumbers
            onCheckedChanged: {
                Config.options.bar.workspaces.alwaysShowNumbers = checked;
            }
        }

        ConfigSwitch {
            visible: Config.options.bar.workspaces.style === 0
            buttonIcon: "award_star"
            text: Translation.tr('Show app icons')
            checked: Config.options.bar.workspaces.showAppIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.showAppIcons = checked;
            }
        }

        ConfigSwitch {
            visible: Config.options.bar.workspaces.style === 0 && Config.options.bar.workspaces.showAppIcons
            buttonIcon: "category"
            text: Translation.tr('Custom app icons')
            checked: Config.options.bar.workspaces.customAppIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.customAppIcons = checked;
            }
        }

        ConfigSwitch {
            visible: Config.options.bar.workspaces.style === 0
            buttonIcon: "colors"
            text: Translation.tr('Tint app icons')
            checked: Config.options.bar.workspaces.monochromeIcons
            onCheckedChanged: {
                Config.options.bar.workspaces.monochromeIcons = checked;
            }
        }

        ConfigSwitch {
            visible: Config.options.bar.workspaces.style === 0
            buttonIcon: "grid_3x3"
            text: Translation.tr('Use workspace map')
            checked: Config.options.bar.workspaces.useWorkspaceMap
            onCheckedChanged: {
                Config.options.bar.workspaces.useWorkspaceMap = checked;
            }
            StyledToolTip {
                text: Translation.tr('Edit the workspace start index for monitors in the config file')
            }
        }

        ConfigSwitch {
            buttonIcon: "swap_horiz"
            text: Translation.tr('Dynamic workspaces')
            checked: Config.options.bar.workspaces.dynamic
            onCheckedChanged: {
                Config.options.bar.workspaces.dynamic = checked;
            }
            StyledToolTip {
                text: Translation.tr('Only show occupied and active workspaces instead of a fixed count')
            }
        }

        ConfigSpinBox {
            icon: "view_column"
            text: Translation.tr("Workspaces shown")
            value: Config.options.bar.workspaces.shown
            from: 1
            to: 30
            stepSize: 1
            onValueChanged: {
                Config.options.bar.workspaces.shown = value;
            }
        }

        ConfigSpinBox {
            visible: Config.options.bar.workspaces.style === 0
            icon: "select_window"
            text: Translation.tr("Maximum window count per workspace")
            value: Config.options.bar.workspaces.maxWindowCount
            from: 1
            to: 20
            stepSize: 1
            onValueChanged: {
                Config.options.bar.workspaces.maxWindowCount = value;
            }
        }

        ConfigSpinBox {
            icon: "touch_long"
            text: Translation.tr("Number show delay when pressing Super (ms)")
            value: Config.options.bar.workspaces.showNumberDelay
            from: 0
            to: 1000
            stepSize: 50
            onValueChanged: {
                Config.options.bar.workspaces.showNumberDelay = value;
            }
        }

        ContentSubsection {
            visible: Config.options.bar.workspaces.style === 0
            title: Translation.tr("Number style")

            ConfigSelectionArray {
                currentValue: JSON.stringify(Config.options.bar.workspaces.numberMap)
                onSelected: newValue => {
                    Config.options.bar.workspaces.numberMap = JSON.parse(newValue)
                }
                options: [
                    {
                        displayName: Translation.tr("Normal"),
                        icon: "timer_10",
                        value: '[]'
                    },
                    {
                        displayName: Translation.tr("Han chars"),
                        icon: "square_dot",
                        value: '["一","二","三","四","五","六","七","八","九","十","十一","十二","十三","十四","十五","十六","十七","十八","十九","二十"]'
                    },
                    {
                        displayName: Translation.tr("Roman"),
                        icon: "account_balance",
                        value: '["I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII","XIII","XIV","XV","XVI","XVII","XVIII","XIX","XX"]'
                    },
                    {
                        displayName: Translation.tr("Spark"),
                        icon: "spark",
                        value: '["spark","spark","spark","spark","spark","spark","spark","spark","spark","spark","spark","spark","spark","spark","spark","spark","spark","spark","spark","spark"]'
                    }
                ]
            }
        }
    }

    ContentSection {
        icon: "tooltip"
        title: Translation.tr("Tooltips")
        ConfigSwitch {
            buttonIcon: "ads_click"
            text: Translation.tr("Click to show")
            checked: Config.options.bar.tooltips.clickToShow
            onCheckedChanged: {
                Config.options.bar.tooltips.clickToShow = checked;
            }
        }
    }
}
