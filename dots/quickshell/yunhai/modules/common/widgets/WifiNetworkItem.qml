import qs.modules.common.widgets
import qs
import qs.modules.common
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell.Networking as QsNet

DialogListItem {
    id: root
    required property QsNet.WifiNetwork wifiNetwork
    property color labelColor: Appearance.colors.colOnSurfaceVariant
    readonly property bool askingPassword: Network.passwordTarget === root.wifiNetwork
    enabled: !root.wifiNetwork.stateChanging

    active: root.askingPassword || root.wifiNetwork.connected
    onClicked: {
        Network.connectToWifiNetwork(wifiNetwork);
    }

    contentItem: ColumnLayout {
        anchors {
            fill: parent
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }
        spacing: 0

        RowLayout {
            spacing: 10
            MaterialSymbol {
                iconSize: Appearance.font.pixelSize.larger
                text: Network.strengthSymbol(Network.strengthPercent(root.wifiNetwork))
                color: Appearance.colors.colOnSurfaceVariant
            }
            StyledText {
                Layout.fillWidth: true
                color: root.labelColor
                elide: Text.ElideRight
                text: root.wifiNetwork.name
                textFormat: Text.PlainText
            }
            MaterialSymbol {
                visible: Network.isSecure(root.wifiNetwork) || root.wifiNetwork.connected
                text: root.wifiNetwork.connected ? "check" : root.wifiNetwork.stateChanging ? "settings_ethernet" : "lock"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        ColumnLayout {
            id: passwordPrompt
            Layout.topMargin: 8
            visible: root.askingPassword

            MaterialTextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: Translation.tr("Password")

                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData

                onAccepted: {
                    Network.connectWithPassword(root.wifiNetwork, passwordField.text);
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                DialogButton {
                    buttonText: Translation.tr("Cancel")
                    onClicked: {
                        Network.cancelPassword();
                    }
                }

                DialogButton {
                    buttonText: Translation.tr("Connect")
                    onClicked: {
                        Network.connectWithPassword(root.wifiNetwork, passwordField.text);
                    }
                }
            }
        }

        ColumnLayout {
            id: publicWifiPortal
            Layout.topMargin: 8
            visible: root.wifiNetwork.connected && !Network.isSecure(root.wifiNetwork)

            RowLayout {
                DialogButton {
                    Layout.fillWidth: true
                    buttonText: Translation.tr("Open network portal")
                    colBackground: Appearance.colors.colLayer4
                    colBackgroundHover: Appearance.colors.colLayer4Hover
                    colRipple: Appearance.colors.colLayer4Active
                    onClicked: {
                        Network.openPublicWifiPortal()
                        GlobalStates.sidebarRightOpen = false
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
