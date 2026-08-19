import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

MouseArea {
    id: root

    enum Mode { Open, Save }

    signal fileSelected(string filePath)
    signal cancelled()

    property string directory: FileUtils.trimFileProtocol(Directories.documents)
    property int currentIndex: 0
    property int mode: NotesFilePicker.Mode.Open

    acceptedButtons: Qt.NoButton

    onDirectoryChanged: currentIndex = 0

    function isSafePath(path) {
        return path.startsWith("/home");
    }

    function navigateUp() {
        const parent = FileUtils.parentDirectory(root.directory);
        if (parent.length > 0 && parent !== "/") {
            if (isSafePath(parent)) {
                root.directory = parent;
            } else {
                root.directory = "/home";
            }
        }
    }

    function navigateToDirectory(path) {
        const cleanPath = FileUtils.trimFileProtocol(path);
        if (cleanPath.length > 0 && cleanPath !== "/") {
            if (isSafePath(cleanPath)) {
                root.directory = cleanPath;
            } else {
                root.directory = "/home";
            }
        }
    }

    Keys.onPressed: event => {
        switch (event.key) {
            case Qt.Key_Escape:
                root.cancelled();
                event.accepted = true;
                break;

            case Qt.Key_Up:
                if (event.modifiers & Qt.AltModifier) {
                    root.navigateUp();
                } else {
                    fileList.moveSelection(-1);
                }
                event.accepted = true;
                break;

            case Qt.Key_Down:
                fileList.moveSelection(1);
                event.accepted = true;
                break;

            case Qt.Key_Left:
                root.navigateUp();
                event.accepted = true;
                break;

            case Qt.Key_Right:
                if (currentIndex >= 0 && currentIndex < folderModel.count) {
                    const isDir = folderModel.get(currentIndex, "fileIsDir");
                    if (isDir) {
                        root.navigateToDirectory(folderModel.get(currentIndex, "filePath"));
                    }
                }
                event.accepted = true;
                break;

            case Qt.Key_Return:
            case Qt.Key_Enter:
                fileList.activateCurrent();
                event.accepted = true;
                break;
        }
    }

    FolderListModel {
        id: folderModel
        folder: `file://${root.directory}`
        showDirs: true
        showFiles: true
        showDotAndDotDot: false
        sortField: FolderListModel.Name
    }

    function isTextFile(fileName) {
        return fileName.match(/\.(txt|md|markdown)$/i);
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.normal
        border.width: 1
        border.color: Appearance.colors.colLayer0Border

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 0

            AddressBar {
                id: addressBar
                Layout.fillWidth: true
                Layout.margins: 4
                directory: root.directory
                onNavigateToDirectory: path => root.navigateToDirectory(path)
                radius: Appearance.rounding.normal
            }

            ListView {
                id: fileList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: folderModel
                currentIndex: root.currentIndex
                ScrollBar.vertical: StyledScrollBar {}

                onCurrentIndexChanged: {
                    root.currentIndex = currentIndex;
                }

                function moveSelection(delta) {
                    currentIndex = Math.max(0, Math.min(model.count - 1, currentIndex + delta));
                    positionViewAtIndex(currentIndex, ListView.Contain);
                }

                function activateCurrent() {
                    if (currentIndex < 0 || currentIndex >= model.count) return;
                    const filePath = model.get(currentIndex, "filePath");
                    const isDir = model.get(currentIndex, "fileIsDir");
                    if (isDir) {
                        root.navigateToDirectory(filePath);
                    } else {
                        if (root.mode === NotesFilePicker.Mode.Open) {
                            root.fileSelected(filePath);
                        }
                    }
                }

                delegate: MouseArea {
                    id: fileItem
                    required property string fileName
                    required property bool fileIsDir
                    required property string filePath
                    required property int index

                    visible: fileIsDir || root.isTextFile(fileName)
                    width: fileList.width
                    height: visible ? 40 : 0
                    hoverEnabled: true

                    onClicked: {
                        fileList.currentIndex = index;
                        fileList.activateCurrent();
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: Appearance.rounding.small
                        color: fileItem.index === fileList.currentIndex ?
                            Appearance.colors.colPrimaryContainer :
                            (fileItem.containsMouse ? Appearance.colors.colLayer1 : Qt.rgba(0, 0, 0, 0))

                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            MaterialSymbol {
                                text: fileItem.fileIsDir ? "folder" : "description"
                                iconSize: 20
                                fill: fileItem.fileIsDir ? 0 : 1
                                color: fileItem.index === fileList.currentIndex ?
                                    Appearance.colors.colOnPrimaryContainer :
                                    Appearance.colors.colOnLayer0
                            }

                            StyledText {
                                Layout.fillWidth: true
                                text: fileItem.fileName
                                color: fileItem.index === fileList.currentIndex ?
                                    Appearance.colors.colOnPrimaryContainer :
                                    Appearance.colors.colOnLayer0
                                font.pixelSize: Appearance.font.pixelSize.normal
                                font.weight: fileItem.fileIsDir ? Font.Medium : Font.Normal
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            Rectangle {
                id: saveToolbar
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                Layout.margins: 4
                visible: root.mode === NotesFilePicker.Mode.Save
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.small
                border.width: 1
                border.color: Appearance.colors.colLayer0Border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    TextField {
                        id: fileNameField
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        placeholderText: Translation.tr("filename.txt")
                        placeholderTextColor: Appearance.colors.colSubtext
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.normal
                        font.family: Appearance.font.family.main
                        verticalAlignment: TextInput.AlignVCenter
                        renderType: Text.NativeRendering
                        selectedTextColor: Appearance.colors.colOnSecondaryContainer
                        selectionColor: Appearance.colors.colSecondaryContainer

                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.RightButton
                            onClicked: (mouse) => {
                                contextMenu.x = mouse.x;
                                contextMenu.y = mouse.y;
                                contextMenu.open();
                            }
                        }

                        TextFieldContextMenu {
                            id: contextMenu
                            textField: fileNameField
                        }

                        background: Rectangle {
                            color: "transparent"
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (text.trim().length > 0) {
                                    const fullPath = `${root.directory}/${text}`;
                                    root.fileSelected(fullPath);
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                root.cancelled();
                                event.accepted = true;
                            }
                        }
                    }

                    RippleButton {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        buttonRadius: Appearance.rounding.small
                        enabled: fileNameField.text.trim().length > 0
                        toggled: true
                        colBackgroundToggled: Appearance.colors.colPrimaryContainer
                        colBackgroundToggledHover: Appearance.colors.colPrimaryContainerHover

                        onClicked: {
                            if (fileNameField.text.trim().length > 0) {
                                const fullPath = `${root.directory}/${fileNameField.text}`;
                                root.fileSelected(fullPath);
                            }
                        }

                        contentItem: MaterialSymbol {
                            anchors.centerIn: parent
                            text: "save"
                            iconSize: 18
                            color: parent.parent.enabled ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colSubtext
                        }

                        StyledToolTip {
                            text: Translation.tr("Save file")
                        }
                    }
                }
            }

        }
    }

    Component.onCompleted: {
        forceActiveFocus();
        if (root.mode === NotesFilePicker.Mode.Save) {
            Qt.callLater(() => fileNameField.forceActiveFocus());
        }
    }
}
