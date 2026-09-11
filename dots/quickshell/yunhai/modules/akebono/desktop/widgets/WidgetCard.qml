pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.modules.akebono
import qs.modules.akebono.desktop.widgets

DesktopWidgetBase {
    id: root

    default property alias cardContent: contentArea.data
    property int padding: 14
    themeRadius: Appearance.rounding.large

    Item {
        id: contentArea
        anchors.fill: parent
        anchors.margins: root.padding + root.contentInset + root.skewInset
    }
}
