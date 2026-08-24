import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property real dialogPadding: 15
    property real dialogMargin: 30
    property string titleText: "Selection Dialog"
    property var items: []
    property var labelFor: item => String(item)
    property bool searchable: false
    property string searchPlaceholder: Translation.tr("Search")
    property var defaultChoice
    property var selectedValue: defaultChoice

    readonly property var filteredItems: {
        const query = searchField.text.trim().toLowerCase();
        if (query.length === 0)
            return root.items;
        return root.items.filter(item => root.labelFor(item).toLowerCase().includes(query));
    }

    signal canceled();
    signal selected(var result);

    function accept() {
        root.selected(root.selectedValue ?? null);
    }

    function moveSelection(offset: int) {
        const items = root.filteredItems;
        if (items.length === 0)
            return;
        const index = items.indexOf(root.selectedValue) + offset;
        root.selectedValue = items[Math.max(0, Math.min(items.length - 1, index))];
    }

    Rectangle { // Scrim
        id: scrimOverlay
        anchors.fill: parent
        radius: Appearance.rounding.small
        color: Appearance.colors.colScrim
        MouseArea {
            hoverEnabled: true
            anchors.fill: parent
            preventStealing: true
            propagateComposedEvents: false
        }
    }

    Rectangle { // The dialog
        id: dialog
        color: Appearance.m3colors.m3surfaceContainerHigh
        radius: Appearance.rounding.normal
        anchors.fill: parent
        anchors.margins: dialogMargin
        implicitHeight: dialogColumnLayout.implicitHeight

        ColumnLayout {
            id: dialogColumnLayout
            anchors.fill: parent
            spacing: 16

            StyledText {
                id: dialogTitle
                Layout.topMargin: dialogPadding
                Layout.leftMargin: dialogPadding
                Layout.rightMargin: dialogPadding
                Layout.alignment: Qt.AlignLeft
                color: Appearance.m3colors.m3onSurface
                font.pixelSize: Appearance.font.pixelSize.larger
                text: root.titleText
            }

            MaterialTextField {
                id: searchField
                visible: root.searchable
                Layout.fillWidth: true
                Layout.leftMargin: root.dialogPadding
                Layout.rightMargin: root.dialogPadding
                placeholderText: root.searchPlaceholder
                Keys.onDownPressed: root.moveSelection(1)
                Keys.onUpPressed: root.moveSelection(-1)
                onAccepted: root.accept()
                Component.onCompleted: if (root.searchable) forceActiveFocus()
            }

            Rectangle {
                color: Appearance.m3colors.m3outline
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.leftMargin: dialogPadding
                Layout.rightMargin: dialogPadding
            }

            StyledListView {
                id: choiceListView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                animateAppearance: false
                currentIndex: root.filteredItems.indexOf(root.selectedValue)

                model: root.filteredItems

                onCurrentIndexChanged: if (currentIndex >= 0) positionViewAtIndex(currentIndex, ListView.Contain)

                delegate: StyledRadioButton {
                    id: radioButton
                    required property var modelData
                    checkable: false
                    width: choiceListView.width
                    leftPadding: root.dialogPadding
                    rightPadding: root.dialogPadding

                    description: root.labelFor(modelData)
                    checked: modelData === root.selectedValue

                    onClicked: root.selectedValue = modelData
                }
            }

            Rectangle {
                color: Appearance.m3colors.m3outline
                implicitHeight: 1
                Layout.fillWidth: true
                Layout.leftMargin: dialogPadding
                Layout.rightMargin: dialogPadding
            }

            RowLayout {
                id: dialogButtonsRowLayout
                Layout.bottomMargin: dialogPadding
                Layout.leftMargin: dialogPadding
                Layout.rightMargin: dialogPadding
                Layout.alignment: Qt.AlignRight

                DialogButton {
                    buttonText: Translation.tr("Cancel")
                    onClicked: root.canceled()
                }
                DialogButton {
                    buttonText: Translation.tr("OK")
                    onClicked: root.accept()
                }
            }
        }
    }
}
