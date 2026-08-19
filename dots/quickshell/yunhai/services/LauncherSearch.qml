pragma Singleton

import qs.modules.common
import qs.modules.common.models
import qs.modules.common.functions
import qs.services
import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property string query: ""
    property string activeCategory: ""

    function ensurePrefix(prefix) {
        if ([Config.options.search.prefix.action, Config.options.search.prefix.app, Config.options.search.prefix.clipboard, Config.options.search.prefix.emojis, Config.options.search.prefix.symbols, Config.options.search.prefix.math, Config.options.search.prefix.shellCommand, Config.options.search.prefix.webSearch,].some(i => root.query.startsWith(i))) {
            root.query = prefix + root.query.slice(1);
        } else {
            root.query = prefix + root.query;
        }
    }

    // https://specifications.freedesktop.org/menu/latest/category-registry.html
    property list<string> mainRegisteredCategories: ["AudioVideo", "Development", "Education", "Game", "Graphics", "Network", "Office", "Science", "Settings", "System", "Utility"]
    property list<string> appCategories: DesktopEntries.applications.values.reduce((acc, entry) => {
        for (const category of entry.categories) {
            if (!acc.includes(category) && mainRegisteredCategories.includes(category)) {
                acc.push(category);
            }
        }
        return acc;
    }, []).sort()

    readonly property var categoryIcons: ({
        "AudioVideo": "headphones",
        "Development": "code",
        "Education": "school",
        "Game": "sports_esports",
        "Graphics": "palette",
        "Network": "language",
        "Office": "description",
        "Science": "science",
        "Settings": "settings",
        "System": "computer",
        "Utility": "build"
    })
    readonly property var categoryLabels: ({
        "AudioVideo": Translation.tr("Media"),
        "Development": Translation.tr("Development"),
        "Education": Translation.tr("Education"),
        "Game": Translation.tr("Games"),
        "Graphics": Translation.tr("Graphics"),
        "Network": Translation.tr("Internet"),
        "Office": Translation.tr("Office"),
        "Science": Translation.tr("Science"),
        "Settings": Translation.tr("Settings"),
        "System": Translation.tr("System"),
        "Utility": Translation.tr("Utilities")
    })

    readonly property string pinnedSection: "fav"
    readonly property string allSection: "all"

    readonly property var sections: [
        {
            key: root.pinnedSection,
            label: Translation.tr("Favourites"),
            icon: "star"
        },
        {
            key: root.allSection,
            label: Translation.tr("All apps"),
            icon: "apps"
        }
    ].concat(root.appCategories.map(category => ({
        key: category,
        label: root.categoryLabels[category] ?? category,
        icon: root.categoryIcons[category] ?? "category"
    })))

    readonly property var pinnedEntries: {
        DesktopEntries.applications.values;
        return (Config.options?.launcher.pinnedApps ?? [])
            .map(id => DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id))
            .filter(entry => entry);
    }

    readonly property var visibleEntries: {
        const hiddenApps = Config.options?.search.hiddenApps ?? [];
        return DesktopEntries.applications.values
            .filter(entry => !hiddenApps.includes(entry.id))
            .slice()
            .sort((a, b) => a.name.localeCompare(b.name));
    }

    function categoryForSection(key: string): string {
        return (key === root.pinnedSection || key === root.allSection) ? "" : key;
    }

    function entriesForSection(key: string): var {
        if (key === root.pinnedSection)
            return root.pinnedEntries;
        if (key === root.allSection)
            return root.visibleEntries;
        return root.visibleEntries.filter(entry => entry.categories.includes(key));
    }

    readonly property var glyphSources: [
        {
            prefix: Config.options.search.prefix.emojis,
            list: false,
            lookup: term => Emojis.fuzzyQuery(term),
            split: raw => ({
                glyph: raw.match(/^\s*(\S+)/)?.[1] ?? "",
                label: raw.replace(/^\s*\S+\s+/, "")
            })
        },
        {
            prefix: Config.options.search.prefix.symbols,
            list: false,
            lookup: term => Symbols.fuzzyQuery(term),
            split: raw => ({
                glyph: raw.match(/^\s*(\S+)/)?.[1] ?? "",
                label: raw.replace(/^\s*\S+\s+/, "")
            })
        },
        {
            prefix: Config.options.search.prefix.kaomojis,
            list: true,
            lookup: term => Kaomojis.fuzzyQuery(term),
            split: raw => {
                const parts = raw.split("\t");
                return {
                    glyph: parts[0].trim(),
                    label: parts[1]?.trim() ?? ""
                };
            }
        }
    ]

    function glyphSourceFor(query: string): var {
        return root.glyphSources.find(source => source.prefix && query.startsWith(source.prefix)) ?? null;
    }

    function isGlyphQuery(query: string): bool {
        return root.glyphSourceFor(query) !== null;
    }

    function glyphListMode(query: string, source: var): bool {
        const from = source ?? root.glyphSourceFor(query);
        return from ? from.list : false;
    }

    function glyphEntries(query: string, source: var): var {
        const from = source ?? root.glyphSourceFor(query);
        if (!from)
            return [];
        const term = StringUtils.cleanPrefix(query, from.prefix);
        return from.lookup(term).map((raw, position) => {
            const entry = from.split(raw);
            entry.idx = position;
            return entry;
        }).filter(entry => entry.glyph);
    }

    property var userActionScripts: {
        const actions = [];
        for (let i = 0; i < userActionsFolder.count; i++) {
            const fileName = userActionsFolder.get(i, "fileName");
            const filePath = userActionsFolder.get(i, "filePath");
            if (fileName && filePath) {
                const actionName = fileName.replace(/\.[^/.]+$/, "");
                actions.push({
                    action: actionName,
                    execute: ((path) => (args) => {
                        Quickshell.execDetached([path, ...(args ? args.split(" ") : [])]);
                    })(FileUtils.trimFileProtocol(filePath.toString()))
                });
            }
        }
        return actions;
    }

    FolderListModel {
        id: userActionsFolder
        folder: Qt.resolvedUrl(Directories.userActions)
        showDirs: false
        showHidden: false
        sortField: FolderListModel.Name
    }

    property var searchActions: [
        {
            action: "accentcolor",
            icon: "palette",
            execute: args => {
                Quickshell.execDetached([Directories.wallpaperSwitchScriptPath, "--noswitch", "--color", ...(args != '' ? [`${args}`] : [])]);
            }
        },
        {
            action: "dark",
            icon: "dark_mode",
            execute: () => {
                MaterialThemeLoader.switchDarkLightMode(true);
            }
        },
        {
            action: "konachanwallpaper",
            icon: "image",
            execute: () => {
                Quickshell.execDetached([Quickshell.shellPath("scripts/colors/random/random_konachan_wall.sh")]);
            }
        },
        {
            action: "light",
            icon: "light_mode",
            execute: () => {
                MaterialThemeLoader.switchDarkLightMode(false);
            }
        },
        {
            action: "superpaste",
            icon: "content_paste",
            execute: args => {
                if (!/^(\d+)/.test(args.trim())) {
                    Quickshell.execDetached(["notify-send", Translation.tr("Superpaste"), Translation.tr("Usage: <tt>%1superpaste NUM_OF_ENTRIES[i]</tt>\nSupply <tt>i</tt> when you want images\nExamples:\n<tt>%1superpaste 4i</tt> for the last 4 images\n<tt>%1superpaste 7</tt> for the last 7 entries").arg(Config.options.search.prefix.action), "-a", "Shell"]);
                    return;
                }
                const syntaxMatch = /^(?:(\d+)(i)?)/.exec(args.trim());
                const count = syntaxMatch[1] ? parseInt(syntaxMatch[1]) : 1;
                const isImage = !!syntaxMatch[2];
                Cliphist.superpaste(count, isImage);
            }
        },
        {
            action: "todo",
            icon: "add_task",
            execute: args => {
                Todo.addTask(args);
            }
        },
        {
            action: "songrec",
            icon: "music_note",
            execute: () => {
                SongRec.toggleRunning();
            }
        },
        {
            action: "wallpaper",
            icon: "wallpaper",
            execute: () => {
                Hyprland.dispatch(`hl.dsp.global("quickshell:wallpaperSelectorToggle")`)
            }
        },
        {
            action: "wipeclipboard",
            icon: "delete_sweep",
            execute: () => {
                Cliphist.wipe();
            }
        },
    ]

    property var allActions: searchActions.concat(userActionScripts)

    property string mathResult: ""
    property bool clipboardWorkSafetyActive: {
        const enabled = Config.options.workSafety.enable.clipboard;
        const sensitiveNetwork = (StringUtils.stringListContainsSubstring(Network.networkName.toLowerCase(), Config.options.workSafety.triggerCondition.networkNameKeywords));
        return enabled && sensitiveNetwork;
    }

    function containsUnsafeLink(entry) {
        if (entry == undefined)
            return false;
        const unsafeKeywords = Config.options.workSafety.triggerCondition.linkKeywords;
        return StringUtils.stringListContainsSubstring(entry.toLowerCase(), unsafeKeywords);
    }

    Timer {
        id: nonAppResultsTimer
        interval: Config.options.search.nonAppResultDelay
        onTriggered: {
            let expr = root.query;
            if (Config.options.search.prefix.math && expr.startsWith(Config.options.search.prefix.math)) {
                expr = expr.slice(Config.options.search.prefix.math.length);
            }
            mathProc.calculateExpression(expr);
        }
    }

    Process {
        id: mathProc
        property list<string> baseCommand: ["qalc", "-t"]
        function calculateExpression(expression) {
            mathProc.running = false;
            mathProc.command = baseCommand.concat(expression);
            mathProc.running = true;
        }
        stdout: SplitParser {
            onRead: data => {
                root.mathResult = data;
            }
        }
    }

    property list<var> results: {
        if (root.query == "")
            return [];

        if (Config.options.search.prefix.clipboard && root.query.startsWith(Config.options.search.prefix.clipboard)) {
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.clipboard);
            return Cliphist.fuzzyQuery(searchString).slice(0, 100).map((entry, index, array) => {
                const mightBlurImage = Cliphist.entryIsImage(entry) && root.clipboardWorkSafetyActive;
                let shouldBlurImage = mightBlurImage;
                if (mightBlurImage) {
                    shouldBlurImage = shouldBlurImage && (root.containsUnsafeLink(array[index - 1]) || root.containsUnsafeLink(array[index + 1]));
                }
                const type = `#${entry.match(/^\s*(\S+)/)?.[1] || ""}`;
                return resultComp.createObject(null, {
                    key: type,
                    rawValue: entry,
                    name: StringUtils.cleanCliphistEntry(entry),
                    verb: "",
                    type: type,
                    execute: () => {
                        Cliphist.copy(entry);
                    },
                    actions: [resultComp.createObject(null, {
                            name: Translation.tr("Copy"),
                            iconName: "content_copy",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                Cliphist.copy(entry);
                            }
                        }), resultComp.createObject(null, {
                            name: Translation.tr("Delete"),
                            iconName: "delete",
                            iconType: LauncherSearchResult.IconType.Material,
                            execute: () => {
                                Cliphist.deleteEntry(entry);
                            }
                        })],
                    blurImage: shouldBlurImage
                });
            }).filter(Boolean);
        } else if (Config.options.search.prefix.emojis && root.query.startsWith(Config.options.search.prefix.emojis)) {
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.emojis);
            return Emojis.fuzzyQuery(searchString).slice(0, 100).map(entry => {
                const emoji = entry.match(/^\s*(\S+)/)?.[1] || "";
                return resultComp.createObject(null, {
                    key: emoji,
                    rawValue: entry,
                    name: entry.replace(/^\s*\S+\s+/, ""),
                    iconName: emoji,
                    iconType: LauncherSearchResult.IconType.Text,
                    verb: Translation.tr("Copy"),
                    type: Translation.tr("Emoji"),
                    execute: () => {
                        Quickshell.clipboardText = entry.match(/^\s*(\S+)/)?.[1];
                    }
                });
            }).filter(Boolean);
        } else if (Config.options.search.prefix.kaomojis && root.query.startsWith(Config.options.search.prefix.kaomojis)) {
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.kaomojis);
            return Kaomojis.fuzzyQuery(searchString).slice(0, 100).map(entry => {
                const parts = entry.split("\t");
                const kaomoji = parts[0].trim();
                const description = parts[1]?.trim() || "";
                return resultComp.createObject(null, {
                    key: kaomoji,
                    rawValue: entry,
                    name: description || kaomoji,
                    iconName: kaomoji,
                    iconType: LauncherSearchResult.IconType.Text,
                    verb: Translation.tr("Copy"),
                    type: Translation.tr("Kaomoji"),
                    execute: () => {
                        Quickshell.clipboardText = kaomoji;
                    }
                });
            }).filter(Boolean);
        } else if (Config.options.search.prefix.symbols && root.query.startsWith(Config.options.search.prefix.symbols)) {
            const searchString = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.symbols);
            return Symbols.fuzzyQuery(searchString).slice(0, 100).map(entry => {
                const symbol = entry.match(/^\s*(\S+)/)?.[1] || "";
                return resultComp.createObject(null, {
                    key: symbol,
                    rawValue: entry,
                    name: entry.replace(/^\s*\S+\s+/, ""),
                    iconName: symbol,
                    iconType: LauncherSearchResult.IconType.Text,
                    verb: Translation.tr("Copy"),
                    type: Translation.tr("Symbol"),
                    execute: () => {
                        Quickshell.clipboardText = entry.match(/^\s*(\S+)/)?.[1];
                    }
                });
            }).filter(Boolean);
        }

        nonAppResultsTimer.restart();
        const mathResultObject = resultComp.createObject(null, {
            key: "math",
            name: root.mathResult,
            verb: Translation.tr("Copy"),
            type: Translation.tr("Math result"),
            fontType: LauncherSearchResult.FontType.Monospace,
            iconName: 'calculate',
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                Quickshell.clipboardText = root.mathResult;
            }
        });
        const hiddenApps = Config.options?.search.hiddenApps ?? [];
        const appResultObjects = AppSearch.fuzzyQuery(StringUtils.cleanPrefix(root.query, Config.options.search.prefix.app))
            .filter(entry => !hiddenApps.includes(entry.id))
            .filter(entry => !root.activeCategory || entry.categories.includes(root.activeCategory))
            .map(entry => {
            return resultComp.createObject(null, {
                key: entry.id,
                type: Translation.tr("App"),
                id: entry.id,
                name: entry.name,
                iconName: entry.icon,
                iconType: LauncherSearchResult.IconType.System,
                verb: Translation.tr("Open"),
                execute: () => {
                    if (!entry.runInTerminal)
                        entry.execute();
                    else {
                        Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(entry.command.join(' '))}'`]);
                    }
                },
                comment: entry.comment,
                runInTerminal: entry.runInTerminal,
                genericName: entry.genericName,
                keywords: entry.keywords,
                actions: entry.actions.map(action => {
                    return resultComp.createObject(null, {
                        name: action.name,
                        iconName: action.icon,
                        iconType: LauncherSearchResult.IconType.System,
                        execute: () => {
                            if (!action.runInTerminal)
                                action.execute();
                            else {
                                Quickshell.execDetached(["bash", '-c', `${Config.options.apps.terminal} -e '${StringUtils.shellSingleQuoteEscape(action.command.join(' '))}'`]);
                            }
                        }
                    });
                })
            });
        });
        const pinnedApps = Config.options?.launcher.pinnedApps ?? [];
        appResultObjects.sort((a, b) => {
            const aPinned = pinnedApps.includes(a.id);
            const bPinned = pinnedApps.includes(b.id);
            if (aPinned && !bPinned) return -1;
            if (!aPinned && bPinned) return 1;
            return 0;
        });
        const commandResultObject = resultComp.createObject(null, {
            key: "command",
            name: StringUtils.cleanPrefix(root.query, Config.options.search.prefix.shellCommand).replace("file://", ""),
            verb: Translation.tr("Run"),
            type: Translation.tr("Command"),
            fontType: LauncherSearchResult.FontType.Monospace,
            iconName: 'terminal',
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                let cleanedCommand = root.query.replace("file://", "");
                cleanedCommand = StringUtils.cleanPrefix(cleanedCommand, Config.options.search.prefix.shellCommand);
                if (cleanedCommand.startsWith(Config.options.search.prefix.shellCommand)) {
                    cleanedCommand = cleanedCommand.slice(Config.options.search.prefix.shellCommand.length);
                }
                Quickshell.execDetached(["bash", "-c", root.query.startsWith('sudo') ? `${Config.options.apps.terminal} fish -C '${cleanedCommand}'` : cleanedCommand]);
            }
        });
        const webSearchResultObject = resultComp.createObject(null, {
            key: "websearch",
            name: StringUtils.cleanPrefix(root.query, Config.options.search.prefix.webSearch),
            verb: Translation.tr("Search"),
            type: Translation.tr("Web search"),
            iconName: 'travel_explore',
            iconType: LauncherSearchResult.IconType.Material,
            execute: () => {
                let query = StringUtils.cleanPrefix(root.query, Config.options.search.prefix.webSearch);
                let url = Config.options.search.engineBaseUrl + query;
                for (let site of Config.options.search.excludedSites) {
                    url += ` -site:${site}`;
                }
                Qt.openUrlExternally(url);
            }
        });
        const launcherActionObjects = root.allActions.map(action => {
            const actionString = `${Config.options.search.prefix.action}${action.action}`;
            if (actionString.startsWith(root.query) || root.query.startsWith(actionString)) {
                return resultComp.createObject(null, {
                    key: `action:${action.action}`,
                    name: root.query.startsWith(actionString) ? root.query : actionString,
                    verb: Translation.tr("Run"),
                    type: Translation.tr("Action"),
                    iconName: action.icon ?? 'settings_suggest',
                    iconType: LauncherSearchResult.IconType.Material,
                    execute: () => {
                        action.execute(root.query.split(" ").slice(1).join(" "));
                    }
                });
            }
            return null;
        }).filter(Boolean);

        let result = [];
        const startsWithNumber = /^\d/.test(root.query);
        const startsWithMathPrefix = root.query.startsWith(Config.options.search.prefix.math);
        const startsWithShellCommandPrefix = root.query.startsWith(Config.options.search.prefix.shellCommand);
        const startsWithWebSearchPrefix = root.query.startsWith(Config.options.search.prefix.webSearch);
        if (startsWithNumber || startsWithMathPrefix) {
            result.push(mathResultObject);
        } else if (startsWithShellCommandPrefix) {
            result.push(commandResultObject);
        } else if (startsWithWebSearchPrefix) {
            result.push(webSearchResultObject);
        }

        result = result.concat(appResultObjects);
        result = result.concat(launcherActionObjects);

        if (Config.options.search.prefix.showDefaultActionsWithoutPrefix) {
            if (!startsWithShellCommandPrefix)
                result.push(commandResultObject);
            if (!startsWithNumber && !startsWithMathPrefix)
                result.push(mathResultObject);
            if (!startsWithWebSearchPrefix)
                result.push(webSearchResultObject);
        }

        return result;
    }

    Component {
        id: resultComp
        LauncherSearchResult {}
    }
}
