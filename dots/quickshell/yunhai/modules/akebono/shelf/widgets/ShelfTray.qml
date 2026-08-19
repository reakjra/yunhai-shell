pragma ComponentBehavior: Bound
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root
    property real barHeight: 54
    property var shelf

    readonly property var pinnedItems: TrayService.pinnedItems
    readonly property var unpinnedItems: TrayService.unpinnedItems
    readonly property int itemCount: pinnedItems.length + unpinnedItems.length
    readonly property bool shelfEmpty: itemCount === 0
    readonly property real iconSize: Math.round(barHeight * 0.4)

    visible: !shelfEmpty
    implicitWidth: shelfEmpty ? 0 : pill.implicitWidth
    implicitHeight: barHeight * 0.7
    Layout.alignment: Qt.AlignVCenter

    Squircle {
        id: pill
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: pillRow.implicitWidth + 18
        implicitHeight: root.barHeight * 0.7
        radius: height / 2
        color: AkebonoAppearance.shelfPillColor

        Component.onCompleted: root.shelf.registerTrayAnchor(pill)
        Component.onDestruction: root.shelf.unregisterTrayAnchor(pill)
        onXChanged: root.shelf.publishTray()

        RowLayout {
            id: pillRow
            anchors.centerIn: parent
            spacing: 10

            Repeater {
                model: ScriptModel {
                    objectProp: "id"
                    values: root.pinnedItems
                }
                delegate: ShelfTrayIcon {
                    required property SystemTrayItem modelData
                    item: modelData
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: root.iconSize
                    Layout.preferredHeight: root.iconSize
                    onMenuRequested: (trayItem, iconItem) => root.shelf.showTrayMenu(trayItem, iconItem)
                }
            }

            RippleButton {
                id: overflowButton
                visible: root.unpinnedItems.length > 0
                toggled: root.shelf.trayOverflowOpen
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: root.iconSize + 4
                implicitHeight: root.iconSize + 4
                background.implicitWidth: root.iconSize + 4
                background.implicitHeight: root.iconSize + 4
                background.anchors.centerIn: this
                colBackgroundToggled: Appearance.colors.colSecondaryContainer
                colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                colRippleToggled: Appearance.colors.colSecondaryContainerActive

                downAction: () => root.shelf.toggleTrayOverflow()

                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    iconSize: Appearance.font.pixelSize.larger
                    text: "expand_less"
                    horizontalAlignment: Text.AlignHCenter
                    color: root.shelf.trayOverflowOpen ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                    rotation: root.shelf.trayOverflowOpen ? 180 : 0
                    Behavior on rotation {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                }
            }
        }
    }
}
