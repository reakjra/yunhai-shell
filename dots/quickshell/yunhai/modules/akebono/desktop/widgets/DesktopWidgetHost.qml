pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.akebono.desktop
import qs.modules.akebono.desktop.widgets.calendar
import qs.modules.akebono.desktop.widgets.deviceBattery
import qs.modules.akebono.desktop.widgets.image
import qs.modules.akebono.desktop.widgets.media
import qs.modules.akebono.desktop.widgets.notes
import qs.modules.akebono.desktop.widgets.weather

Item {
    id: root

    required property var modelData
    readonly property string wid: root.modelData.id
    readonly property bool editMode: DesktopWidgets.editMode
    readonly property bool manipulating: contentLoader.item?.manipulating ?? false

    readonly property var componentsByType: ({
            "calendar": calendarComponent,
            "deviceBattery": deviceBatteryComponent,
            "image": imageComponent,
            "media": mediaComponent,
            "notes": notesComponent,
            "weather": weatherComponent
        })

    function syncGeometry() {
        if (root.manipulating)
            return;
        root.x = root.modelData.x ?? 60;
        root.y = root.modelData.y ?? 60;
        root.width = root.modelData.w ?? 190;
        root.height = root.modelData.h ?? 190;
    }

    onModelDataChanged: root.syncGeometry()
    Component.onCompleted: root.syncGeometry()

    Loader {
        id: contentLoader
        anchors.fill: parent
        sourceComponent: root.componentsByType[root.modelData.type] ?? null
    }

    Component {
        id: calendarComponent
        CalendarWidget {
            host: root
        }
    }
    Component {
        id: deviceBatteryComponent
        DeviceBatteryWidget {
            host: root
        }
    }
    Component {
        id: imageComponent
        ImageWidget {
            host: root
        }
    }
    Component {
        id: mediaComponent
        MediaWidget {
            host: root
        }
    }
    Component {
        id: notesComponent
        NotesWidget {
            host: root
        }
    }
    Component {
        id: weatherComponent
        WeatherWidget {
            host: root
        }
    }
}
