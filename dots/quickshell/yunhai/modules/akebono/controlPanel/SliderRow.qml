import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

ColumnLayout {
    id: root

    property string icon: ""
    property string title: ""
    property string valueText: ""
    property alias from: slider.from
    property alias to: slider.to
    property alias value: slider.value
    property alias stopIndicatorValues: slider.stopIndicatorValues

    signal moved(real value)

    Layout.fillWidth: true
    Layout.leftMargin: 12
    Layout.rightMargin: 8
    spacing: 2

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        MaterialSymbol {
            text: root.icon
            iconSize: Appearance.font.pixelSize.huge
            color: Appearance.colors.colOnLayer2
        }
        InkCenteredText {
            Layout.fillWidth: true
            text: root.title
            textFormat: Text.PlainText
            elide: Text.ElideRight
            font.pixelSize: Appearance.font.pixelSize.normal
            color: Appearance.colors.colOnLayer2
        }
        InkCenteredText {
            text: root.valueText
            font.pixelSize: Appearance.font.pixelSize.small
            color: Appearance.colors.colSubtext
        }
    }

    StyledSlider {
        id: slider
        Layout.fillWidth: true
        configuration: StyledSlider.Configuration.S
        tooltipContent: root.valueText
        onMoved: root.moved(value)
    }
}
