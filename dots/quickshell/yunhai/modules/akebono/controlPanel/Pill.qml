import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono

Squircle {
    id: root

    property string icon: ""
    property string text: ""
    property string sizingText: ""
    property string tooltip: ""
    property bool clickable: false
    readonly property color foreground: root.clickable ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnSecondaryContainer

    signal clicked()

    implicitWidth: row.implicitWidth + Appearance.font.pixelSize.normal * 1.4
    implicitHeight: row.implicitHeight + Appearance.font.pixelSize.normal * 0.8
    radius: height / 2
    smoothing: AkebonoAppearance.squircleSmoothing
    color: root.clickable ? Appearance.colors.colPrimaryContainer : Appearance.colors.colSecondaryContainer

    TextMetrics {
        id: sizing
        font: label.font
        text: root.sizingText
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6

        MaterialSymbol {
            visible: root.icon !== ""
            text: root.icon
            iconSize: Appearance.font.pixelSize.normal
            color: root.foreground
        }
        InkCenteredText {
            id: label
            Layout.minimumWidth: sizing.advanceWidth
            horizontalAlignment: Text.AlignHCenter
            text: root.text
            font.pixelSize: Appearance.font.pixelSize.small
            color: root.foreground
        }
    }

    RippleArea {
        id: area
        visible: root.clickable
        shapeRadius: root.radius
        squircle: true
        rippleColor: root.foreground
        onClicked: root.clicked()
    }
    MouseAreaToolTip {
        area: area
        text: root.tooltip
    }
}
