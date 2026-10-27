import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

Item {
    id: root

    property bool forgetDialogOpen: false
    property var forgetTarget: null

    function requestForget(device) {
        root.forgetTarget = device;
        root.forgetDialogOpen = true;
    }

    Component.onCompleted: BluetoothStatus.setDiscoveryWanted(root, true)
    Component.onDestruction: BluetoothStatus.setDiscoveryWanted(root, false)

    StyledFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.implicitHeight
        clip: true

        ColumnLayout {
            id: column
            width: flickable.width
            spacing: 16

            BluetoothHero {
                Layout.fillWidth: true
            }

            FadeLoader {
                Layout.fillWidth: true
                shown: BluetoothStatus.enabled && BluetoothStatus.connectedDevices.length > 0

                sourceComponent: ColumnLayout {
                    spacing: 16

                    SectionHeader {
                        title: Translation.tr("Connected")
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 10

                        Repeater {
                            model: ScriptModel {
                                values: BluetoothStatus.connectedDevices
                            }
                            delegate: BluetoothDeviceCard {
                                required property var modelData
                                device: modelData
                                onForgetRequested: root.requestForget(modelData)
                            }
                        }
                    }
                }
            }

            FadeLoader {
                Layout.fillWidth: true
                shown: BluetoothStatus.enabled

                sourceComponent: ColumnLayout {
                    spacing: 16

                    SectionHeader {
                        title: Translation.tr("Paired devices")
                    }

                    ListCard {
                        values: BluetoothStatus.pairedButNotConnectedDevices
                        emptyText: Translation.tr("No other paired devices")
                        delegate: ListRow {
                            required property var modelData
                            Layout.fillWidth: true
                            icon: Icons.getBluetoothDeviceMaterialSymbol(modelData.icon || "")
                            title: modelData.name
                            subtitle: Translation.tr("Paired")
                            busy: BluetoothStatus.isBusy(modelData)
                            hoverActionAvailable: true
                            hoverActionTooltip: Translation.tr("Forget this device")
                            onClicked: modelData.connect()
                            onHoverActionClicked: root.requestForget(modelData)
                        }
                    }

                    SectionHeader {
                        title: Translation.tr("Nearby devices")
                        busy: BluetoothStatus.discovering
                    }

                    ListCard {
                        Layout.bottomMargin: 8
                        values: BluetoothStatus.unpairedDevices
                        emptyText: Translation.tr("Looking for devices...")
                        delegate: ListRow {
                            required property var modelData
                            Layout.fillWidth: true
                            icon: Icons.getBluetoothDeviceMaterialSymbol(modelData.icon || "")
                            title: modelData.name
                            subtitle: modelData.pairing ? Translation.tr("Pairing...") : ""
                            busy: BluetoothStatus.isBusy(modelData)
                            onClicked: BluetoothStatus.pairAndConnect(modelData)
                        }
                    }
                }
            }
        }
    }

    Item {
        parent: root.Window.window?.contentItem ?? root
        anchors.fill: parent
        z: 1

        WindowDialogLoader {
            shown: root.forgetDialogOpen
            onDismissed: root.forgetDialogOpen = false
            dialog: ConfirmDialog {
                title: Translation.tr("Forget %1?").arg(root.forgetTarget?.name ?? "")
                body: Translation.tr("You'll have to pair it again to use it.")
                confirmText: Translation.tr("Forget")
                onConfirmed: root.forgetTarget.forget()
            }
        }
    }
}
