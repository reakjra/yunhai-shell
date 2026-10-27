pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.services
import qs.modules.common
import qs.modules.common.widgets

SidebarNavChrome {
    id: root

    property string initialSection: ""

    onPageLoaded: item => {
        if (root.initialSection === "" || !item.scrollToSection)
            return;
        item.scrollToSection(root.initialSection);
        root.initialSection = "";
    }

    header: RowLayout {
        spacing: 10

        Rectangle {
            id: avatarContainer
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            radius: Appearance.rounding.small
            color: Appearance.colors.colLayer2

            MaterialSymbol {
                anchors.centerIn: parent
                text: "person"
                iconSize: 22
                color: Appearance.m3colors.m3onSurfaceVariant
                visible: avatarImg.status !== Image.Ready
            }
            Item {
                anchors.fill: parent
                layer.enabled: avatarImg.status === Image.Ready
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: avatarContainer.width
                        height: avatarContainer.height
                        radius: avatarContainer.radius
                    }
                }
                Image {
                    id: avatarImg
                    anchors.fill: parent
                    sourceSize: Qt.size(44, 44)
                    source: (Directories.userAvatarPathAccountsService && !Directories.userAvatarPathAccountsService.endsWith("/user")) ? Directories.userAvatarPathAccountsService : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            StyledText {
                Layout.fillWidth: true
                text: SystemInfo.username
                font.pixelSize: Appearance.font.pixelSize.normal
                font.variableAxes: { "wght": 600 }
                color: Appearance.colors.colOnLayer1
                elide: Text.ElideRight
            }
            StyledText {
                Layout.fillWidth: true
                text: SystemInfo.distroName ?? "Linux"
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
            }
        }
    }
}
