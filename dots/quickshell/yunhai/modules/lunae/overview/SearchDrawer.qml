pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models
import qs.modules.common.functions
import qs.modules.lunae

Item {
    id: root

    property bool open: false
    property real drawerWidth: 650
    property real armpitSize: Appearance.rounding.normal
    readonly property real cornerSize: Appearance.rounding.large
    readonly property bool contextMenuShowing: contextMenu.showing

    readonly property string searchingText: LauncherSearch.query
    readonly property bool showResults: searchingText !== ""
    readonly property color bgColor: Appearance.colors.colBackgroundSurfaceContainer
    readonly property real naturalHeight: contentColumn.height

    readonly property bool appSearchMode: {
        if (searchingText === "") return true;
        if (searchingText.startsWith(Config.options.search.prefix.app)) return true;
        const prefixes = [
            Config.options.search.prefix.action,
            Config.options.search.prefix.clipboard,
            Config.options.search.prefix.emojis,
            Config.options.search.prefix.kaomojis,
            Config.options.search.prefix.math,
            Config.options.search.prefix.shellCommand,
            Config.options.search.prefix.symbols,
            Config.options.search.prefix.webSearch,
        ];
        return !prefixes.some(p => p && searchingText.startsWith(p));
    }

    readonly property var pinnedDesktopEntries: {
        DesktopEntries.applications.values;
        return Config.options.launcher.pinnedApps.map(appId => DesktopEntries.byId(appId));
    }
    readonly property bool hasFavourites: pinnedDesktopEntries.some(e => e !== null)

    property bool suppressAnimations: false
    Timer {
        id: suppressAnimationsTimer
        interval: 100
        onTriggered: root.suppressAnimations = false
    }

    function focusInput() { searchInput.forceActiveFocus(); }
    onOpenChanged: if (!open) contextMenu.dismiss()
    function cancelSearch() {
        suppressAnimations = true;
        searchInput.text = "";
        LauncherSearch.query = "";
        LauncherSearch.activeCategory = "";
        contextMenu.dismiss();
        suppressAnimationsTimer.restart();
    }
    function setSearchingText(text) { searchInput.text = text; LauncherSearch.query = text; }

    enum SearchPrefixType { Action, App, Clipboard, Emojis, Kaomojis, Math, ShellCommand, Symbols, WebSearch, DefaultSearch }

    property int searchPrefixType: {
        const p = Config.options.search.prefix;
        if (p.action && searchingText.startsWith(p.action)) return SearchDrawer.SearchPrefixType.Action;
        if (p.app && searchingText.startsWith(p.app)) return SearchDrawer.SearchPrefixType.App;
        if (p.clipboard && searchingText.startsWith(p.clipboard)) return SearchDrawer.SearchPrefixType.Clipboard;
        if (p.emojis && searchingText.startsWith(p.emojis)) return SearchDrawer.SearchPrefixType.Emojis;
        if (p.kaomojis && searchingText.startsWith(p.kaomojis)) return SearchDrawer.SearchPrefixType.Kaomojis;
        if (p.math && searchingText.startsWith(p.math)) return SearchDrawer.SearchPrefixType.Math;
        if (p.shellCommand && searchingText.startsWith(p.shellCommand)) return SearchDrawer.SearchPrefixType.ShellCommand;
        if (p.symbols && searchingText.startsWith(p.symbols)) return SearchDrawer.SearchPrefixType.Symbols;
        if (p.webSearch && searchingText.startsWith(p.webSearch)) return SearchDrawer.SearchPrefixType.WebSearch;
        return SearchDrawer.SearchPrefixType.DefaultSearch;
    }

    property int currentShape: switch(searchPrefixType) {
        case SearchDrawer.SearchPrefixType.Action: return MaterialShape.Shape.Pill;
        case SearchDrawer.SearchPrefixType.App: return MaterialShape.Shape.Clover4Leaf;
        case SearchDrawer.SearchPrefixType.Clipboard: return MaterialShape.Shape.Gem;
        case SearchDrawer.SearchPrefixType.Emojis: return MaterialShape.Shape.Sunny;
        case SearchDrawer.SearchPrefixType.Kaomojis: return MaterialShape.Shape.Flower;
        case SearchDrawer.SearchPrefixType.Math: return MaterialShape.Shape.PuffyDiamond;
        case SearchDrawer.SearchPrefixType.ShellCommand: return MaterialShape.Shape.PixelCircle;
        case SearchDrawer.SearchPrefixType.Symbols: return MaterialShape.Shape.Pentagon;
        case SearchDrawer.SearchPrefixType.WebSearch: return MaterialShape.Shape.SoftBurst;
        default: return MaterialShape.Shape.Cookie7Sided;
    }

    Item {
        id: contentColumn
        anchors.bottom: parent.bottom
        x: root.armpitSize
        width: root.drawerWidth
        height: categorySection.height + favouritesSection.height + resultsWrapper.height + spacerItem.height + inputRow.height + 24

        Item {
            id: categorySection
            y: 12
            width: parent.width
            height: (Config.options?.lunae.runner.showFilters && root.appSearchMode && LauncherSearch.appCategories.length > 0) ? filterBar.implicitHeight + 8 : 0
            clip: true
            visible: height > 0

            Behavior on height {
                enabled: root.open && !root.suppressAnimations
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            CategoryFilterBar {
                id: filterBar
                width: parent.width - 26
                x: 13
            }
        }

        Item {
            id: favouritesSection
            y: categorySection.y + categorySection.height
            width: parent.width
            height: (!root.showResults && root.appSearchMode) ? favouritesContent.implicitHeight + 8 : 0
            clip: true
            visible: height > 0

            Behavior on height {
                enabled: root.open && !root.suppressAnimations
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            Column {
                id: favouritesContent
                width: parent.width
                spacing: 8

                Flow {
                    id: favouritesGrid
                    width: parent.width - 12
                    x: 6
                    spacing: 8
                    visible: root.hasFavourites

                    Repeater {
                        model: root.pinnedDesktopEntries

                        RippleButton {
                            id: favButton
                            required property var modelData
                            required property int index
                            visible: modelData !== null
                            implicitWidth: 72
                            implicitHeight: 62
                            buttonRadius: Appearance.rounding.small
                            colBackground: "transparent"
                            colBackgroundHover: Appearance.colors.colLayer2Hover

                            altAction: (event) => {
                                if (!favButton.modelData) return;
                                const mapped = favButton.mapToItem(contextMenu, event.x, event.y);
                                const fakeEntry = resultComp.createObject(contextMenu, {
                                    type: Translation.tr("App"),
                                    id: Config.options.launcher.pinnedApps[favButton.index] ?? "",
                                    name: favButton.modelData.name,
                                    iconName: favButton.modelData.icon,
                                    iconType: LauncherSearchResult.IconType.System,
                                });
                                contextMenu.show(fakeEntry, mapped.x, mapped.y);
                            }

                            onClicked: {
                                if (!favButton.modelData) return;
                                GlobalStates.overviewOpen = false;
                                favButton.modelData.execute();
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                IconImage {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    source: favButton.modelData ? Quickshell.iconPath(favButton.modelData.icon, "image-missing") : ""
                                    implicitSize: 32
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 64
                                    text: favButton.modelData?.name ?? ""
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.m3colors.m3onSurface
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: resultsWrapper
            y: favouritesSection.y + favouritesSection.height
            width: parent.width
            height: root.showResults ? (resultsList.count === 0 ? 120 : Math.min(400, resultsList.contentHeight + 20)) : 0
            clip: true

            Behavior on height {
                enabled: root.open && !root.suppressAnimations
                NumberAnimation { duration: Appearance.animation.elementMove.duration; easing.type: Easing.OutCubic }
            }

            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: root.showResults && resultsList.count === 0
                opacity: visible ? 1 : 0

                Behavior on opacity {
                    enabled: root.open && !root.suppressAnimations
                    NumberAnimation { duration: 200 }
                }

                MaterialSymbol {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "manage_search"
                    iconSize: 40
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Translation.tr("No results")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colSubtext
                }

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Translation.tr("Try searching for something else")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
            }

            ListView {
                id: resultsList
                width: parent.width
                implicitHeight: Math.min(400, contentHeight + topMargin + bottomMargin)
                topMargin: 8
                bottomMargin: 12
                leftMargin: 6
                rightMargin: 6
                spacing: 2
                highlightMoveDuration: 100

                highlight: null

                model: ScriptModel {
                    id: resultModel
                    objectProp: "key"
                }

                Timer {
                    id: debounceTimer
                    interval: 200
                    onTriggered: resultModel.values = LauncherSearch.results ?? []
                }

                Connections {
                    target: LauncherSearch
                    function onResultsChanged() {
                        resultModel.values = LauncherSearch.results.slice(0, 15);
                        resultsList.currentIndex = 0;
                        debounceTimer.restart();
                    }
                }

                delegate: SearchItem {
                    id: searchItem
                    required property var modelData
                    width: resultsList.width - resultsList.leftMargin - resultsList.rightMargin
                    entry: modelData
                    query: StringUtils.cleanOnePrefix(root.searchingText, [
                        Config.options.search.prefix.action,
                        Config.options.search.prefix.app,
                        Config.options.search.prefix.clipboard,
                        Config.options.search.prefix.emojis,
                        Config.options.search.prefix.kaomojis,
                        Config.options.search.prefix.math,
                        Config.options.search.prefix.shellCommand,
                        Config.options.search.prefix.webSearch
                    ])

                    onRightClicked: (entry, mouseX, mouseY) => {
                        const mapped = contextMenu.mapFromItem(null, mouseX, mouseY);
                        contextMenu.show(entry, mapped.x, mapped.y);
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Tab && LauncherSearch.results.length > 0) {
                            const tabbedText = searchItem.modelData.name;
                            LauncherSearch.query = tabbedText;
                            searchInput.text = tabbedText;
                            event.accepted = true;
                            searchInput.forceActiveFocus();
                        }
                    }
                }

                KeyNavigation.up: searchInput

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete ||
                        (event.text && event.text.length > 0 && event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter)) {
                        searchInput.forceActiveFocus();
                        if (event.key === Qt.Key_Backspace)
                            searchInput.text = searchInput.text.slice(0, -1);
                        else if (event.text)
                            searchInput.text += event.text;
                        event.accepted = true;
                    }
                }

                displaced: Transition {
                    NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutCubic }
                }
            }
        }

        Item {
            id: spacerItem
            y: resultsWrapper.y + resultsWrapper.height
            width: parent.width
            height: root.showResults ? 6 : 0
        }

        RowLayout {
            id: inputRow
            y: spacerItem.y + spacerItem.height
            width: parent.width
            height: 40
            spacing: 8

            Item { width: 6 }

            MaterialShapeWrappedMaterialSymbol {
                id: promptIcon
                Layout.alignment: Qt.AlignVCenter
                iconSize: Appearance.font.pixelSize.large
                shape: root.currentShape
                text: "chevron_right"
            }

            ToolbarTextField {
                id: searchInput
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                implicitHeight: 36
                rightPadding: clearButton.width + 8
                placeholderText: Translation.tr("Search...")
                font.pixelSize: Appearance.font.pixelSize.normal
                focus: root.open

                onTextChanged: LauncherSearch.query = text

                onAccepted: {
                    if (resultsList.count > 0) {
                        let firstItem = resultsList.itemAtIndex(0);
                        if (firstItem?.clicked) firstItem.clicked();
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Tab && LauncherSearch.results.length > 0) {
                        const tabbedText = LauncherSearch.results[0].name;
                        LauncherSearch.query = tabbedText;
                        searchInput.text = tabbedText;
                        event.accepted = true;
                    }
                    if (event.key === Qt.Key_Down && resultsList.count > 0) {
                        resultsList.forceActiveFocus();
                        resultsList.currentIndex = 0;
                        event.accepted = true;
                    }
                }

                MaterialSymbol {
                    id: clearButton
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: "close"
                    iconSize: Appearance.font.pixelSize.large
                    color: Appearance.colors.colSubtext
                    visible: opacity > 0
                    opacity: searchInput.text.length > 0 ? (clearMouse.containsMouse ? 0.7 : 1) : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 100
                        }
                    }

                    MouseArea {
                        id: clearMouse
                        anchors.fill: parent
                        anchors.margins: -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = "";
                            searchInput.forceActiveFocus();
                        }
                    }
                }
            }

            Item { width: 6 }
        }
    }

    AppContextMenu {
        id: contextMenu
        anchors.fill: parent
        boundsWidth: root.width
        boundsHeight: root.height
    }

    Component {
        id: resultComp
        LauncherSearchResult {}
    }
}
