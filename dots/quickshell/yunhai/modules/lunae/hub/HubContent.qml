pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.lunae.hub.dash
import qs.modules.lunae.hub.media
import qs.modules.lunae.hub.weather

Item {
    id: root

    property int currentTab: 0
    property bool hubVisible: false
    signal tabChangeRequested(int newTab)

    readonly property real preferredWidth: {
        const tabs = HubContext.availableTabs;
        if (currentTab < 0 || currentTab >= tabs.length) return 800;
        switch (tabs[currentTab].identifier) {
            case "dash": return 780;
            case "media": return 730;
            case "weather": return 700;
            default: return 780;
        }
    }

    readonly property real preferredHeight: {
        const tabs = HubContext.availableTabs;
        if (currentTab < 0 || currentTab >= tabs.length) return 430;
        switch (tabs[currentTab].identifier) {
            case "dash": return 375;
            case "media": return 310;
            case "weather": return 370;
            default: return 400;
        }
    }

    readonly property real slotWidth: preferredWidth - 16
    readonly property real slotHeight: preferredHeight - 16

    Behavior on height {
        enabled: root.hubVisible
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Easing.OutCubic
        }
    }
    readonly property var tabComponents: ({
        "dash": dashComp,
        "media": mediaComp,
        "weather": weatherComp,
    })

    Component {
        id: dashComp
        DashGrid {}
    }
    Component {
        id: mediaComp
        HubMediaTab {}
    }
    Component {
        id: weatherComp
        HubWeatherTab {}
    }

    Item {
        id: viewport
        anchors.fill: parent
        anchors.margins: 8
        clip: true

        Row {
            id: contentRow
            height: parent.height

            x: -root.currentTab * root.slotWidth
            Behavior on x {
                NumberAnimation {
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                model: HubContext.availableTabs

                Loader {
                    id: tabLoader
                    required property var modelData
                    required property int index
                    clip: true

                    width: root.slotWidth
                    height: root.slotHeight

                    sourceComponent: root.tabComponents[modelData.identifier] ?? null

                    onLoaded: {
                        item.width = Qt.binding(() => tabLoader.width);
                        item.height = Qt.binding(() => tabLoader.height);
                        if (tabLoader.modelData.identifier === "media") {
                            item.hubVisible = Qt.binding(() => root.hubVisible);
                            item.menuOverlay = menuOverlay;
                        }
                    }
                }
            }
        }
    }

    Item {
        id: menuOverlay
        anchors.fill: parent
        z: 10
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        property real startX: 0
        property bool dragging: false

        onPressed: event => {
            startX = event.x;
            dragging = true;
        }
        onReleased: event => {
            if (dragging) {
                const dx = event.x - startX;
                const maxTab = HubContext.tabCount - 1;
                if (dx > 60 && root.currentTab > 0)
                    root.tabChangeRequested(root.currentTab - 1);
                else if (dx < -60 && root.currentTab < maxTab)
                    root.tabChangeRequested(root.currentTab + 1);
            }
            dragging = false;
        }
    }
}
