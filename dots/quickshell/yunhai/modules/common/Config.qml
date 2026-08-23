pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common.functions

Singleton {
    id: root
    property string filePath: Directories.globalConfigPath
    property alias options: optionsFacade
    property bool ready: false
    property int readWriteDelay: 50 // milliseconds
    property bool blockWrites: false

    readonly property var activeFamilyAdapter: ({
        "lunae": lunaeAdapter,
        "waffle": waffleAdapter,
        "akebono": akebonoAdapter
    }[globalAdapter.panelFamily] ?? iiAdapter)

    function setNestedValue(nestedKey, value) {
        let keys = nestedKey.split(".");
        let obj = root.options;
        let parents = [obj];

        // Traverse and collect parent objects
        for (let i = 0; i < keys.length - 1; ++i) {
            if (!obj[keys[i]] || typeof obj[keys[i]] !== "object") {
                obj[keys[i]] = {};
            }
            obj = obj[keys[i]];
            parents.push(obj);
        }

        // Convert value to correct type using JSON.parse when safe
        let convertedValue = value;
        if (typeof value === "string") {
            let trimmed = value.trim();
            if (trimmed === "true" || trimmed === "false" || !isNaN(Number(trimmed))) {
                try {
                    convertedValue = JSON.parse(trimmed);
                } catch (e) {
                    convertedValue = value;
                }
            }
        }

        obj[keys[keys.length - 1]] = convertedValue;
    }

    component ConfigFile: QtObject {
        id: cf
        property string path
        default property alias adapter: cfView.adapter
        signal loaded()

        property FileView view: FileView {
            id: cfView
            path: cf.path
            watchChanges: true
            blockWrites: root.blockWrites
            onFileChanged: cfReloadTimer.restart()
            onAdapterUpdated: cfWriteTimer.restart()
            onLoaded: cf.loaded()
            onLoadFailed: error => {
                if (error == FileViewError.FileNotFound) {
                    writeAdapter();
                }
            }
        }
        property Timer reloadTimer: Timer {
            id: cfReloadTimer
            interval: root.readWriteDelay
            repeat: false
            onTriggered: cfView.reload()
        }
        property Timer writeTimer: Timer {
            id: cfWriteTimer
            interval: root.readWriteDelay
            repeat: false
            onTriggered: cfView.writeAdapter()
        }
    }

    component BarOptions: JsonObject {
        property JsonObject activeWindow: JsonObject {
            property bool fixedSize: false
        }
        property JsonObject autoHide: JsonObject {
            property bool enable: false
            property int hoverRegionWidth: 2
            property bool pushWindows: false
            property JsonObject showWhenPressingSuper: JsonObject {
                property bool enable: true
                property int delay: 140
            }
        }
        property bool bottom: false // Instead of top
        property int cornerStyle: 0 // 0: Hug | 1: Float | 2: Plain rectangle
        property bool floatStyleShadow: true // Show shadow behind bar when cornerStyle == 1 (Float)
        property bool borderless: false // true for no grouping of items
        property string topLeftIcon: "spark" // Options: "distro" or any icon name in ~/.config/quickshell/yunhai/assets/icons
        property int barBackgroundStyle: 1 // 0: Transparent | 1: Visible | 2: Adaptive
        property int componentBackgroundStyle: 1 // 0: Layer color | 1: Primary container
        property bool verbose: true
        property bool vertical: false
        property JsonObject mediaPlayer: JsonObject {
            property bool useCustomSize: false
            property int customSize: 300
        }
        property JsonObject resources: JsonObject {
            property bool alwaysShowRam: true
            property bool alwaysShowSwap: true
            property bool alwaysShowCpu: true
            property int memoryWarningThreshold: 95
            property int swapWarningThreshold: 85
            property int cpuWarningThreshold: 90
            property bool alwaysShowGpu: false
            property int gpuLayout: 0 // 0: dGPU only | 1: iGPU only | 2: Both
            property int gpuWarningThreshold: 90
        }
        property list<string> screenList: [] // List of names, like "eDP-1", find out with 'hyprctl monitors' command
        property JsonObject timers: JsonObject {
            property bool showPomodoro: true
            property bool showStopwatch: true
            property bool showCountdown: true
        }
        property JsonObject utilButtons: JsonObject {
            property bool showScreenSnip: true
            property bool showColorPicker: false
            property bool showMicToggle: false
            property bool showKeyboardToggle: true
            property bool showDarkModeToggle: true
            property bool showPerformanceProfileToggle: false
            property bool showScreenRecord: false
        }
        property JsonObject workspaces: JsonObject {
            property int style: 0 // 0: classic (icons + indicator), 1: dots, 2: windows
            property bool dynamic: false // true: show only occupied+active, false: fixed count from 'shown'
            property bool monochromeIcons: true
            property int shown: 10
            property bool showAppIcons: true
            property bool alwaysShowNumbers: false
            property bool showNumberOnSuperHold: true
            property int showNumberDelay: 300 // milliseconds
            property list<string> numberMap: ["1", "2"] // Characters to show instead of numbers on workspace indicator
            property bool useNerdFont: false
            property bool useWorkspaceMap: false
            property list<int> workspaceMap: [0, 10]
            property int maxWindowCount: 5
            property bool customAppIcons: false
            property bool renderMaterialSymbols: false
        }
        property JsonObject weather: JsonObject {
            property bool enable: false
            property bool enableGPS: true // gps based location
            property string city: "" // When 'enableGPS' is false
            property bool useUSCS: false // Instead of metric (SI) units
            property int fetchInterval: 10 // minutes
        }
        property JsonObject indicators: JsonObject {
            property JsonObject notifications: JsonObject {
                property bool showUnreadCount: false
            }
            property JsonObject capsLock: JsonObject {
                property bool enable: true
            }
        }
        property JsonObject layouts: JsonObject {
            // Only adding place-essential components to left-center-right
            // And adding the dynamic components to leftover
            property list<var> availableComps: [
                {
                    id: "record_indicator",
                    icon: "screen_record",
                    title: "Record indicator",
                    centered: false, // centered or not (only in center section)
                    visible: false,
                    scrollTo: "" // scroll to this component when clicked (has also to be configured in BarConfig)
                },
                {
                    id: "screen_share_indicator",
                    icon: "screen_share",
                    title: "Screen share indicator",
                    centered: false,
                    visible: false,
                    scrollTo: ""
                },
                {
                    id: "date",
                    icon: "date_range",
                    title: "Date",
                    centered: false,
                    visible: true,
                    scrollTo: ""
                },
                {
                    id: "battery",
                    icon: "battery_android_6",
                    title: "Battery",
                    centered: false,
                    visible: true,
                    scrollTo: ""
                },
                {
                    id: "timer",
                    icon: "timer",
                    title: "Timer & Pomodoro",
                    centered: false,
                    visible: true,
                    scrollTo: "timerAndPomodoro"
                },
                {
                    id: "caps_lock",
                    icon: "font_download",
                    title: "Caps Lock indicator",
                    centered: false,
                    visible: true,
                    scrollTo: ""
                },
                {
                    id: "weather",
                    icon: "partly_cloudy_day",
                    title: "Weather",
                    centered: false,
                    visible: true,
                    scrollTo: "weather"
                },
                {
                    id: "equalizer",
                    icon: "graphic_eq",
                    title: "Equalizer",
                    centered: false,
                    visible: true,
                    scrollTo: ""
                }
            ]
            property list<var> left: [
                {
                    id: "active_window",
                    icon: "label",
                    title: "Active window",
                    centered: false,
                    visible: true,
                    scrollTo: "active_window"
                },
            ]
            property list<var> center: [
                {
                    id: "music_player",
                    icon: "music_note",
                    title: "Music player",
                    centered: false,
                    visible: true,
                    scrollTo: "music_player"
                },
                {
                    id: "workspaces",
                    icon: "workspaces",
                    title: "Workspaces",
                    centered: false,
                    visible: true,
                    scrollTo: "workspaces"
                },
                {
                    id: "system_monitor",
                    icon: "monitor_heart",
                    title: "System monitor",
                    centered: false,
                    visible: true,
                    scrollTo: ""
                }
            ]
            property list<var> right: [
                {
                    id: "utility_buttons",
                    icon: "build",
                    title: "Utility buttons",
                    centered: false,
                    visible: true,
                    scrollTo: "utility_buttons"
                },
                {
                    id: "clock",
                    icon: "nest_clock_farsight_analog",
                    title: "Clock",
                    centered: false,
                    visible: true,
                    scrollTo: ""
                },
                {
                    id: "system_tray",
                    icon: "system_update_alt",
                    title: "System tray",
                    centered: false,
                    visible: true,
                    scrollTo: "system_tray"
                }
            ]

        }
        property JsonObject tooltips: JsonObject {
            property bool clickToShow: false
        }
        property JsonObject sizes: JsonObject {
            property int height: 40 // horizontal mode
            property int width: 46 // vertical mode
        }
    }

    component DockOptions: JsonObject {
        property bool enable: false
        property bool monochromeIcons: true
        property real height: 60
        property real hoverRegionHeight: 2
        property bool pinnedOnStartup: false
        property bool hoverToReveal: true // When false, only reveals on empty workspace
        property bool smartHide: true
        property bool showTrash: true
        property list<string> pinnedApps: [ // IDs of pinned entries
            "org.kde.dolphin", "kitty",]
        property list<string> ignoredAppRegexes: []
    }

    component ScreenOptions: JsonObject {
        property int fakeScreenRounding: 2 // 0: None | 1: Always | 2: When not fullscreen | 3: Wrapped
        property int wrappedFrameThickness: 10
    }

    component OverlayOptions: JsonObject {
        property bool openingZoomAnimation: true
        property bool darkenScreen: true
        property real clickthroughOpacity: 0.8
        property bool showOffscreenButton: true
        property list<string> buttons: [
            "crosshair",
            "fpsLimiter",
            "notes",
            "floatingImage",
            "processMonitor",
            "recorder",
            "resources",
            "media",
            "volumeMixer",
            "webView"
        ]
        property JsonObject floatingImage: JsonObject {
            property string imageSource: "https://media.tenor.com/H5U5bJzj3oAAAAAi/kukuru.gif"
            property real scale: 2
            property bool resizable: true
        }
        property JsonObject notes: JsonObject {
            property bool showTabs: true
            property bool allowEditingIcon: true
        }
        property JsonObject webView: JsonObject {
            property list<var> bookmarks: [
                {
                    "name": "DuckDuckGo",
                    "url": "https://duckduckgo.com"
                },
                {
                    "name": "GitHub",
                    "url": "https://github.com"
                }
            ]
        }
    }

    component SidebarOptions: JsonObject {
        property bool keepRightSidebarLoaded: true
        property JsonObject translator: JsonObject {
            property bool enable: false
            property bool useDeepL: false
            property int delay: 300 // Delay before sending request. Reduces (potential) rate limits and lag.
        }
        property JsonObject ai: JsonObject {
            property bool textFadeIn: false
        }
        property JsonObject booru: JsonObject {
            property bool allowNsfw: false
            property string downloadPath: "~/Pictures/homework"
            property string defaultProvider: "yandere"
            property int limit: 20
            property JsonObject zerochan: JsonObject {
                property string username: "[unset]"
            }
        }
        property JsonObject cornerOpen: JsonObject {
            property bool enable: true
            property bool bottom: false
            property bool valueScroll: true
            property bool clickless: false
            property int cornerRegionWidth: 250
            property int cornerRegionHeight: 5
            property bool visualize: false
            property bool clicklessCornerEnd: true
            property int clicklessCornerVerticalOffset: 1
        }

        property JsonObject quickToggles: JsonObject {
            property string style: "android" // Options: classic, android
            property JsonObject android: JsonObject {
                property int columns: 5
                property list<var> toggles: [
                    { "size": 2, "type": "network" },
                    { "size": 2, "type": "bluetooth"  },
                    { "size": 1, "type": "idleInhibitor" },
                    { "size": 1, "type": "mic" },
                    { "size": 2, "type": "audio" },
                    { "size": 2, "type": "nightLight" }
                ]
            }
        }

        property JsonObject quickSliders: JsonObject {
            property bool enable: false
            property bool showMic: false
            property bool showVolume: true
            property bool showBrightness: true
        }
    }

    ConfigFile {
        id: globalFile
        path: root.filePath
        onLoaded: root.ready = true

        JsonAdapter {
            id: globalAdapter

            property string panelFamily: "ii" // "ii", "waffle", "lunae", "akebono"

            property JsonObject policies: JsonObject {
                property int ai: 1 // 0: No | 1: Yes | 2: Local
                property int weeb: 1 // 0: No | 1: Open | 2: Closet
            }

            property JsonObject ai: JsonObject {
                property bool autoSave: false
                property int autoSaveResponses: 3
                property string systemPrompt: "## Style\n- Use casual tone, don't be formal!\n- Always be brief and to the point, unless asked otherwise\n- Don't repeat the user's question\n- Be approachable: Avoid using overly complicated, domain-specific terms and provide analogies when asked to explain a concept\n\n## Context (ignore when irrelevant)\n- You are a helpful and inspiring sidebar assistant on a {DISTRO} Linux system\n- Desktop environment: {DE}\n- Current date & time: {DATETIME}\n- Focused app: {WINDOWCLASS}\n\n## Presentation\n- Use Markdown features in your response: \n  - **Bold** text to **highlight keywords** in your response\n  - **Split long information into small sections** with h2 headers and a relevant emoji at the start of it (for example `## 🐧 Linux`). Bullet points are preferred over long paragraphs, unless you're offering writing support or instructed otherwise by the user.\n- Asked to compare different options? You should firstly use a table to compare the main aspects, then elaborate or include relevant comments from online forums *after* the table. Make sure to provide a final recommendation for the user's use case!\n- Use LaTeX formatting for mathematical and scientific notations whenever appropriate. Enclose all LaTeX '$$' delimiters. NEVER generate LaTeX code in a latex block unless the user explicitly asks for it. DO NOT use LaTeX for regular documents (resumes, letters, essays, CVs, etc.).\n\nThanks!\n"
                property string tool: "functions" // search, functions, or none
                property list<var> extraModels: [
                    {
                        "api_format": "openai", // Most of the time you want "openai". Use "gemini" for Google's models
                        "description": "This is a custom model. Edit the config to add more! | Anyway, this is DeepSeek R1 Distill LLaMA 70B",
                        "endpoint": "https://openrouter.ai/api/v1/chat/completions",
                        "homepage": "https://openrouter.ai/deepseek/deepseek-r1-distill-llama-70b:free", // Not mandatory
                        "icon": "spark-symbolic", // Not mandatory
                        "key_get_link": "https://openrouter.ai/settings/keys", // Not mandatory
                        "key_id": "openrouter",
                        "model": "deepseek/deepseek-r1-distill-llama-70b:free",
                        "name": "Custom: DS R1 Dstl. LLaMA 70B",
                        "requires_key": true
                    }
                ]
            }

            property JsonObject appearance: JsonObject {
                property bool extraBackgroundTint: true
                property JsonObject fonts: JsonObject {
                    property string main: "Google Sans Flex"
                    property string numbers: "Google Sans Flex"
                    property string title: "Google Sans Flex"
                    property string iconNerd: "JetBrains Mono NF"
                    property string monospace: "JetBrains Mono NF"
                    property string reading: "Readex Pro"
                    property string expressive: "Space Grotesk"
                }
                property JsonObject transparency: JsonObject {
                    property bool enable: false
                    property bool automatic: true
                    property real backgroundTransparency: 0.11
                    property real contentTransparency: 0.57
                }
                property JsonObject wallpaperTheming: JsonObject {
                    property bool enableAppsAndShell: true
                    property bool enableQtApps: true
                    property bool enableTerminal: true
                    property JsonObject terminalGenerationProps: JsonObject {
                        property real harmony: 0.6
                        property real harmonizeThreshold: 100
                        property real termFgBoost: 0.35
                        property real termBgTone: 0.4
                        property bool forceDarkMode: false
                    }
                }
                property JsonObject palette: JsonObject {
                    property string type: "auto" // Allowed: auto, scheme-content, scheme-expressive, scheme-fidelity, scheme-fruit-salad, scheme-monochrome, scheme-neutral, scheme-rainbow, scheme-tonal-spot
                    property string accentColor: ""
                    property string mode: "" // "dark" or "light" — set by QuickConfig to signal mode changes cross-process
                }
            }

            property JsonObject audio: JsonObject {
                // Values in %
                property JsonObject protection: JsonObject {
                    // Prevent sudden bangs
                    property bool enable: false
                    property real maxAllowedIncrease: 10
                    property real maxAllowed: 99
                }
            }

            property JsonObject gameMode: JsonObject {
                property bool disableAnimations: true
                property bool disableShadows: true
                property bool disableBlur: true
                property bool removeGaps: true
                property bool setBorderSize: true
                property int borderSize: 1
                property bool disableRounding: true
                property bool enableTearing: true
            }

            property JsonObject apps: JsonObject {
                property string bluetooth: "kcmshell6 kcm_bluetooth"
                property string changePassword: "kitty -1 --hold=yes fish -i -c 'passwd'"
                property string network: "kcmshell6 kcm_networkmanagement"
                property string manageUser: "kcmshell6 kcm_users"
                property string networkEthernet: "kcmshell6 kcm_networkmanagement"
                property string taskManager: "plasma-systemmonitor --page-name Processes"
                property string terminal: "kitty -1" // This is only for shell actions
                property string update: "kitty -1 --hold=yes fish -i -c 'pkexec pacman -Syu'"
                property string volumeMixer: `~/.config/hypr/hyprland/scripts/launch_first_available.sh "pavucontrol-qt" "pavucontrol"`
            }

            property JsonObject background: JsonObject {
                property JsonObject widgets: JsonObject {
                    property JsonObject clock: JsonObject {
                        property bool enable: true
                        property bool showOnlyWhenLocked: false
                        property string placementStrategy: "leastBusy" // "free", "leastBusy", "mostBusy"
                        property real x: 100
                        property real y: 100
                        property string style: "cookie"        // Options: "cookie", "digital", "lunae"
                        property string styleLocked: "cookie"  // Options: "cookie", "digital", "lunae"
                        property JsonObject cookie: JsonObject {
                            property bool aiStyling: false
                            property int sides: 14
                            property string dialNumberStyle: "full"   // Options: "dots" , "numbers", "full" , "none"
                            property string hourHandStyle: "fill"     // Options: "classic", "fill", "hollow", "hide"
                            property string minuteHandStyle: "medium" // Options "classic", "thin", "medium", "bold", "hide"
                            property string secondHandStyle: "dot"    // Options: "dot", "line", "classic", "hide"
                            property string dateStyle: "bubble"       // Options: "border", "rect", "bubble" , "hide"
                            property bool timeIndicators: true
                            property bool hourMarks: false
                            property bool dateInClock: true
                            property bool constantlyRotate: false
                            property bool useSineCookie: false
                        }
                        property JsonObject digital: JsonObject {
                            property bool adaptiveAlignment: true
                            property bool showDate: true
                            property bool animateChange: true
                            property bool vertical: false
                            property JsonObject font: JsonObject {
                                property string family: "Google Sans Flex"
                                property real weight: 350
                                property real width: 100
                                property real size: 90
                                property real roundness: 0
                            }
                        }
                        property JsonObject quote: JsonObject {
                            property bool enable: false
                            property string text: ""
                        }
                    }
                    property JsonObject weather: JsonObject {
                        property bool enable: false
                        property string placementStrategy: "free" // "free", "leastBusy", "mostBusy"
                        property real x: 400
                        property real y: 100
                        property string style: "cookie" // "cookie", "digital"
                        property JsonObject digital: JsonObject {
                            property bool showCity: true
                            property bool cityBelow: true // false = city on same line as temp
                            property bool showIcon: true
                            property JsonObject font: JsonObject {
                                property string family: "Google Sans Flex"
                                property real weight: 350
                                property real width: 100
                                property real size: 90
                                property real roundness: 0
                            }
                        }
                    }
                }
                property string wallpaperPath: ""
                property string thumbnailPath: ""
                property bool hideWhenFullscreen: true
                property JsonObject parallax: JsonObject {
                    property bool vertical: false
                    property bool autoVertical: false
                    property bool enableWorkspace: true
                    property real workspaceZoom: 1.0 // Relative to wallpaper size
                    property bool enableSidebar: true
                    property real widgetsFactor: 1.2
                }
            }

            property JsonObject battery: JsonObject {
                property int low: 20
                property int critical: 5
                property int full: 101
                property bool automaticSuspend: true
                property int suspend: 3
            }

            property JsonObject calendar: JsonObject {
                property string locale: "en-GB"
            }

            property JsonObject cheatsheet: JsonObject {
                // Use a nerdfont to see the icons
                // 0: 󰖳  | 1: 󰌽 | 2: 󰘳 | 3:  | 4: 󰨡
                // 5:  | 6:  | 7: 󰣇 | 8:  | 9:
                // 10:  | 11:  | 12:  | 13:  | 14: 󱄛
                property string superKey: ""
                property bool useMacSymbol: false
                property bool splitButtons: false
                property bool useMouseSymbol: false
                property bool useFnSymbol: false
                property JsonObject fontSize: JsonObject {
                    property int key: Appearance.font.pixelSize.smaller
                    property int comment: Appearance.font.pixelSize.smaller
                }
            }

            property JsonObject conflictKiller: JsonObject {
                property bool autoKillNotificationDaemons: false
                property bool autoKillTrays: false
            }

            property JsonObject crosshair: JsonObject {
                // Valorant crosshair format. Use https://www.vcrdb.net/builder
                property string code: "0;P;d;1;0l;10;0o;2;1b;0"
            }

            property JsonObject interactions: JsonObject {
                property JsonObject scrolling: JsonObject {
                    property bool fasterTouchpadScroll: false // Enable faster scrolling with touchpad
                    property int mouseScrollDeltaThreshold: 120 // delta >= this then it gets detected as mouse scroll rather than touchpad
                    property int mouseScrollFactor: 120
                    property int touchpadScrollFactor: 450
                }
                property JsonObject deadPixelWorkaround: JsonObject { // Hyprland leaves out 1 pixel on the right for interactions
                    property bool enable: false
                }
            }

            property JsonObject language: JsonObject {
                property string ui: "auto" // UI language. "auto" for system locale, or specific language code like "zh_CN", "en_US"
                property JsonObject translator: JsonObject {
                    property string engine: "auto" // Run `trans -list-engines` for available engines. auto should use google
                    property string targetLanguage: "auto" // Run `trans -list-all` for available languages
                    property string sourceLanguage: "auto"
                }
            }

            property JsonObject launcher: JsonObject {
                property list<string> pinnedApps: [ "org.kde.dolphin", "kitty", "cmake-gui"]
            }

            property JsonObject light: JsonObject {
                property JsonObject night: JsonObject {
                    property bool automatic: true
                    property string from: "19:00" // Format: "HH:mm", 24-hour time
                    property string to: "06:30"   // Format: "HH:mm", 24-hour time
                    property int colorTemperature: 5000
                }
                property JsonObject antiFlashbang: JsonObject {
                    property bool enable: false
                }
            }

            property JsonObject lock: JsonObject {
                property bool useHyprlock: false
                property bool launchOnStartup: false
                property JsonObject blur: JsonObject {
                    property bool enable: true
                    property real radius: 100
                    property real extraZoom: 1.1
                }
                property bool centerClock: true
                property bool showLockedText: true
                property JsonObject security: JsonObject {
                    property bool unlockKeyring: true
                    property bool requirePasswordToPower: false
                }
                property bool materialShapeChars: true
            }

            property JsonObject media: JsonObject {
                // Attempt to remove dupes (the aggregator playerctl one and browsers' native ones when there's plasma browser integration)
                property bool filterDuplicatePlayers: true

                property JsonObject lyrics: JsonObject {
                    property bool enable: true
                    property bool online: true
                    property real offset: 0
                }
            }

            property JsonObject networking: JsonObject {
                property string userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
            }

            property JsonObject notifications: JsonObject {
                property int timeout: 7000
            }

            property JsonObject osd: JsonObject {
                property int timeout: 1000
            }

            property JsonObject osk: JsonObject {
                property string layout: "qwerty_full"
                property bool pinnedOnStartup: false
            }

            property JsonObject overview: JsonObject {
                property bool enable: true
                property real scale: 0.18 // Relative to screen size
                property real rows: 2
                property real columns: 5
                property bool orderRightLeft: false
                property bool orderBottomUp: false
                property bool centerIcons: true
            }

            property JsonObject regionSelector: JsonObject {
                property JsonObject targetRegions: JsonObject {
                    property bool windows: true
                    property bool layers: false
                    property bool content: true
                    property bool showLabel: false
                    property real opacity: 0.3
                    property real contentRegionOpacity: 0.8
                    property int selectionPadding: 5
                }
                property JsonObject rect: JsonObject {
                    property bool showAimLines: true
                }
                property JsonObject circle: JsonObject {
                    property int strokeWidth: 6
                    property int padding: 10
                }
                property JsonObject annotation: JsonObject {
                    property string command: "swappy -f %f"
                }
            }

            // Global resource monitoring settings (for overlay and system-wide monitoring)
            // Note: bar.resources controls bar-specific display settings
            property JsonObject resources: JsonObject {
                property int updateInterval: 3000 // milliseconds
                property int historyLength: 60 // data points to keep in history

                // Enable/disable resource monitoring globally
                property bool enableCpu: true
                property bool enableGpu: true
                property bool enableRam: true
                property bool enableSwap: true

                property JsonObject gpu: JsonObject {
                    // Manual card override, matched against GpuDevice.card (e.g. "card1")
                    property string dgpuCard: ""
                    property string igpuCard: ""

                    // Manual GPU name override (if empty, uses detected name)
                    property string dgpuName: ""
                    property string igpuName: ""

                    // Overlay widget GPU display settings
                    property JsonObject overlay: JsonObject {
                        property bool showDGpu: true
                        property bool showIGpu: false
                        property list<var> dGpuMetrics: [
                            { id: "usage", icon: "speed", title: "Usage", scrollTo: "" },
                            { id: "vram", icon: "storage", title: "VRAM", scrollTo: "" },
                            { id: "temp", icon: "device_thermostat", title: "Temperature", scrollTo: "" },
                            { id: "fan", icon: "air", title: "Fan", scrollTo: "" },
                            { id: "power", icon: "bolt", title: "Power", scrollTo: "" }
                        ]
                        property list<var> dGpuAvailableMetrics: [
                            { id: "tempJunction", icon: "local_fire_department", title: "Junction Temp", scrollTo: "" },
                            { id: "tempMem", icon: "memory_alt", title: "Memory Temperature", scrollTo: "" }
                        ]
                        property list<var> iGpuMetrics: [
                            { id: "usage", icon: "speed", title: "Usage", scrollTo: "" },
                            { id: "vram", icon: "storage", title: "VRAM", scrollTo: "" },
                            { id: "temp", icon: "device_thermostat", title: "Temperature", scrollTo: "" }
                        ]
                        property list<var> iGpuAvailableMetrics: []
                    }

                    // Bar popup GPU settings
                    property JsonObject bar: JsonObject {
                        property bool showDGpu: true
                        property bool showIGpu: false
                        property list<var> dGpuMetrics: [
                            { id: "usage", icon: "speed", title: "Usage", scrollTo: "" },
                            { id: "vram", icon: "storage", title: "VRAM", scrollTo: "" },
                            { id: "temp", icon: "device_thermostat", title: "Temperature", scrollTo: "" }
                        ]
                        property list<var> dGpuAvailableMetrics: [
                            { id: "fan", icon: "air", title: "Fan", scrollTo: "" },
                            { id: "power", icon: "bolt", title: "Power", scrollTo: "" },
                            { id: "tempJunction", icon: "local_fire_department", title: "Junction Temp", scrollTo: "" },
                            { id: "tempMem", icon: "memory_alt", title: "Memory Temperature", scrollTo: "" }
                        ]
                        property list<var> iGpuMetrics: [
                            { id: "usage", icon: "speed", title: "Usage", scrollTo: "" },
                            { id: "vram", icon: "storage", title: "VRAM", scrollTo: "" },
                            { id: "temp", icon: "device_thermostat", title: "Temperature", scrollTo: "" }
                        ]
                        property list<var> iGpuAvailableMetrics: []
                    }
                }
            }

            property JsonObject tray: JsonObject {
                property bool monochromeIcons: true
                property bool showItemId: false
                property bool invertPinnedItems: true // Makes the below a whitelist for the tray and blacklist for the pinned area
                property list<var> pinnedItems: [ "Fcitx" ]
                property bool filterPassive: true
            }

            property JsonObject musicRecognition: JsonObject {
                property int timeout: 16
                property int interval: 4
            }

            property JsonObject search: JsonObject {
                property int nonAppResultDelay: 30 // This prevents lagging when typing
                property string engineBaseUrl: "https://www.google.com/search?q="
                property list<string> excludedSites: ["quora.com", "facebook.com"]
                property bool sloppy: false // Uses levenshtein distance based scoring instead of fuzzy sort. Very weird.
                property JsonObject prefix: JsonObject {
                    property bool showDefaultActionsWithoutPrefix: true
                    property string action: "/"
                    property string app: ">"
                    property string clipboard: ";"
                    property string emojis: ":"
                    property string kaomojis: "~"
                    property string math: "="
                    property string shellCommand: "$"
                    property string symbols: "^"
                    property string webSearch: "?"
                }
                property list<string> hiddenApps: []
                property JsonObject imageSearch: JsonObject {
                    property string imageSearchEngineBaseUrl: "https://lens.google.com/uploadbyurl?url="
                    property bool useCircleSelection: false
                }
            }

            property JsonObject screenRecord: JsonObject {
                property string savePath: Directories.videos.replace("file://","") // strip "file://"
                property int qualityQp: 28
                property int maxFps: 30
                property bool hardwareEncoding: false
                property bool recordAudio: false
                property bool showBreathingBorder: true
            }

            property JsonObject screenSnip: JsonObject {
                property string savePath: "" // only copy to clipboard when empty
                property string monitorScope: "all" // all | focused

                property JsonObject translator: JsonObject {
                    property string ocrBackend: "google"
                    property string translationEngine: "trans"
                    property real textBoxOpacity: 0.85
                    property bool usePreprocessing: true
                    property string ocrLanguage: "auto"
                    property string targetLanguage: "auto"
                }
            }

            property JsonObject sounds: JsonObject {
                property bool battery: false
                property bool pomodoro: false
                property bool countdown: true
                property string theme: "freedesktop"
            }

            property JsonObject time: JsonObject {
                // https://doc.qt.io/qt-6/qtime.html#toString
                property string format: "hh:mm"
                property string shortDateFormat: "dd/MM"
                property string dateWithYearFormat: "dd/MM/yyyy"
                property string dateFormat: "ddd, dd/MM"
                property JsonObject pomodoro: JsonObject {
                    property int breakTime: 300
                    property int cyclesBeforeLongBreak: 4
                    property int focus: 1500
                    property int longBreak: 900
                }
                property bool secondPrecision: false
            }

            property JsonObject updates: JsonObject {
                property bool enableCheck: true
                property int checkInterval: 120 // minutes
                property int adviseUpdateThreshold: 75 // packages
                property int stronglyAdviseUpdateThreshold: 200 // packages
            }

            property JsonObject wallpaperSelector: JsonObject {
                property bool useSystemFileDialog: false
                property bool keepLoaded: false
                property string downloadPath: "~/Pictures/Wallpapers"
            }

            property JsonObject windows: JsonObject {
                property bool showTitlebar: true // Client-side decoration for shell apps
                property bool centerTitle: true
            }

            property JsonObject hacks: JsonObject {
                property int arbitraryRaceConditionDelay: 20 // milliseconds
            }

            property JsonObject workSafety: JsonObject {
                property JsonObject enable: JsonObject {
                    property bool wallpaper: false
                    property bool clipboard: false
                }
                property JsonObject triggerCondition: JsonObject {
                    property list<string> networkNameKeywords: ["airport", "cafe", "college", "company", "eduroam", "free", "guest", "public", "school", "university"]
                    property list<string> fileKeywords: ["anime", "booru", "ecchi", "hentai", "yande.re", "konachan", "breast", "nipples", "pussy", "nsfw", "spoiler", "girl"]
                    property list<string> linkKeywords: ["hentai", "porn", "sukebei", "hitomi.la", "rule34", "gelbooru", "fanbox", "dlsite"]
                }
            }
        }
    }

    ConfigFile {
        id: iiFile
        path: Directories.familyConfigPath("ii")
        JsonAdapter {
            id: iiAdapter
            property BarOptions bar: BarOptions {}
            property SidebarOptions sidebar: SidebarOptions {}
            property DockOptions dock: DockOptions {}
            property OverlayOptions overlay: OverlayOptions {}
            property ScreenOptions screen: ScreenOptions {}
        }
    }

    ConfigFile {
        id: lunaeFile
        path: Directories.familyConfigPath("lunae")
        JsonAdapter {
            id: lunaeAdapter
            property BarOptions bar: BarOptions {}
            property SidebarOptions sidebar: SidebarOptions {}
            property DockOptions dock: DockOptions {}
            property OverlayOptions overlay: OverlayOptions {}
            property ScreenOptions screen: ScreenOptions {}

            property JsonObject lunae: JsonObject {
                property string monitor: "" // Output name to pin the shell to, empty = first screen
                property bool colorful: true
                property bool bouncyAnimations: true
                property real deformStrength: 1.5
                property JsonObject hub: JsonObject {
                    property list<string> tabs: ["dash", "media", "weather", "system"]
                    property JsonObject dash: JsonObject {
                        property string gifSource: "https://media4.giphy.com/media/v1.Y2lkPTc5MGI3NjExbDZrc3VrazR2eHN3dWZjaGJlNHU0djM1ZDZqYzVvcTczYWZhdTVhZCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/oz45ELYgMoYVsZqmor/giphy.gif"
                    }
                    property JsonObject media: JsonObject {
                        property string gifSource: "https://media.tenor.com/H9-uWnxDmI8AAAAj/hu-tao-dance.gif"
                        property bool showLyrics: true
                    }
                }
                property JsonObject osd: JsonObject {
                    property string gifSource: ""
                    property int gifNudgeUp: 8
                    property int gifNudgeRight: 8
                    property bool showBoth: true
                    property bool positionRight: false
                }
                property JsonObject runner: JsonObject {
                    property bool showFilters: true
                }
                property JsonObject screenSnip: JsonObject {
                    property string toolbarPosition: "top"
                    property bool cursorToolTip: true
                }
                property JsonObject sidebar: JsonObject {
                    property bool splitMode: true
                    property JsonObject sliders: JsonObject {
                        property bool showBrightness: true
                        property bool showVolume: true
                    }
                    property JsonObject toggles: JsonObject {
                        property bool flickable: true
                        property list<string> enabled: [
                            "network", "bluetooth", "nightLight",
                            "idleInhibitor", "gameMode", "easyEffects",
                            "cloudflareWarp", "darkMode", "mic", "screenSnip"
                        ]
                    }
                }
            }
        }
    }

    ConfigFile {
        id: waffleFile
        path: Directories.familyConfigPath("waffle")
        JsonAdapter {
            id: waffleAdapter
            property BarOptions bar: BarOptions {}
            property SidebarOptions sidebar: SidebarOptions {}
            property DockOptions dock: DockOptions {}
            property OverlayOptions overlay: OverlayOptions {}
            property ScreenOptions screen: ScreenOptions {}

            property JsonObject waffles: JsonObject {
                // Some spots are kinda janky/awkward. Setting the following to
                // false will make (some) stuff also be like that for accuracy.
                // Example: the right-click menu of the Start button
                property JsonObject tweaks: JsonObject {
                    property bool switchHandlePositionFix: true
                    property bool smootherMenuAnimations: true
                    property bool smootherSearchBar: true
                }
                property JsonObject bar: JsonObject {
                    property bool bottom: true
                    property bool leftAlignApps: false
                }
                property JsonObject actionCenter: JsonObject {
                    property list<string> toggles: [ "network", "bluetooth", "easyEffects", "powerProfile", "idleInhibitor", "nightLight", "darkMode", "antiFlashbang", "cloudflareWarp", "mic", "musicRecognition", "notifications", "onScreenKeyboard", "gameMode", "screenSnip", "colorPicker" ]
                }
                property JsonObject calendar: JsonObject {
                    property bool force2CharDayOfWeek: true
                }
            }
        }
    }

    ConfigFile {
        id: akebonoFile
        path: Directories.familyConfigPath("akebono")
        JsonAdapter {
            id: akebonoAdapter
            property BarOptions bar: BarOptions {}
            property SidebarOptions sidebar: SidebarOptions {}
            property DockOptions dock: DockOptions { enable: true }
            property OverlayOptions overlay: OverlayOptions {}
            property ScreenOptions screen: ScreenOptions {}

            property JsonObject akebono: JsonObject {
                property JsonObject squircle: JsonObject {
                    property real smoothing: 4.0
                }
                property JsonObject preview: JsonObject {
                    property bool enable: true
                }
                property JsonObject hyprbars: JsonObject {
                    property bool enable: true
                    property bool glyphs: false
                    property bool macColors: false
                }
                property JsonObject runner: JsonObject {
                    property bool favourites: true
                    property bool dim: true
                    property bool glyphPicker: true
                    property int glyphPickerWidth: 360
                    property int glyphPickerHeight: 300
                    property int glyphPickerScale: 100
                    property string style: "shelf" // "shelf" | "sheet"
                    property int sheetWidth: 720
                    property int sheetHeight: 560
                }
                property JsonObject shelf: JsonObject {
                    property string position: "bottom" // "bottom" | "top"
                    property string shape: "inverseHug" // "float" | "inverseHug" | "hug" | "rect"
                    property bool pills: true
                    property string lengthMode: "full" // "full" | "fit" | "fixed"
                    property int fixedLength: 900
                    property int height: 54
                    property bool minimizeOnClick: true
                    property bool popupsDetached: false
                    property JsonObject status: JsonObject {
                        property bool notifications: true
                        property bool mic: true
                        property bool capsLock: true
                        property bool keyboardLayout: false
                        property bool bluetooth: true
                        property bool volume: true
                        property bool network: true
                        property bool battery: true
                    }
                    property JsonObject media: JsonObject {
                        property string layout: "art" // "art" | "icon"
                        property bool showTitle: true
                        property bool showLyricsInline: false
                        property bool lyricsExpand: false
                        property bool lyricsShown: true
                        property bool audioRipple: false
                    }
                    property JsonObject quickSettings: JsonObject {
                        property list<var> toggles: ["network", "bluetooth", "nightLight", "darkMode", "audio", "mic"]
                        property bool flickable: false
                    }
                    property JsonObject layout: JsonObject {
                        property list<var> availableComps: [
                            { id: "launcher", icon: "apps", title: "Launcher", centered: false, visible: true, scrollTo: "" },
                            { id: "workspaces", icon: "workspaces", title: "Workspaces", centered: false, visible: true, scrollTo: "" },
                            { id: "dock", icon: "dock_to_bottom", title: "App dock", centered: false, visible: true, scrollTo: "" },
                            { id: "sidebar", icon: "dock_to_left", title: "Sidebar", centered: false, visible: true, scrollTo: "" },
                            { id: "record", icon: "screen_record", title: "Recording", centered: false, visible: true, scrollTo: "" },
                            { id: "screenshare", icon: "screen_share", title: "Screen share", centered: false, visible: true, scrollTo: "" },
                            { id: "timer", icon: "timer", title: "Timer & Pomodoro", centered: false, visible: true, scrollTo: "" },
                            { id: "media", icon: "music_note", title: "Media", centered: false, visible: true, scrollTo: "" },
                            { id: "equalizer", icon: "graphic_eq", title: "Equalizer", centered: false, visible: true, scrollTo: "" },
                            { id: "resources", icon: "memory", title: "Resources", centered: false, visible: true, scrollTo: "" },
                            { id: "weather", icon: "partly_cloudy_day", title: "Weather", centered: false, visible: true, scrollTo: "" },
                            { id: "clock", icon: "nest_clock_farsight_analog", title: "Clock", centered: false, visible: true, scrollTo: "" },
                            { id: "system_tray", icon: "system_update_alt", title: "System tray", centered: false, visible: true, scrollTo: "" },
                            { id: "status", icon: "tune", title: "Quick settings", centered: false, visible: true, scrollTo: "" }
                        ]
                        property list<var> left: [
                            { id: "launcher", icon: "apps", title: "Launcher", centered: false, visible: true, scrollTo: "" },
                            { id: "workspaces", icon: "workspaces", title: "Workspaces", centered: false, visible: true, scrollTo: "" }
                        ]
                        property list<var> center: [
                            { id: "dock", icon: "dock_to_bottom", title: "App dock", centered: false, visible: true, scrollTo: "" }
                        ]
                        property list<var> right: [
                            { id: "record", icon: "screen_record", title: "Recording", centered: false, visible: true, scrollTo: "" },
                            { id: "screenshare", icon: "screen_share", title: "Screen share", centered: false, visible: true, scrollTo: "" },
                            { id: "timer", icon: "timer", title: "Timer & Pomodoro", centered: false, visible: true, scrollTo: "" },
                            { id: "media", icon: "music_note", title: "Media", centered: false, visible: true, scrollTo: "" },
                            { id: "equalizer", icon: "graphic_eq", title: "Equalizer", centered: false, visible: true, scrollTo: "" },
                            { id: "resources", icon: "memory", title: "Resources", centered: false, visible: true, scrollTo: "" },
                            { id: "weather", icon: "partly_cloudy_day", title: "Weather", centered: false, visible: true, scrollTo: "" },
                            { id: "clock", icon: "nest_clock_farsight_analog", title: "Clock", centered: false, visible: true, scrollTo: "" },
                            { id: "system_tray", icon: "system_update_alt", title: "System tray", centered: false, visible: true, scrollTo: "" },
                            { id: "status", icon: "tune", title: "Quick settings", centered: false, visible: true, scrollTo: "" }
                        ]
                    }
                }
                property JsonObject desktop: JsonObject {
                    property bool enable: true
                    property bool showIcons: true
                    property bool showWidgets: true
                    property bool widgetWobble: true
                    property bool widgetShadow: true
                    property real widgetShadowStrength: 0.5
                    property int iconSize: 48 // 48 | 64 | 96
                    property string sortBy: "name" // name | date | size | type
                    property bool showHidden: false
                    property bool showExtensions: false
                    property int iconSpacingX: 56
                    property int iconSpacingY: 16
                    property list<string> hiddenIcons: []
                    property JsonObject shortcuts: JsonObject {
                        property string trash: "Delete"
                        property string rename: "F2"
                        property string copy: "Ctrl+C"
                        property string cut: "Ctrl+X"
                        property string paste: "Ctrl+V"
                        property string selectAll: "Ctrl+A"
                        property string open: "Return"
                        property string deselect: "Escape"
                    }
                }
                property JsonObject session: JsonObject {
                    property string gifPath: ""
                    property int gifHeight: 220
                }
                property JsonObject overview: JsonObject {
                    property bool classic: false
                }
                property JsonObject osd: JsonObject {
                    property string gifSource: ""
                    property int gifNudgeUp: 8
                    property int gifNudgeRight: 8
                    property bool showBoth: true
                }
                property bool standaloneDock: false
                property list<string> dockOrder: []
            }
        }
    }

    QtObject {
        id: optionsFacade

        property alias panelFamily: globalAdapter.panelFamily
        property alias policies: globalAdapter.policies
        property alias ai: globalAdapter.ai
        property alias appearance: globalAdapter.appearance
        property alias audio: globalAdapter.audio
        property alias gameMode: globalAdapter.gameMode
        property alias apps: globalAdapter.apps
        property alias background: globalAdapter.background
        property alias battery: globalAdapter.battery
        property alias calendar: globalAdapter.calendar
        property alias cheatsheet: globalAdapter.cheatsheet
        property alias conflictKiller: globalAdapter.conflictKiller
        property alias crosshair: globalAdapter.crosshair
        property alias interactions: globalAdapter.interactions
        property alias language: globalAdapter.language
        property alias launcher: globalAdapter.launcher
        property alias light: globalAdapter.light
        property alias lock: globalAdapter.lock
        property alias media: globalAdapter.media
        property alias networking: globalAdapter.networking
        property alias notifications: globalAdapter.notifications
        property alias osd: globalAdapter.osd
        property alias osk: globalAdapter.osk
        property alias overview: globalAdapter.overview
        property alias regionSelector: globalAdapter.regionSelector
        property alias resources: globalAdapter.resources
        property alias tray: globalAdapter.tray
        property alias musicRecognition: globalAdapter.musicRecognition
        property alias search: globalAdapter.search
        property alias screenRecord: globalAdapter.screenRecord
        property alias screenSnip: globalAdapter.screenSnip
        property alias sounds: globalAdapter.sounds
        property alias time: globalAdapter.time
        property alias updates: globalAdapter.updates
        property alias wallpaperSelector: globalAdapter.wallpaperSelector
        property alias windows: globalAdapter.windows
        property alias hacks: globalAdapter.hacks
        property alias workSafety: globalAdapter.workSafety

        readonly property var bar: root.activeFamilyAdapter.bar
        readonly property var sidebar: root.activeFamilyAdapter.sidebar
        readonly property var dock: root.activeFamilyAdapter.dock
        readonly property var overlay: root.activeFamilyAdapter.overlay
        readonly property var screen: root.activeFamilyAdapter.screen

        readonly property string desktopFamily: PanelFamilies.desktopModule(globalAdapter.panelFamily)
        readonly property var family: root.activeFamilyAdapter[globalAdapter.panelFamily] ?? null

        readonly property var lunae: lunaeAdapter.lunae
        readonly property var waffles: waffleAdapter.waffles
        readonly property var akebono: akebonoAdapter.akebono
    }
}
