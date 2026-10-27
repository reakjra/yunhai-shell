import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking as QsNet
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs.modules.waffle.actionCenter

ExpandableChoiceButton {
    id: root
    required property QsNet.WifiNetwork wifiNetwork

    contentItem: RowLayout {
        id: contentItem
        spacing: 12

        FluentIcon { // Duotone hack
            Layout.bottomMargin: 2
            Layout.alignment: Qt.AlignTop
            icon: "wifi-1"
            implicitSize: 30
            color: Looks.colors.inactiveIcon

            FluentIcon { // Signal
                icon: WIcons.wifiIconForStrength(Network.strengthPercent(root.wifiNetwork))
                implicitSize: 30

                FluentIcon { // Security
                    anchors {
                        right: parent.right
                        bottom: parent.bottom
                    }
                    visible: Network.isSecure(root.wifiNetwork)
                    icon: "lock-closed"
                    filled: true
                    implicitSize: 14           
                }
            }
        }

        ColumnLayout {
            Layout.topMargin: statusText.visible ? 4 : 7
            Layout.bottomMargin: 4
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            spacing: 1

            Behavior on Layout.topMargin {
                animation: Looks.transition.move.createObject(this)
            }

            WText { // Network name
                Layout.fillWidth: true
                elide: Text.ElideRight
                font.pixelSize: Looks.font.pixelSize.large
                text: root.wifiNetwork.name
                textFormat: Text.PlainText
            }
            WText { // Status
                id: statusText
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.wifiNetwork.connected ? Translation.tr("Connected") : Network.isSecure(root.wifiNetwork) ? Translation.tr("Secured") : Translation.tr("Not secured")
                font.pixelSize: Looks.font.pixelSize.large
                color: Looks.colors.subfg
                visible: root.wifiNetwork.connected || root.expanded
                Behavior on opacity {
                    animation: Looks.transition.opacity.createObject(this)
                }
            }

            WButton {
                Layout.alignment: Qt.AlignRight
                horizontalAlignment: Text.AlignHCenter
                visible: root.expanded
                checked: !root.wifiNetwork.connected
                colBackground: Looks.colors.bg2
                colBackgroundHover: Looks.colors.bg2Hover
                colBackgroundActive: Looks.colors.bg2Active
                implicitHeight: 30
                implicitWidth: 148
                text: root.wifiNetwork.connected ? Translation.tr("Disconnect") : Translation.tr("Connect")

                onClicked: {
                    if (root.wifiNetwork.connected) {
                        Network.disconnectWifiNetwork();
                    } else {
                        Network.connectToWifiNetwork(root.wifiNetwork);
                    }
                }
            }
        }
    }
}
