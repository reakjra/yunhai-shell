pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.lunae.hub.dash
import qs.modules.lunae.hub.media
import qs.modules.lunae.hub.performance
import qs.modules.lunae.hub.weather

Item {
    id: root

    property int currentTab: 0
    property bool hubVisible: false
    signal tabChangeRequested(int newTab)

    readonly property real inset: 8
    readonly property var tabSizes: ({
        "dash": Qt.size(780, 375),
        "media": Qt.size(730, 310),
        "weather": Qt.size(700, 370),
        "system": Qt.size(1000, 390),
    })

    function sizeFor(identifier: string): size {
        return tabSizes[identifier] ?? Qt.size(780, 400);
    }

    readonly property size currentSize: {
        const tabs = HubContext.availableTabs;
        return currentTab >= 0 && currentTab < tabs.length ? sizeFor(tabs[currentTab].identifier) : Qt.size(800, 430);
    }
    readonly property real preferredWidth: currentSize.width
    readonly property real preferredHeight: currentSize.height

    readonly property bool popupOpen: tabRepeater.count > 0 && (tabRepeater.itemAt(currentTab)?.item?.popupOpen ?? false)

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
        "system": performanceComp,
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
    Component {
        id: performanceComp
        HubPerformanceTab {}
    }

    Item {
        id: viewport
        anchors.fill: parent
        anchors.margins: root.inset
        clip: true

        Row {
            id: contentRow
            height: parent.height

            x: {
                const tabs = HubContext.availableTabs;
                let offset = 0;
                for (let i = 0; i < root.currentTab && i < tabs.length; i++)
                    offset += root.sizeFor(tabs[i].identifier).width - root.inset * 2;
                return -offset;
            }
            Behavior on x {
                NumberAnimation {
                    duration: Appearance.animation.elementMove.duration
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                id: tabRepeater
                model: HubContext.availableTabs

                Loader {
                    id: tabLoader
                    required property var modelData
                    required property int index
                    clip: true

                    width: root.sizeFor(modelData.identifier).width - root.inset * 2
                    height: root.sizeFor(modelData.identifier).height - root.inset * 2

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
