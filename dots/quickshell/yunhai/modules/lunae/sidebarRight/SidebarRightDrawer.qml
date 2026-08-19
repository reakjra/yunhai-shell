pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.lunae.sidebarRight.quickToggles

Item {
    id: root

    property real contentWidth: Appearance.sizes.sidebarWidth
    property real armpitSize: Appearance.rounding.normal
    property bool sidebarVisible: false
    property string mode: "full"

    readonly property real toggleSectionHeight: {
        let h = togglesCard.implicitHeight
        if (slidersCard.visible) h += 12 + slidersCard.implicitHeight
        if (profileFooter.visible) h += 12 + profileFooter.implicitHeight
        return h
    }

    onSidebarVisibleChanged: if (!sidebarVisible) {
        togglesCard.editMode = false
        togglesCard.activeDialog = ""
        profileFooter.timerExpanded = false
        GlobalStates.sidebarRightPinned = false
    }

    property var brightnessMonitor: Brightness.getMonitorForScreen(root.QsWindow.window?.screen)

    ColumnLayout {
        x: root.armpitSize + 12
        y: root.mode === "toggles"
            ? (root.height - 20 - implicitHeight)
            : 20
        width: root.contentWidth - 24
        height: root.mode === "toggles"
            ? implicitHeight
            : (root.height - 40)
        spacing: 12

        NotifHeaderRow {
            visible: root.mode !== "toggles"
        }

        NotifListCard {
            visible: root.mode !== "toggles"
        }

        Rectangle {
            visible: root.mode === "full"
            Layout.fillWidth: true
            Layout.preferredHeight: 2
            radius: Appearance.rounding.full
            color: Appearance.colors.colOnLayer1
            opacity: 0.15
        }

        QuickTogglesCard {
            id: togglesCard
            visible: root.mode !== "notifs"
        }

        SlidersCard {
            id: slidersCard
            visible: root.mode !== "notifs"
                && (Config.options.lunae.sidebar.sliders.showBrightness || Config.options.lunae.sidebar.sliders.showVolume)
            brightnessMonitor: root.brightnessMonitor
        }

        ProfileFooter {
            id: profileFooter
            visible: root.mode !== "notifs"
        }
    }
}
