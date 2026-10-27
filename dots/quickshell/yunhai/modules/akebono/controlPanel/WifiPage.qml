import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    readonly property var nearbyNetworks: Network.friendlyWifiNetworks.filter(network => !network.connected)
    property bool hiddenDialogOpen: false
    property bool dnsDialogOpen: false
    property bool forgetDialogOpen: false
    property var forgetTarget: null

    function requestForget(network) {
        root.forgetTarget = network;
        root.forgetDialogOpen = true;
    }

    Component.onCompleted: Network.setScanWanted(root, true)
    Component.onDestruction: Network.setScanWanted(root, false)

    StyledFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: column.implicitHeight
        clip: true

        ColumnLayout {
            id: column
            width: flickable.width
            spacing: 16

            WifiHero {
                Layout.fillWidth: true
                onForgetRequested: network => root.requestForget(network)
                onDnsRequested: root.dnsDialogOpen = true
            }

            FadeLoader {
                Layout.fillWidth: true
                shown: Network.wifiEnabled

                sourceComponent: ColumnLayout {
                    spacing: 16

                    SectionHeader {
                        title: Translation.tr("Networks nearby")
                        busy: Network.wifiScanPending

                        Pill {
                            clickable: true
                            icon: "add"
                            text: Translation.tr("Hidden network")
                            onClicked: root.hiddenDialogOpen = true
                        }
                    }

                    ListCard {
                        Layout.bottomMargin: 8
                        values: root.nearbyNetworks
                        emptyText: Translation.tr("Looking for networks...")
                        delegate: ListRow {
                            required property var modelData
                            Layout.fillWidth: true
                            icon: Network.strengthSymbol(Network.strengthPercent(modelData))
                            title: modelData.name
                            subtitle: [modelData.known ? Translation.tr("Saved") : "", Network.isSecure(modelData) ? Network.securityLabel(modelData) : Translation.tr("Open")].filter(part => part !== "").join(" · ")
                            trailingIcon: Network.isSecure(modelData) ? "lock" : ""
                            busy: modelData.stateChanging
                            hoverActionAvailable: modelData.known
                            hoverActionTooltip: Translation.tr("Forget this network")
                            onClicked: Network.connectToWifiNetwork(modelData)
                            onHoverActionClicked: root.requestForget(modelData)
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
            shown: Network.passwordTarget !== null || root.hiddenDialogOpen
            onDismissed: {
                Network.cancelPassword();
                root.hiddenDialogOpen = false;
            }
            dialog: WifiConnectDialog {
                hiddenRequested: root.hiddenDialogOpen
            }
        }

        WindowDialogLoader {
            shown: root.dnsDialogOpen
            onDismissed: root.dnsDialogOpen = false
            dialog: WifiDnsDialog {}
        }

        WindowDialogLoader {
            shown: root.forgetDialogOpen
            onDismissed: root.forgetDialogOpen = false
            dialog: ConfirmDialog {
                title: Translation.tr("Forget %1?").arg(root.forgetTarget?.name ?? "")
                body: Translation.tr("You'll need the password to connect to it again.")
                confirmText: Translation.tr("Forget")
                onConfirmed: Network.forgetWifiNetwork(root.forgetTarget)
            }
        }
    }
}
