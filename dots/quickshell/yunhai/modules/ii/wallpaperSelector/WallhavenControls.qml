import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Rectangle {
    id: root

    property real padding: 6
    property bool showSettings: false
    readonly property bool hasApiKey: (KeyringStorage.keyringData?.apiKeys?.wallhaven ?? "").length > 0

    implicitWidth: outerLayout.implicitWidth + padding * 2
    implicitHeight: outerLayout.implicitHeight + padding * 2
    color: Appearance.colors.colLayer2
    radius: Appearance.rounding.normal

    function triggerSearch() {
        Wallhaven.query = searchField.text
        Wallhaven.search()
    }

    component Separator: Rectangle {
        Layout.fillHeight: true
        Layout.topMargin: 8
        Layout.bottomMargin: 8
        implicitWidth: 1
        color: Appearance.colors.colLayer1
    }

    ColumnLayout {
        id: outerLayout
        anchors {
            fill: parent
            margins: root.padding
        }
        spacing: 4

        // Row 1: Search, categories, purity
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            ToolbarTextField {
                id: searchField
                Layout.fillWidth: true
                implicitWidth: 160
                placeholderText: Translation.tr("Search wallhaven...")
                Keys.onReturnPressed: root.triggerSearch()
                Keys.onEnterPressed: root.triggerSearch()
            }

            IconToolbarButton {
                implicitWidth: height
                text: "search"
                onClicked: root.triggerSearch()
                StyledToolTip { text: Translation.tr("Search") }
            }

            IconToolbarButton {
                implicitWidth: height
                text: "casino"
                onClicked: {
                    Wallhaven.query = searchField.text
                    Wallhaven.random()
                }
                StyledToolTip { text: Translation.tr("Random wallpapers") }
            }

            Separator {}

            // Category toggles
            IconToolbarButton {
                implicitWidth: height
                text: "landscape"
                toggled: Wallhaven.categories[0] === "1"
                onClicked: {
                    const c = Wallhaven.categories
                    Wallhaven.categories = (c[0] === "1" ? "0" : "1") + c[1] + c[2]
                }
                StyledToolTip { text: Translation.tr("General") }
            }
            IconToolbarButton {
                implicitWidth: height
                text: "animated_images"
                toggled: Wallhaven.categories[1] === "1"
                onClicked: {
                    const c = Wallhaven.categories
                    Wallhaven.categories = c[0] + (c[1] === "1" ? "0" : "1") + c[2]
                }
                StyledToolTip { text: Translation.tr("Anime") }
            }
            IconToolbarButton {
                implicitWidth: height
                text: "person"
                toggled: Wallhaven.categories[2] === "1"
                onClicked: {
                    const c = Wallhaven.categories
                    Wallhaven.categories = c[0] + c[1] + (c[2] === "1" ? "0" : "1")
                }
                StyledToolTip { text: Translation.tr("People") }
            }

            Separator {}

            // Purity toggles
            IconToolbarButton {
                implicitWidth: height
                text: "check_circle"
                toggled: Wallhaven.purity[0] === "1"
                onClicked: {
                    const p = Wallhaven.purity
                    Wallhaven.purity = (p[0] === "1" ? "0" : "1") + p[1] + p[2]
                }
                StyledToolTip { text: Translation.tr("SFW") }
            }
            IconToolbarButton {
                implicitWidth: height
                text: "warning"
                toggled: Wallhaven.purity[1] === "1"
                onClicked: {
                    const p = Wallhaven.purity
                    Wallhaven.purity = p[0] + (p[1] === "1" ? "0" : "1") + p[2]
                }
                StyledToolTip { text: Translation.tr("Sketchy") }
            }
            IconToolbarButton {
                visible: root.hasApiKey
                implicitWidth: height
                text: "18_up_rating"
                toggled: Wallhaven.purity[2] === "1"
                onClicked: {
                    const p = Wallhaven.purity
                    Wallhaven.purity = p[0] + p[1] + (p[2] === "1" ? "0" : "1")
                }
                StyledToolTip { text: Translation.tr("NSFW (requires API key)") }
            }
        }

        // Row 2: Sort, filters, pagination, settings
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            StyledComboBox {
                id: sortCombo
                Layout.fillWidth: false
                implicitWidth: 140
                model: [
                    Translation.tr("Date Added"),
                    Translation.tr("Relevance"),
                    Translation.tr("Random"),
                    Translation.tr("Views"),
                    Translation.tr("Favorites"),
                    Translation.tr("Top List"),
                ]
                readonly property var sortValues: [
                    "date_added", "relevance", "random", "views", "favorites", "toplist"
                ]
                currentIndex: sortValues.indexOf(Wallhaven.sorting)
                onActivated: index => {
                    Wallhaven.sorting = sortValues[index]
                }
            }

            StyledComboBox {
                id: ratioCombo
                Layout.fillWidth: false
                implicitWidth: 110
                model: [
                    Translation.tr("Any Ratio"),
                    "16x9", "16x10", "21x9", "32x9",
                    "4x3", "5x4", "3x2", "1x1",
                ]
                readonly property var ratioValues: [
                    "", "16x9", "16x10", "21x9", "32x9",
                    "4x3", "5x4", "3x2", "1x1",
                ]
                currentIndex: 0
                onActivated: index => {
                    Wallhaven.ratios = ratioValues[index]
                }
            }

            StyledComboBox {
                id: resCombo
                Layout.fillWidth: false
                implicitWidth: 120
                model: [
                    Translation.tr("Any Res"),
                    "1920x1080", "2560x1440", "3840x2160",
                    "2560x1080", "3440x1440", "5120x1440",
                ]
                readonly property var resValues: [
                    "", "1920x1080", "2560x1440", "3840x2160",
                    "2560x1080", "3440x1440", "5120x1440",
                ]
                currentIndex: 0
                onActivated: index => {
                    Wallhaven.atleast = resValues[index]
                }
            }

            Item { Layout.fillWidth: true }

            Separator {}

            // Page nav
            IconToolbarButton {
                implicitWidth: height
                text: "chevron_left"
                enabled: Wallhaven.page > 1
                onClicked: {
                    Wallhaven.page = Math.max(1, Wallhaven.page - 1)
                    Wallhaven.search(false, false)
                }
            }

            StyledText {
                text: `${Wallhaven.page}/${Wallhaven.lastPage}`
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colOnLayer2
                horizontalAlignment: Text.AlignHCenter
                Layout.minimumWidth: 40
            }

            IconToolbarButton {
                implicitWidth: height
                text: "chevron_right"
                enabled: Wallhaven.page < Wallhaven.lastPage
                onClicked: {
                    Wallhaven.page++
                    Wallhaven.search(false, false)
                }
            }

            Separator {}

            IconToolbarButton {
                implicitWidth: height
                text: "key"
                toggled: root.showSettings
                onClicked: root.showSettings = !root.showSettings
                StyledToolTip { text: Translation.tr("API key settings") }
            }
        }

        // Row 3 (optional): API key input, slides in/out
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.showSettings ? apiKeyRow.implicitHeight : 0
            clip: true
            opacity: root.showSettings ? 1 : 0

            Behavior on Layout.preferredHeight {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.animation.elementMoveFast.duration
                    easing.type: Appearance.animation.elementMoveFast.type
                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                }
            }

            RowLayout {
                id: apiKeyRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: 6

                MaterialSymbol {
                    text: "key"
                    iconSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer2
                }

                ToolbarTextField {
                    id: apiKeyField
                    property bool ready: false
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Wallhaven API key (for NSFW access)")
                    echoMode: TextInput.Password
                    onTextChanged: {
                        if (ready)
                            KeyringStorage.setNestedField(["apiKeys", "wallhaven"], text);
                    }
                    Connections {
                        target: KeyringStorage
                        function onLoadedChanged() {
                            if (KeyringStorage.loaded) {
                                apiKeyField.text = KeyringStorage.keyringData?.apiKeys?.wallhaven ?? "";
                                apiKeyField.ready = true;
                            }
                        }
                    }
                    Component.onCompleted: {
                        if (KeyringStorage.loaded) {
                            text = KeyringStorage.keyringData?.apiKeys?.wallhaven ?? "";
                            ready = true;
                        } else {
                            KeyringStorage.fetchKeyringData();
                        }
                    }
                }

                StyledText {
                    text: root.hasApiKey ? Translation.tr("Key set") : Translation.tr("No key")
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: root.hasApiKey ? Appearance.m3colors.m3success : Appearance.colors.colSubtext
                }
            }
        }
    }
}
