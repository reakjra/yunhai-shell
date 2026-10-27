import QtQuick

StyledText {
    id: root

    readonly property real inkHeight: (capMetrics.tightBoundingRect.height + fontMetrics.xHeight) / 2
    readonly property real inkShift: Math.round((fontMetrics.ascent - fontMetrics.descent - root.inkHeight) / 2)

    topPadding: -root.inkShift
    bottomPadding: root.inkShift

    FontMetrics {
        id: fontMetrics
        font: root.font
    }

    TextMetrics {
        id: capMetrics
        font: root.font
        text: "H"
    }
}
