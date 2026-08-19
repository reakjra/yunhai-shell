import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root
    property string title
    property string icon: ""
    default property alias data: sectionContent.data

    Layout.fillWidth: true
    spacing: 6

    RowLayout {
        spacing: 6
        Layout.leftMargin: SettingsStyle.grouped ? 6 : 0
        OptionalMaterialSymbol {
            icon: SettingsStyle.grouped ? "" : root.icon
            iconSize: Appearance.font.pixelSize.hugeass
        }
        StyledText {
            text: root.title
            font.pixelSize: SettingsStyle.grouped ? SettingsStyle.sectionHeaderSize : Appearance.font.pixelSize.larger
            font.weight: Font.Medium
            color: SettingsStyle.grouped ? SettingsStyle.sectionHeaderColor : Appearance.colors.colOnSecondaryContainer
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: sectionContent.implicitHeight + (SettingsStyle.grouped ? SettingsStyle.cardPaddingV * 2 : 0)
        radius: SettingsStyle.grouped ? SettingsStyle.cardRadius : 0
        color: SettingsStyle.grouped ? SettingsStyle.cardColor : "transparent"

        ColumnLayout {
            id: sectionContent
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: SettingsStyle.grouped ? SettingsStyle.cardPaddingH : 0
                rightMargin: SettingsStyle.grouped ? SettingsStyle.cardPaddingH : 0
                topMargin: SettingsStyle.grouped ? SettingsStyle.cardPaddingV : 0
            }
            spacing: 4
        }
    }
}
