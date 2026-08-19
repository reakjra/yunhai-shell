import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

Item {
    id: wrappedFrame

    property int frameThickness: Config.options.screen.wrappedFrameThickness
    property bool barVertical: Config.options.bar.vertical
    property bool barBottom: Config.options.bar.bottom

    component HorizontalFrame: PanelWindow {
        required property bool fullscreen
        visible: !fullscreen

        color: Appearance.colors.colLayer0
        implicitWidth: frameThickness; implicitHeight: frameThickness

        anchors {
            left: true
            right: true
        }
    }

    component VerticalFrame: PanelWindow {
        required property bool fullscreen
        visible: !fullscreen

        color: Appearance.colors.colLayer0
        implicitWidth: frameThickness; implicitHeight: frameThickness

        anchors {
            bottom: true
            top: true
        }
    }

    component ScreenCorner: PanelWindow {
        id: screenCornerWindow
        property bool left
        property bool bottom
        required property bool fullscreen
        visible: !fullscreen

        screen: monitorScope.modelData

        anchors {
            bottom: bottom
            top: !bottom
            left: left
            right: !left
        }
        implicitHeight: Appearance.rounding.screenRounding
        implicitWidth: Appearance.rounding.screenRounding
        color: "transparent"

        RoundCorner {
            anchors {
                top: !screenCornerWindow.bottom ? parent.top : undefined
                bottom: screenCornerWindow.bottom ? parent.bottom : undefined
                left: screenCornerWindow.left ? parent.left : undefined
                right: !screenCornerWindow.left ? parent.right : undefined
            }

            implicitSize: Appearance.rounding.screenRounding
            color: Appearance.colors.colLayer0

            corner: screenCornerWindow.left ?
                (screenCornerWindow.bottom ? RoundCorner.CornerEnum.BottomLeft : RoundCorner.CornerEnum.TopLeft) :
                (screenCornerWindow.bottom ? RoundCorner.CornerEnum.BottomRight : RoundCorner.CornerEnum.TopRight)
        }
    }

    Loader {
        active: Config.options.screen.fakeScreenRounding == 3
        sourceComponent: Variants {
            model: Quickshell.screens

            Scope {
                id: monitorScope
                required property var modelData
                property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)

                // Per-monitor fullscreen detection
                property list<HyprlandWorkspace> workspacesForMonitor: Hyprland.workspaces.values.filter(workspace => workspace.monitor && workspace.monitor.name == monitor.name)
                property var activeWorkspaceWithFullscreen: workspacesForMonitor.filter(workspace => ((workspace.toplevels.values.filter(window => window.wayland?.fullscreen)[0] != undefined) && workspace.active))[0]
                property bool fullscreen: activeWorkspaceWithFullscreen != undefined

                // SCREEN CORNERS
                Loader {
                    active: !(barBottom && !barVertical) && !(barVertical && !barBottom)
                    sourceComponent: ScreenCorner {
                        left: true
                        bottom: true
                        fullscreen: monitorScope.fullscreen
                    }
                }
                Loader {
                    active: barBottom
                    sourceComponent: ScreenCorner {
                        left: true
                        bottom: false
                        fullscreen: monitorScope.fullscreen
                    }
                }
                Loader {
                    active: !(!barBottom && !barVertical) && !(barVertical && barBottom)
                    sourceComponent: ScreenCorner {
                        left: false
                        bottom: false
                        fullscreen: monitorScope.fullscreen
                    }
                }
                Loader {
                    active: !barBottom
                    sourceComponent: ScreenCorner {
                        left: false
                        bottom: true
                        fullscreen: monitorScope.fullscreen
                    }
                }

                // FRAMES
                Loader {
                    active: !(!barVertical && barBottom)
                    sourceComponent: HorizontalFrame {
                        screen: monitorScope.modelData
                        anchors.bottom: true
                        fullscreen: monitorScope.fullscreen
                    }
                }
                Loader {
                    active: !(!barVertical && !barBottom)
                    sourceComponent: HorizontalFrame {
                        screen: monitorScope.modelData
                        anchors.top: true
                        fullscreen: monitorScope.fullscreen
                    }
                }
                Loader {
                    active: !(barVertical && barBottom)
                    sourceComponent: VerticalFrame {
                        screen: monitorScope.modelData
                        anchors.right: true
                        fullscreen: monitorScope.fullscreen
                    }
                }
                Loader {
                    active: !(barVertical && !barBottom)
                    sourceComponent: VerticalFrame {
                        screen: monitorScope.modelData
                        anchors.left: true
                        fullscreen: monitorScope.fullscreen
                    }
                }
            }
        }
    }
}
