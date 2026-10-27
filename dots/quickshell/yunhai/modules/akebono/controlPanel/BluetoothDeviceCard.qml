import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.akebono
import qs.modules.akebono.shelf.widgets.controlPanel

Squircle {
    id: root

    required property var device
    readonly property real tileSize: Appearance.font.pixelSize.huge * 2

    signal forgetRequested()

    implicitWidth: Appearance.font.pixelSize.normal * 19
    implicitHeight: content.implicitHeight + 28
    radius: 22
    smoothing: AkebonoAppearance.squircleSmoothing
    color: Appearance.colors.colLayer2

    ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Squircle {
                implicitWidth: root.tileSize
                implicitHeight: root.tileSize
                radius: root.tileSize * 0.32
                smoothing: AkebonoAppearance.squircleSmoothing
                color: Appearance.colors.colPrimaryContainer

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: Icons.getBluetoothDeviceMaterialSymbol(root.device.icon || "")
                    iconSize: Appearance.font.pixelSize.huge
                    fill: 1
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: root.device.name
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer2
                }
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Connected")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Pill {
                visible: root.device.batteryAvailable
                icon: BluetoothStatus.batterySymbol(root.device)
                text: `${Math.round(root.device.battery * 100)}%`
                sizingText: "100%"
            }
            Item {
                Layout.fillWidth: true
            }
            ActionButton {
                flat: true
                size: Appearance.font.pixelSize.huge * 1.5
                icon: "link_off"
                tooltip: Translation.tr("Disconnect")
                onClicked: root.device.disconnect()
            }
            ActionButton {
                flat: true
                size: Appearance.font.pixelSize.huge * 1.5
                icon: "delete"
                tooltip: Translation.tr("Forget this device")
                onClicked: root.forgetRequested()
            }
        }
    }
}
