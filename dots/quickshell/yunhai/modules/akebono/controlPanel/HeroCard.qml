import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property bool switchVisible: true
    property bool switchChecked: false
    property alias glyph: glyphTile.data
    property alias actions: actionRow.data
    default property alias details: detailsColumn.data
    readonly property real padding: Appearance.font.pixelSize.normal * 1.6
    readonly property real glyphSize: Appearance.font.pixelSize.huge * 2.4

    signal switchToggled(bool checked)

    implicitHeight: Math.max(glyphTile.height, texts.implicitHeight, controls.implicitHeight) + root.padding * 2

    Squircle {
        anchors.fill: parent
        radius: 28
        smoothing: AkebonoAppearance.squircleSmoothing
        color: Appearance.colors.colLayer2
    }

    Squircle {
        id: glyphTile
        anchors.left: parent.left
        anchors.leftMargin: root.padding
        anchors.verticalCenter: parent.verticalCenter
        width: root.glyphSize * 1.6
        height: width
        radius: width * 0.32
        smoothing: AkebonoAppearance.squircleSmoothing
        color: Appearance.colors.colPrimaryContainer
    }

    ColumnLayout {
        id: texts
        anchors {
            left: glyphTile.right
            right: controls.left
            verticalCenter: parent.verticalCenter
            leftMargin: root.padding * 0.8
            rightMargin: root.padding * 0.6
        }
        spacing: 4

        StyledText {
            Layout.fillWidth: true
            text: root.title
            textFormat: Text.PlainText
            elide: Text.ElideRight
            font.pixelSize: Appearance.font.pixelSize.title
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer2
        }
        StyledText {
            Layout.fillWidth: true
            text: root.subtitle
            elide: Text.ElideRight
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
        }
        ColumnLayout {
            id: detailsColumn
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 6
        }
    }

    ColumnLayout {
        id: controls
        anchors {
            top: parent.top
            right: parent.right
            bottom: parent.bottom
            margins: root.padding
        }
        spacing: 8

        StyledSwitch {
            Layout.alignment: Qt.AlignRight
            visible: root.switchVisible
            checked: root.switchChecked
            onToggled: root.switchToggled(checked)
        }

        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            id: actionRow
            Layout.alignment: Qt.AlignRight
            spacing: 6
        }
    }
}
