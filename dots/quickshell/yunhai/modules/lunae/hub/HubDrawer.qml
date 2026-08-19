pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Item {
    id: root

    property real drawerWidth: hubContent.preferredWidth
    property real armpitSize: Appearance.rounding.normal

    Behavior on drawerWidth {
        enabled: root.hubVisible
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Easing.OutCubic
        }
    }

    property int currentTab: 0
    property bool hubVisible: false

    property alias contentColumn: contentColumn
    property alias hubTabs: hubTabs

    readonly property bool systemTabActive: {
        const tabs = HubContext.availableTabs;
        return currentTab >= 0 && currentTab < tabs.length && tabs[currentTab].identifier === "system";
    }

    onSystemTabActiveChanged: {
        if (systemTabActive && hubVisible) {
            Notifications.timeoutAll();
            Notifications.markAllRead();
        }
    }

    Connections {
        target: Notifications
        enabled: root.systemTabActive && root.hubVisible
        function onUnreadChanged() {
            if (Notifications.unread > 0) {
                Notifications.timeoutAll();
                Notifications.markAllRead();
            }
        }
    }

    Column {
        id: contentColumn
        anchors.top: parent.top
        anchors.topMargin: root.armpitSize
        x: root.armpitSize
        width: root.drawerWidth

        HubTabs {
            id: hubTabs
            width: parent.width
            targetWidth: hubContent.preferredWidth
            currentTab: root.currentTab
            onTabClicked: index => root.currentTab = index
        }

        HubContent {
            id: hubContent
            width: parent.width
            height: hubContent.preferredHeight
            currentTab: root.currentTab
            hubVisible: root.hubVisible
            onTabChangeRequested: newTab => root.currentTab = newTab
        }
    }
}
