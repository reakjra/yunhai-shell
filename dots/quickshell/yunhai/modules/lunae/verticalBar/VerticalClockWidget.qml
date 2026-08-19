import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    implicitHeight: clockColumn.implicitHeight + 10
    implicitWidth: Appearance.sizes.verticalBarWidth

    ColumnLayout {
        id: clockColumn
        anchors.centerIn: parent
        spacing: 0

        Repeater {
            model: DateTime.time.split(/[: ]/)
            delegate: StyledText {
                required property string modelData
                Layout.alignment: Qt.AlignHCenter
                font.pixelSize: modelData.match(/am|pm/i) ?
                    Appearance.font.pixelSize.smaller
                    : Appearance.font.pixelSize.large
                color: Config.options.lunae.colorful ? Appearance.colors.colTertiary : Appearance.colors.colOnLayer1
                text: modelData.padStart(2, "0")
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: !Config.options.bar.tooltips.clickToShow

        onClicked: {
            if (hoverEnabled) return
            if (GlobalStates.activeBarPopup === "clock")
                GlobalStates.activeBarPopup = ""
            else {
                const pos = root.mapToItem(null, 0, root.height / 2)
                GlobalStates.barPopupY = pos.y
                GlobalStates.activeBarPopup = "clock"
            }
        }

        onContainsMouseChanged: {
            if (!hoverEnabled) return
            if (containsMouse) {
                const pos = root.mapToItem(null, 0, root.height / 2)
                GlobalStates.barPopupY = pos.y
                GlobalStates.activeBarPopup = "clock"
            } else {
                GlobalStates.activeBarPopup = ""
            }
        }
    }
}
