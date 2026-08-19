import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono
import qs.modules.akebono.dock
import qs.modules.akebono.shelf.widgets
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

Item {
    id: module
    property var shelf
    required property var modelData

    readonly property bool present: modelData.visible !== false

    Layout.alignment: Qt.AlignVCenter
    visible: present && !(itemLoader.item?.shelfEmpty ?? false)
    implicitWidth: visible ? (itemLoader.item?.implicitWidth ?? 0) : 0
    implicitHeight: visible ? (itemLoader.item?.implicitHeight ?? 0) : 0

    readonly property var compMap: ({
        "launcher": launcherComp,
        "workspaces": workspacesComp,
        "dock": dockComp,
        "clock": clockComp,
        "sidebar": sidebarComp,
        "system_tray": trayComp,
        "status": statusComp,
        "media": mediaComp,
        "weather": weatherComp,
        "resources": resourcesComp,
        "record": recordComp,
        "screenshare": screenshareComp,
        "timer": timerComp,
        "equalizer": equalizerComp
    })

    Loader {
        id: itemLoader
        anchors.centerIn: parent
        active: module.present
        sourceComponent: module.compMap[module.modelData.id] ?? null
    }

    Component {
        id: launcherComp
        Squircle {
            id: launcherBtn
            implicitWidth: module.shelf.barHeight * 0.7
            implicitHeight: module.shelf.barHeight * 0.7
            radius: height / 2
            color: launcherMouse.containsMouse ? AkebonoAppearance.shelfPillHoverColor : AkebonoAppearance.shelfPillColor

            Component.onCompleted: module.shelf.registerLauncherAnchor(launcherBtn)
            Component.onDestruction: module.shelf.unregisterLauncherAnchor(launcherBtn)
            onXChanged: module.shelf.publishLauncher()

            MaterialSymbol {
                anchors.centerIn: parent
                text: "apps"
                iconSize: Math.round(module.shelf.barHeight * 0.4)
                color: Appearance.colors.colOnLayer1
            }
            MouseArea {
                id: launcherMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    module.shelf.publishLauncher();
                    GlobalStates.desktopRunnerOpen = !GlobalStates.desktopRunnerOpen;
                }
            }
        }
    }

    Component {
        id: sidebarComp
        ShelfSidebarButton {
            barHeight: module.shelf.barHeight
        }
    }

    Component {
        id: workspacesComp
        ShelfWorkspaces {
            barHeight: module.shelf.barHeight
        }
    }

    Component {
        id: dockComp
        DockApps {
            id: dockInner
            tileSize: module.shelf.barHeight * 0.82
            iconSize: module.shelf.barHeight * 0.63
            tileSpacing: 4
            minimizeFocused: Config.options.akebono?.shelf.minimizeOnClick ?? true

            Component.onCompleted: module.shelf.registerDock(dockInner)
            Component.onDestruction: module.shelf.unregisterDock(dockInner)

            onBumpRequested: (centerX, entry) => module.shelf.requestBump(dockInner, centerX, entry)
            onBumpCleared: module.shelf.scheduleClearBump()
            onScrollRequested: (delta, entry) => module.shelf.requestScroll(delta, entry)
            onMenuRequested: (centerX, entry) => module.shelf.requestMenu(dockInner, centerX, entry)
        }
    }

    Component {
        id: clockComp
        MouseArea {
            id: clockArea
            implicitWidth: clockCol.implicitWidth
            implicitHeight: clockCol.implicitHeight
            cursorShape: Qt.PointingHandCursor
            onClicked: module.shelf.toggleCalendar()

            Component.onCompleted: module.shelf.registerClockAnchor(clockArea)
            Component.onDestruction: module.shelf.unregisterClockAnchor(clockArea)

            Column {
                id: clockCol
                spacing: 0

                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: DateTime.time
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                }
                StyledText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: DateTime.shortDate
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                }
            }
        }
    }

    Component {
        id: trayComp
        ShelfTray {
            barHeight: module.shelf.barHeight
            shelf: module.shelf
        }
    }

    Component {
        id: mediaComp
        ShelfMedia {
            barHeight: module.shelf.barHeight
            shelf: module.shelf
        }
    }

    Component {
        id: weatherComp
        ShelfWeather {
            barHeight: module.shelf.barHeight
            shelf: module.shelf
        }
    }

    Component {
        id: resourcesComp
        ShelfResources {
            barHeight: module.shelf.barHeight
            shelf: module.shelf
        }
    }

    Component {
        id: statusComp
        ShelfStatus {
            barHeight: module.shelf.barHeight
            shelf: module.shelf
        }
    }

    Component {
        id: recordComp
        ShelfRecord {
            barHeight: module.shelf.barHeight
        }
    }

    Component {
        id: screenshareComp
        ShelfScreenShare {
            barHeight: module.shelf.barHeight
        }
    }

    Component {
        id: timerComp
        ShelfTimer {
            barHeight: module.shelf.barHeight
        }
    }

    Component {
        id: equalizerComp
        ShelfEqualizer {
            barHeight: module.shelf.barHeight
        }
    }
}
