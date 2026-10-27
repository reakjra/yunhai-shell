pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.lunae
import qs.services
import Quickshell

StyledListView {
    id: root
    property bool popup: false
    property bool elevated: popup

    spacing: 3
    animateAppearance: false

    property bool expanding: false
    Timer {
        id: expandResetTimer
        interval: Motion.spatialFast.duration
        onTriggered: root.expanding = false
    }

    property var sourceValues: popup ? Notifications.popupAppNameList : Notifications.appNameList
    property list<string> displayModel: []
    property var exitingItems: ({})

    onSourceValuesChanged: syncModel()
    Component.onCompleted: displayModel = [...sourceValues]

    function syncModel() {
        const src = [...sourceValues]
        const cur = [...displayModel]

        if (src.length === 0) {
            return
        }

        let next = [...cur]
        let changed = false

        src.forEach(name => {
            if (!next.includes(name)) {
                next.push(name)
                changed = true
            }
        })

        cur.forEach(name => {
            if (!src.includes(name) && !exitingItems[name]) {
                exitingItems[name] = true
                exitingItems = exitingItems
                changed = true
            }
        })

        if (changed) displayModel = next
    }

    function finishExit(appName) {
        delete exitingItems[appName]
        exitingItems = exitingItems
        displayModel = displayModel.filter(n => n !== appName)
    }

    function clearAll() {
        exitingItems = {}
        displayModel = []
    }

    add: Transition {
        MotionAnimation {
            property: "x"
            from: root.width
        }
        MotionAnimation {
            property: "opacity"
            from: 0; to: 1
        }
    }

    addDisplaced: Transition {
        MotionAnimation {
            property: "y"
        }
    }

    model: ScriptModel {
        values: root.displayModel
    }
    delegate: LunaeNotificationGroup {
        required property int index
        required property var modelData
        popup: root.popup
        elevated: root.elevated
        width: ListView.view.width

        property var liveGroup: popup ?
            Notifications.popupGroupsByAppName[modelData] :
            Notifications.groupsByAppName[modelData]
        property var cachedGroup
        onLiveGroupChanged: if (liveGroup) cachedGroup = liveGroup
        notificationGroup: liveGroup ?? cachedGroup

        onExpandedChanged: {
            root.expanding = true
            expandResetTimer.restart()
        }

        isExiting: root.exitingItems[modelData] ?? false
        onExitComplete: root.finishExit(modelData)
    }
}
