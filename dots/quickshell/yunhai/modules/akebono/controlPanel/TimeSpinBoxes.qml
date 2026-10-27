import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets

RowLayout {
    id: root

    property alias firstValue: firstBox.value
    property alias firstTo: firstBox.to
    property alias secondValue: secondBox.value
    property alias secondTo: secondBox.to

    Layout.alignment: Qt.AlignHCenter
    spacing: 10

    component PaddedSpinBox: StyledSpinBox {
        from: 0
        textFromValue: value => String(value).padStart(2, "0")
    }

    PaddedSpinBox {
        id: firstBox
    }
    StyledText {
        text: ":"
        font.pixelSize: Appearance.font.pixelSize.huge
        color: Appearance.colors.colOnLayer2
    }
    PaddedSpinBox {
        id: secondBox
        to: 59
    }
}
