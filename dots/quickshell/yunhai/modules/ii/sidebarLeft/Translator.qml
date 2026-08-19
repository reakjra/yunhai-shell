import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.sidebarLeft.translator
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Sizes
    property real padding: 4

    // Widgets
    property var inputField: inputCanvas.inputTextArea

    // Widget variables
    property bool translationFor: false
    property string translatedText: ""
    property list<string> languages: []

    // Options
    property string targetLanguage: Config.options.language.translator.targetLanguage
    property string sourceLanguage: Config.options.language.translator.sourceLanguage
    property string hostLanguage: targetLanguage

    // DeepL
    readonly property string deeplApiKey: KeyringStorage.keyringData?.apiKeys?.deepl ?? ""
    readonly property bool useDeepL: Config.options.sidebar.translator.useDeepL && deeplApiKey.length > 0
    readonly property bool deeplMissingKey: Config.options.sidebar.translator.useDeepL && deeplApiKey.length === 0

    Component.onCompleted: {
        if (Config.options.sidebar.translator.useDeepL && !KeyringStorage.loaded)
            KeyringStorage.fetchKeyringData();
        else
            reloadLanguages();
    }

    onUseDeepLChanged: {
        // Reset languages to auto since trans and DeepL use incompatible codes
        root.targetLanguage = "auto";
        root.sourceLanguage = "auto";
        Config.options.language.translator.targetLanguage = "auto";
        Config.options.language.translator.sourceLanguage = "auto";
        reloadLanguages();
    }
    function reloadLanguages() {
        root.languages = [];
        if (useDeepL)
            getDeeplLanguagesProc.running = true;
        else
            getLanguagesProc.running = true;
    }

    // States
    property bool showLanguageSelector: false
    property bool languageSelectorTarget: false

    function showLanguageSelectorDialog(isTargetLang: bool) {
        root.languageSelectorTarget = isTargetLang;
        root.showLanguageSelector = true
    }

    onFocusChanged: (focus) => {
        if (focus) {
            root.inputField.forceActiveFocus()
        }
    }

    Timer {
        id: translateTimer
        interval: Config.options.sidebar.translator.delay
        repeat: false
        onTriggered: () => {
            if (root.inputField.text.trim().length === 0) {
                root.translatedText = "";
                return;
            }
            if (root.useDeepL) {
                deeplTranslateProc.running = false;
                deeplTranslateProc.buffer = "";
                deeplTranslateProc.running = true;
            } else {
                translateProc.running = false;
                translateProc.buffer = "";
                translateProc.running = true;
            }
        }
    }

    Process {
        id: translateProc
        command: ["bash", "-c", `trans -brief -no-bidi`
            + ` -source '${StringUtils.shellSingleQuoteEscape(root.sourceLanguage)}'`
            + ` -target '${StringUtils.shellSingleQuoteEscape(root.targetLanguage)}'`
            + ` '${StringUtils.shellSingleQuoteEscape(root.inputField.text.trim())}'`]
        property string buffer: ""
        stdout: SplitParser {
            onRead: data => {
                translateProc.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            // With -brief mode, we get output with no metadata
            root.translatedText = translateProc.buffer.trim();
        }
    }

    Process {
        id: getLanguagesProc
        command: ["trans", "-list-languages", "-no-bidi"]
        property list<string> bufferList: ["auto"]
        stdout: SplitParser {
            onRead: data => {
                getLanguagesProc.bufferList.push(data.trim());
            }
        }
        onExited: (exitCode, exitStatus) => {
            let langs = getLanguagesProc.bufferList
                .filter(lang => lang.trim().length > 0 && lang !== "auto")
                .sort((a, b) => a.localeCompare(b));
            langs.unshift("auto");
            root.languages = langs;
            getLanguagesProc.bufferList = [];
        }
    }

    // DeepL Free API translation
    Process {
        id: deeplTranslateProc
        property string buffer: ""
        command: {
            const text = JSON.stringify(root.inputField.text.trim());
            const targetLang = root.targetLanguage === "auto" ? "EN" : root.targetLanguage.toUpperCase();
            let body = `{"text":[${text}],"target_lang":"${targetLang}"`;
            if (root.sourceLanguage !== "auto")
                body += `,"source_lang":"${root.sourceLanguage.toUpperCase()}"`;
            body += "}";
            return ["curl", "-s", "-X", "POST", "https://api-free.deepl.com/v2/translate",
                "-H", `Authorization: DeepL-Auth-Key ${root.deeplApiKey}`,
                "-H", "Content-Type: application/json",
                "-d", body];
        }
        stdout: SplitParser {
            onRead: data => {
                deeplTranslateProc.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            try {
                const resp = JSON.parse(deeplTranslateProc.buffer);
                root.translatedText = resp.translations.map(t => t.text).join("\n");
            } catch (e) {
                root.translatedText = deeplTranslateProc.buffer.trim();
            }
        }
    }

    // DeepL supported languages list
    Process {
        id: getDeeplLanguagesProc
        property string buffer: ""
        command: ["curl", "-s", "https://api-free.deepl.com/v2/languages",
            "-H", `Authorization: DeepL-Auth-Key ${root.deeplApiKey}`]
        stdout: SplitParser {
            onRead: data => {
                getDeeplLanguagesProc.buffer += data + "\n";
            }
        }
        onExited: (exitCode, exitStatus) => {
            try {
                const resp = JSON.parse(getDeeplLanguagesProc.buffer);
                let langs = resp.map(l => l.language).sort((a, b) => a.localeCompare(b));
                langs.unshift("auto");
                root.languages = langs;
            } catch (e) {
                root.languages = ["auto"];
            }
            getDeeplLanguagesProc.buffer = "";
        }
    }

    ColumnLayout {
        anchors {
            fill: parent
            margins: root.padding
        }

        StyledFlickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: contentColumn.implicitHeight

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent

                StyledText {
                    Layout.fillWidth: true
                    visible: root.deeplMissingKey
                    text: Translation.tr("DeepL enabled but no API key set. Add it in Settings > Interface.")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colError
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    topPadding: 4
                    bottomPadding: 4
                }

                LanguageSelectorButton { // Target language button
                    id: targetLanguageButton
                    displayText: root.targetLanguage
                    onClicked: {
                        root.showLanguageSelectorDialog(true);
                    }
                }

                TextCanvas { // Content translation
                    id: outputCanvas
                    isInput: false
                    placeholderText: Translation.tr("Translation goes here...")
                    property bool hasTranslation: (root.translatedText.trim().length > 0)
                    text: hasTranslation ? root.translatedText : ""
                    GroupButton {
                        id: copyButton
                        baseWidth: height
                        buttonRadius: Appearance.rounding.small
                        enabled: outputCanvas.displayedText.trim().length > 0
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            iconSize: Appearance.font.pixelSize.larger
                            text: "content_copy"
                            color: copyButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                        }
                        onClicked: {
                            Quickshell.clipboardText = outputCanvas.displayedText
                        }
                    }
                    GroupButton {
                        id: searchButton
                        baseWidth: height
                        buttonRadius: Appearance.rounding.small
                        enabled: outputCanvas.displayedText.trim().length > 0
                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            iconSize: Appearance.font.pixelSize.larger
                            text: "travel_explore"
                            color: searchButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                        }
                        onClicked: {
                            let url = Config.options.search.engineBaseUrl + outputCanvas.displayedText;
                            for (let site of Config.options.search.excludedSites) {
                                url += ` -site:${site}`;
                            }
                            Qt.openUrlExternally(url);
                        }
                    }
                }

            }    
        }

        LanguageSelectorButton { // Source language button
            id: sourceLanguageButton
            displayText: root.sourceLanguage
            onClicked: {
                root.showLanguageSelectorDialog(false);
            }
        }

        TextCanvas { // Content input
            id: inputCanvas
            isInput: true
            placeholderText: Translation.tr("Enter text to translate...")
            onInputTextChanged: {
                translateTimer.restart();
            }
            GroupButton {
                id: pasteButton
                baseWidth: height
                buttonRadius: Appearance.rounding.small
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    iconSize: Appearance.font.pixelSize.larger
                    text: "content_paste"
                    color: deleteButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                }
                onClicked: {
                    root.inputField.text = Quickshell.clipboardText
                }
            }
            GroupButton {
                id: deleteButton
                baseWidth: height
                buttonRadius: Appearance.rounding.small
                enabled: inputCanvas.displayedText.length > 0
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    iconSize: Appearance.font.pixelSize.larger
                    text: "close"
                    color: deleteButton.enabled ? Appearance.colors.colOnLayer1 : Appearance.colors.colSubtext
                }
                onClicked: {
                    root.inputField.text = ""
                }
            }
        }
    }

    Loader {
        anchors.fill: parent
        active: root.showLanguageSelector
        visible: root.showLanguageSelector
        z: 9999
        sourceComponent: SelectionDialog {
            id: languageSelectorDialog
            titleText: Translation.tr("Select Language")
            items: root.languages
            defaultChoice: root.languageSelectorTarget ? root.targetLanguage : root.sourceLanguage
            onCanceled: () => {
                root.showLanguageSelector = false;
            }
            onSelected: (result) => {
                root.showLanguageSelector = false;
                if (!result || result.length === 0) return; // No selection made

                if (root.languageSelectorTarget) {
                    root.targetLanguage = result;
                    Config.options.language.translator.targetLanguage = result; // Save to config
                } else {
                    root.sourceLanguage = result;
                    Config.options.language.translator.sourceLanguage = result; // Save to config
                }

                translateTimer.restart(); // Restart translation after language change
            }
        }
    }
}
