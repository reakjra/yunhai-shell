import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.overlay

OverlayBackground {
    id: root

    property alias content: textInput.text
    property var copyListEntries: []
    property string lastParsedCopylistText: ""
    property var parsedCopylistLines: []
    property real maxCopyButtonSize: 20
    property bool previewMode: false
    property bool loadingContent: false
    property bool filePickerVisible: false
    property int filePickerMode: 0
    property bool showSavedNotification: false
    property bool tabEditModeEnabled: false

    property int currentTabIndex: Persistent.states.overlay.notes.tabIndex

    property var tabsData: ({
        tabs: root.defaultTabs
    })

    property list<var> defaultTabs: [
        { title: "Notes", icon: "article", content: "" }
    ]

    property var tabOptions: root.tabsData.tabs.map((tab, index) => ({
        displayName: tab.title,
        icon: tab.icon,
        value: index,
        middleClickAction: () => root.closeTab(index)
    }))

    FileView {
        id: exportFileView
    }

    FileView {
        id: importFileView
    }

    Timer {
        id: savedNotificationHideTimer
        interval: 2000
        onTriggered: root.showSavedNotification = false
    }

    Component.onCompleted: {
        noteFile.reload();
        updateCopyListEntries();
    }

    // --- Storage ---

    function saveToFile() {
        if (!textInput) return;
        if (currentTabIndex >= 0 && currentTabIndex < tabsData.tabs.length) {
            tabsData.tabs[currentTabIndex].content = root.content;
        }
        const jsonString = JSON.stringify(tabsData, null, 2);
        noteFile.setText(jsonString);
    }

    function loadTabContent(tabIndex) {
        if (tabIndex >= 0 && tabIndex < tabsData.tabs.length) {
            root.loadingContent = true;
            root.content = tabsData.tabs[tabIndex].content || "";
            root.loadingContent = false;
            Qt.callLater(root.updateCopyListEntries);
        }
    }

    function changeCurrentTab(index) {
        Persistent.states.overlay.notes.tabIndex = index;
    }

    // --- Tab management ---

    function switchToTab(index) {
        if (index < 0 || index >= tabsData.tabs.length) return;
        if (tabEditModeEnabled) return;
        saveToFile();
        root.content = "";
        changeCurrentTab(index);
        Qt.callLater(() => loadTabContent(index));
        root.filePickerVisible = false;
    }

    function addNewTab() {
        const newTabIndex = tabsData.tabs.length;
        const newTab = {
            title: "Tab " + (newTabIndex + 1),
            icon: "article",
            content: ""
        };
        let newTabs = tabsData.tabs.slice();
        newTabs.push(newTab);
        root.tabsData = { tabs: newTabs };
        saveToFile();
        changeCurrentTab(newTabIndex);
        Qt.callLater(() => {
            loadTabContent(newTabIndex);
            focusAtEnd();
        });
    }

    function closeTab(index) {
        if (tabsData.tabs.length <= 1) return;
        // Save current content before modifying
        if (currentTabIndex >= 0 && currentTabIndex < tabsData.tabs.length) {
            tabsData.tabs[currentTabIndex].content = root.content;
        }
        let newTabs = tabsData.tabs.slice();
        newTabs.splice(index, 1);
        const newIndex = Math.max(0, Math.min(
            index <= currentTabIndex ? currentTabIndex - 1 : currentTabIndex,
            newTabs.length - 1
        ));
        root.tabsData = { tabs: newTabs };
        Persistent.states.overlay.notes.tabIndex = newIndex;
        root.loadingContent = true;
        root.content = newTabs[newIndex].content || "";
        root.loadingContent = false;
        saveToFile();
        Qt.callLater(root.updateCopyListEntries);
    }

    function deleteCurrentTab() {
        closeTab(currentTabIndex);
    }

    // --- Focus helpers ---

    function restoreFocus() {
        if (root.previewMode) {
            Qt.callLater(() => previewContainer.forceActiveFocus());
        } else {
            Qt.callLater(() => textInput.forceActiveFocus());
        }
    }

    function focusAtEnd() {
        if (!textInput) return;
        textInput.forceActiveFocus();
        const endPos = root.content.length;
        applySelection(endPos, endPos);
    }

    function applySelection(cursorPos, anchorPos) {
        if (!textInput) return;
        const textLength = root.content.length;
        const cursor = Math.max(0, Math.min(cursorPos, textLength));
        const anchor = Math.max(0, Math.min(anchorPos, textLength));
        textInput.select(anchor, cursor);
        if (cursor === anchor) textInput.deselect();
    }

    // --- Import / Export ---

    function exportNote(filePath) {
        if (!filePath || filePath.trim() === "") return;
        const cleanPath = filePath.startsWith("file://") ? filePath : `file://${filePath}`;
        exportFileView.path = cleanPath;
        exportFileView.setText(root.content);
        root.filePickerVisible = false;
        root.showSavedNotification = true;
        savedNotificationHideTimer.start();
        restoreFocus();
    }

    function importNote(filePath) {
        if (!filePath) return;
        saveToFile();
        importFileView.path = filePath;

        const loadHandler = () => {
            const fileName = filePath.toString().split('/').pop().replace(/\.(txt|md|markdown)$/i, '');
            const importedContent = importFileView.text();
            const newTab = {
                title: fileName,
                icon: "article",
                content: importedContent
            };
            let newTabs = tabsData.tabs.slice();
            newTabs.push(newTab);
            root.tabsData = { tabs: newTabs };

            const newIndex = newTabs.length - 1;
            changeCurrentTab(newIndex);
            root.loadingContent = true;
            root.content = importedContent;
            root.loadingContent = false;
            saveToFile();
            restoreFocus();
            root.filePickerVisible = false;
            Qt.callLater(root.updateCopyListEntries);

            importFileView.onLoaded.disconnect(loadHandler);
        };

        importFileView.onLoaded.connect(loadHandler);
        importFileView.reload();
    }

    // --- Keybinds ---

    function handleKeyPress(event) {
        if (!(event.modifiers & Qt.ControlModifier)) return false;

        switch (event.key) {
            case Qt.Key_M:
                root.previewMode = !root.previewMode;
                if (!root.previewMode) textInput.forceActiveFocus();
                return true;
            case Qt.Key_S:
                root.filePickerMode = 1;
                root.filePickerVisible = !root.filePickerVisible;
                return true;
            case Qt.Key_I:
                root.filePickerMode = 0;
                root.filePickerVisible = !root.filePickerVisible;
                return true;
            case Qt.Key_Tab:
                if (tabsData.tabs.length > 1) {
                    const nextIndex = (currentTabIndex + 1) % tabsData.tabs.length;
                    switchToTab(nextIndex);
                }
                return true;
            case Qt.Key_Backtab:
                if (tabsData.tabs.length > 1) {
                    const prevIndex = currentTabIndex > 0 ? currentTabIndex - 1 : tabsData.tabs.length - 1;
                    switchToTab(prevIndex);
                }
                return true;
            case Qt.Key_T:
                Config.options.overlay.notes.showTabs = !Config.options.overlay.notes.showTabs;
                return true;
            case Qt.Key_N:
                addNewTab();
                return true;
            case Qt.Key_W:
                deleteCurrentTab();
                return true;
            default:
                return false;
        }
    }

    // --- Copyable bullet points ---

    function scheduleCopylistUpdate(immediate = false) {
        if (!textInput) return;
        if (immediate) {
            copyListDebounce?.stop();
            updateCopyListEntries();
        } else {
            copyListDebounce.restart();
        }
    }

    function updateCopyListEntries() {
        if (!textInput) return;
        const textValue = root.content;
        if (!textValue || textValue.length === 0) {
            lastParsedCopylistText = "";
            parsedCopylistLines = [];
            root.copyListEntries = [];
            return;
        }

        if (textValue !== lastParsedCopylistText) {
            const lineRegex = /(.*?)(\r?\n|$)/g;
            let match = null;
            const parsed = [];
            while ((match = lineRegex.exec(textValue)) !== null) {
                const lineText = match[1];
                const newlineText = match[2];
                const lineStart = match.index;
                const lineEnd = lineStart + lineText.length;
                const bulletMatch = lineText.match(/^\s*-\s+(.*\S)\s*$/);
                if (bulletMatch) {
                    parsed.push({
                        content: bulletMatch[1].trim(),
                        start: lineStart,
                        end: lineEnd
                    });
                }
                if (newlineText === "") break;
            }
            lastParsedCopylistText = textValue;
            parsedCopylistLines = parsed;
            if (parsed.length === 0) {
                root.copyListEntries = [];
                return;
            }
        }

        updateCopylistPositions();
    }

    function updateCopylistPositions() {
        if (!textInput || parsedCopylistLines.length === 0) return;
        const rawSelectionStart = textInput.selectionStart;
        const rawSelectionEnd = textInput.selectionEnd;
        const selectionStart = rawSelectionStart === -1 ? textInput.cursorPosition : rawSelectionStart;
        const selectionEnd = rawSelectionEnd === -1 ? textInput.cursorPosition : rawSelectionEnd;
        const rangeStart = Math.min(selectionStart, selectionEnd);
        const rangeEnd = Math.max(selectionStart, selectionEnd);

        const entries = parsedCopylistLines.map(line => {
            const caretIntersects = rangeEnd > line.start && rangeStart <= line.end;
            if (caretIntersects) return null;
            const startRect = textInput.positionToRectangle(line.start);
            let endRect = textInput.positionToRectangle(line.end);
            if (!isFinite(startRect.y)) return null;
            if (!isFinite(endRect.y)) endRect = startRect;
            const lineBottom = endRect.y + endRect.height;
            const rectHeight = Math.max(lineBottom - startRect.y, textInput.font.pixelSize + 8);
            return {
                content: line.content,
                y: startRect.y,
                height: rectHeight
            };
        }).filter(entry => entry !== null);

        root.copyListEntries = entries;
    }

    // --- Layout ---

    implicitWidth: 300
    implicitHeight: 200

    ColumnLayout {
        id: contentItem
        property int margin: Config.options.overlay.notes.showTabs ? 26 : 14
        anchors {
            fill: parent
            leftMargin: margin
            rightMargin: margin
            topMargin: margin
        }
        spacing: 14

        Loader {
            Layout.fillWidth: true
            Layout.preferredHeight: active ? implicitHeight : 0
            Layout.leftMargin: -contentItem.margin
            Layout.rightMargin: -contentItem.margin
            Layout.topMargin: -contentItem.margin
            active: Config.options.overlay.notes.showTabs
            sourceComponent: Rectangle {
                implicitHeight: tabColumn.implicitHeight + 16
                color: (Config?.options.appearance.transparency.enable ?? false)
                    ? Qt.rgba(
                        Appearance.m3colors.m3surfaceContainer.r,
                        Appearance.m3colors.m3surfaceContainer.g,
                        Appearance.m3colors.m3surfaceContainer.b,
                        Math.max(0.8, 1 - Config.options.appearance.transparency.backgroundTransparency)
                    )
                    : Appearance.colors.colSurfaceContainer
                radius: Appearance.rounding.normal

                ColumnLayout {
                    id: tabColumn
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true

                        ConfigSelectionArray {
                            currentValue: root.currentTabIndex
                            Layout.fillWidth: true

                            onSelected: newValue => {
                                root.switchToTab(newValue);
                            }

                            options: root.tabOptions
                        }

                        ConfigSelectionArray {
                            currentValue: root.tabEditModeEnabled ? 0 : -1
                            Layout.fillWidth: false
                            options: [
                                {
                                    displayName: "",
                                    icon: "edit",
                                    value: 0,
                                    releaseAction: (() => root.tabEditModeEnabled = !root.tabEditModeEnabled)
                                },
                                {
                                    displayName: "",
                                    icon: "add",
                                    value: 1,
                                    releaseAction: (() => root.addNewTab())
                                }
                            ]
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.tabEditModeEnabled || (editLoader.item && editLoader.item.height > 0)

                        Item {
                            Layout.fillWidth: true
                        }

                        Loader {
                            id: editLoader
                            active: root.tabEditModeEnabled || (item && item.height > 0)
                            sourceComponent: TitleEditComp {
                                Layout.fillWidth: false
                            }
                            onLoaded: item.height = 50
                        }
                    }
                }
            }
        }

        ScrollView {
            id: editorScrollView
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: -12
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
            onWidthChanged: root.scheduleCopylistUpdate(true)

            MouseArea {
                anchors.fill: parent
                z: -1
                onPressed: mouse => {
                    root.restoreFocus();
                    mouse.accepted = false;
                }
            }

            StyledTextArea {
                id: textInput
                width: editorScrollView.width
                visible: !root.previewMode
                wrapMode: TextEdit.Wrap
                placeholderText: Translation.tr("Write something here...\nUse '-' to create copyable bullet points, like this:\n\nSheep fricker\n- 4x Slab\n- 1x Boat\n- 4x Redstone Dust\n- 1x Sticky Piston\n- 1x End Rod\n- 4x Redstone Repeater\n- 1x Redstone Torch\n- 1x Sheep")
                selectByMouse: true
                persistentSelection: true
                textFormat: TextEdit.PlainText
                background: null
                padding: 12


                Keys.onPressed: event => {
                    event.accepted = root.handleKeyPress(event);
                }

                onTextChanged: {
                    if (textInput.activeFocus && !root.loadingContent) {
                        saveDebounce.restart();
                    }
                    root.scheduleCopylistUpdate(true);
                }

                onHeightChanged: root.scheduleCopylistUpdate(true)
                onContentHeightChanged: root.scheduleCopylistUpdate(true)
                onCursorPositionChanged: root.scheduleCopylistUpdate()
                onSelectionStartChanged: root.scheduleCopylistUpdate()
                onSelectionEndChanged: root.scheduleCopylistUpdate()
            }

            Item {
                id: previewContainer
                width: editorScrollView.width
                height: previewText.implicitHeight
                visible: root.previewMode
                focus: root.previewMode

                Keys.onPressed: event => {
                    event.accepted = root.handleKeyPress(event);
                }

                MouseArea {
                    anchors.fill: parent
                    onPressed: mouse => {
                        previewContainer.forceActiveFocus();
                        mouse.accepted = false;
                    }
                }

                StyledText {
                    id: previewText
                    width: parent.width
                    leftPadding: 12
                    rightPadding: 12
                    topPadding: 12
                    bottomPadding: 12
                    text: root.content
                    textFormat: Text.MarkdownText
                    wrapMode: Text.Wrap
                    onLinkActivated: link => Qt.openUrlExternally(link)
                }

                Component.onCompleted: {
                    if (root.previewMode) forceActiveFocus();
                }
            }

            Connections {
                target: root
                function onPreviewModeChanged() {
                    if (root.previewMode) {
                        previewContainer.forceActiveFocus();
                    } else {
                        textInput.forceActiveFocus();
                    }
                }
            }

            Item {
                width: editorScrollView.width
                height: textInput.height
                visible: !root.previewMode && root.copyListEntries.length > 0
                clip: true

                Repeater {
                    model: ScriptModel {
                        values: root.copyListEntries
                    }
                    delegate: RippleButton {
                        id: copyButton
                        required property var modelData
                        readonly property real lineHeight: Math.min(Math.max(modelData.height, Appearance.font.pixelSize.normal + 6), root.maxCopyButtonSize)
                        readonly property real iconSizeLocal: Appearance.font.pixelSize.normal
                        readonly property real hitPadding: 4
                        property bool justCopied: false

                        implicitHeight: lineHeight
                        implicitWidth: lineHeight
                        buttonRadius: height / 2
                        y: modelData.y
                        anchors.right: parent.right
                        anchors.rightMargin: -hitPadding
                        z: 5

                        Timer {
                            id: resetState
                            interval: 700
                            onTriggered: copyButton.justCopied = false
                        }

                        onClicked: {
                            Quickshell.clipboardText = copyButton.modelData.content;
                            justCopied = true;
                            resetState.start();
                        }

                        contentItem: Item {
                            anchors.centerIn: parent
                            MaterialSymbol {
                                id: iconItem
                                anchors.centerIn: parent
                                text: copyButton.justCopied ? "check" : "content_copy"
                                iconSize: copyButton.iconSizeLocal
                                color: Appearance.colors.colOnLayer1
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            id: statusBar
            Layout.fillWidth: true
            Layout.leftMargin: -contentItem.margin + 8
            Layout.rightMargin: -contentItem.margin + 8
            Layout.topMargin: 0
            Layout.bottomMargin: 4
            spacing: 8

            RippleButton {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                buttonRadius: Appearance.rounding.small
                colBackground: Qt.rgba(0, 0, 0, 0)
                colBackgroundHover: Appearance.colors.colLayer3Hover
                colRipple: Appearance.colors.colLayer3Active
                visible: !root.filePickerVisible

                contentItem: MaterialSymbol {
                    anchors.fill: parent
                    text: "help"
                    iconSize: 16
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    color: Appearance.colors.colSubtext
                }

                StyledToolTip {
                    text: Translation.tr("Keybinds:\nCtrl+M: Toggle Preview/Edit\nCtrl+S: Save Note As\nCtrl+I: Import Note\nCtrl+Tab: Next Tab\nCtrl+Shift+Tab: Previous Tab\nCtrl+N: New Tab\nCtrl+W: Close Tab\nCtrl+T: Hide Tabs")
                }
            }

            StyledText {
                id: modeIndicator
                Layout.alignment: Qt.AlignLeft
                text: root.previewMode ? Translation.tr("Preview") : Translation.tr("Edit")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small * 0.85
                visible: !root.filePickerVisible
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                id: statusLabel
                Layout.alignment: Qt.AlignRight
                Layout.minimumWidth: implicitWidth
                text: saveDebounce.running ? Translation.tr("Saving...") : Translation.tr("Saved")
                color: Appearance.colors.colSubtext
                font.pixelSize: Appearance.font.pixelSize.small * 0.85
                visible: !root.filePickerVisible
            }
        }
    }

    // --- Timers ---

    Timer {
        id: saveDebounce
        interval: 500
        repeat: false
        onTriggered: saveToFile()
    }

    Timer {
        id: copyListDebounce
        interval: 100
        repeat: false
        onTriggered: updateCopylistPositions()
    }

    // --- File I/O ---

    FileView {
        id: noteFile
        path: Qt.resolvedUrl(Directories.notesPath)
        onLoaded: {
            try {
                const jsonText = noteFile.text();
                const parsed = JSON.parse(jsonText);
                if (parsed && parsed.tabs && Array.isArray(parsed.tabs)) {
                    root.tabsData = parsed;
                } else {
                    root.tabsData = { tabs: root.defaultTabs };
                }
            } catch (e) {
                console.log("[Overlay Notes] JSON parse error: " + e);
                root.tabsData = { tabs: root.defaultTabs };
            }
            loadTabContent(root.currentTabIndex);
            Qt.callLater(root.updateCopyListEntries);
        }
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.tabsData = { tabs: root.defaultTabs };
                root.content = "";
                saveToFile();
                Qt.callLater(root.updateCopyListEntries);
            } else {
                console.log("[Overlay Notes] Error loading file: " + error);
            }
        }
    }

    // --- Export saved notification ---

    Rectangle {
        id: savedNotification
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.showSavedNotification ? 12 : -60
        width: savedNotifContent.width + 16
        height: 28
        radius: Appearance.rounding.full
        color: Appearance.m3colors.m3successContainer
        z: 2000
        opacity: root.showSavedNotification ? 1 : 0

        Behavior on anchors.topMargin {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(savedNotification)
        }

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(savedNotification)
        }

        RowLayout {
            id: savedNotifContent
            anchors.centerIn: parent
            spacing: 6

            MaterialSymbol {
                text: "check"
                iconSize: 16
                color: Appearance.m3colors.m3onSuccessContainer
            }

            StyledText {
                text: Translation.tr("Saved")
                color: Appearance.m3colors.m3onSuccessContainer
                font.pixelSize: Appearance.font.pixelSize.small
                font.weight: Font.Medium
            }
        }
    }

    // --- File picker overlay ---

    Item {
        anchors.fill: parent
        visible: opacity > 0
        opacity: root.filePickerVisible ? 1 : 0
        z: 1999
        clip: true

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.5
            radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.filePickerVisible = false;
                root.restoreFocus();
            }
        }
    }

    Item {
        anchors.centerIn: parent
        width: Math.min(parent.width - 32, 600)
        height: Math.min(parent.height - 32, 500)
        visible: opacity > 0
        opacity: root.filePickerVisible ? 1 : 0
        scale: root.filePickerVisible ? 1 : 0.95
        z: 2000

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        Behavior on scale {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        StyledRectangularShadow {
            target: filePicker
        }

        NotesFilePicker {
            id: filePicker
            anchors.fill: parent
            focus: root.filePickerVisible
            mode: root.filePickerMode

            onFileSelected: filePath => {
                if (root.filePickerMode === 0) {
                    root.importNote(filePath);
                } else {
                    root.exportNote(filePath);
                }
            }

            onCancelled: {
                root.filePickerVisible = false;
                root.restoreFocus();
            }

            Component.onCompleted: {
                if (root.filePickerVisible) {
                    Qt.callLater(() => forceActiveFocus());
                }
            }
        }

        Connections {
            target: root
            function onFilePickerVisibleChanged() {
                if (root.filePickerVisible) {
                    Qt.callLater(() => filePicker.forceActiveFocus());
                }
            }
        }
    }

    // --- Edit tab components ---

    component TitleEditComp: Row {
        id: row
        spacing: 4
        height: 0

        property bool editMode: root.tabEditModeEnabled
        onEditModeChanged: {
            if (!editMode) height = 0;
        }

        function updateTitle(disableEditMode = false) {
            let newTabs = root.tabsData.tabs.slice();
            newTabs[currentTabIndex] = {
                title: titleInput.text.split("\n")[0],
                icon: iconInput.text.split("\n")[0],
                content: newTabs[currentTabIndex].content
            };
            if (disableEditMode) root.tabEditModeEnabled = false;
            root.tabsData = { tabs: newTabs };
            saveToFile();
        }

        Behavior on height {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        EditInput {
            id: iconInput
            visible: Config.options.overlay.notes.allowEditingIcon
            placeholderText: Translation.tr("Icon")
            text: root.tabsData.tabs[currentTabIndex].icon
        }

        EditInput {
            id: titleInput
            placeholderText: Translation.tr("Title")
            text: root.tabsData.tabs[currentTabIndex].title
        }
    }

    component EditInput: MaterialTextArea {
        property int textAreaPadding: 6

        implicitWidth: 150
        implicitHeight: parent.height
        placeholderTextColor: height >= 40 ? Appearance.m3colors.m3outline : "transparent"

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                row.updateTitle(true);
            }
        }

        anchors.top: parent.top
        anchors.topMargin: -textAreaPadding
        topInset: textAreaPadding
    }
}
