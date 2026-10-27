import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono
import qs.modules.akebono.shelf.widgets.controlPanel

Item {
    id: root

    property string icon: ""
    property Component leading: null
    property string title: ""
    property string subtitle: ""
    property string trailingIcon: ""
    property string trailingText: ""
    property bool busy: false
    property bool selectable: false
    property bool selected: false
    property bool switchable: false
    property bool switchChecked: false
    property bool hoverActionAvailable: false
    property string hoverActionIcon: "delete"
    property string hoverActionTooltip: ""

    signal clicked()
    signal hoverActionClicked()

    implicitHeight: content.implicitHeight + Appearance.font.pixelSize.normal * 1.2

    HoverHandler {
        id: hover
    }

    RippleArea {
        anchors.fill: parent
        shapeRadius: 16
        squircle: true
        enabled: !root.busy
        onClicked: root.clicked()
    }

    RowLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: 12
            rightMargin: 8
        }
        spacing: 12

        Loader {
            active: root.leading !== null
            visible: active
            sourceComponent: root.leading
        }

        MaterialSymbol {
            visible: root.leading === null
            text: root.icon
            iconSize: Appearance.font.pixelSize.huge
            color: Appearance.colors.colOnLayer2
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            InkCenteredText {
                Layout.fillWidth: true
                text: root.title
                textFormat: Text.PlainText
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer2
            }
            InkCenteredText {
                Layout.fillWidth: true
                visible: root.subtitle !== ""
                text: root.subtitle
                textFormat: Text.PlainText
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
            }
        }

        MaterialLoadingIndicator {
            visible: root.busy
            implicitSize: Appearance.font.pixelSize.huge
        }

        ActionButton {
            visible: root.hoverActionAvailable && hover.hovered
            flat: true
            size: Appearance.font.pixelSize.huge * 1.5
            iconSize: Appearance.font.pixelSize.larger
            icon: root.hoverActionIcon
            tooltip: root.hoverActionTooltip
            onClicked: root.hoverActionClicked()
        }

        StyledRadioButton {
            visible: root.selectable
            checkable: false
            checked: root.selected
            onClicked: root.clicked()
        }

        StyledSwitch {
            visible: root.switchable
            checkable: false
            checked: root.switchChecked
            onClicked: root.clicked()
        }

        InkCenteredText {
            visible: root.trailingText !== ""
            text: root.trailingText
            font.family: Appearance.font.family.numbers
            font.variableAxes: Appearance.font.variableAxes.numbers
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colSubtext
        }

        MaterialSymbol {
            visible: root.trailingIcon !== "" && !root.busy
            text: root.trailingIcon
            iconSize: Appearance.font.pixelSize.larger
            color: Appearance.colors.colSubtext
        }
    }
}
