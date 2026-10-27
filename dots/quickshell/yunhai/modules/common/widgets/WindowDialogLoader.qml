import QtQuick

Loader {
    id: root

    property bool shown: false
    property alias dialog: root.sourceComponent

    signal dismissed()

    anchors.fill: parent
    active: false

    onShownChanged: {
        if (root.item)
            root.item.show = root.shown;
        else if (root.shown)
            root.active = true;
    }
    onLoaded: {
        root.item.show = true;
        root.item.forceActiveFocus();
    }

    Connections {
        target: root.item

        function onDismiss() {
            root.dismissed();
        }

        function onVisibleChanged() {
            if (!root.item.visible && !root.shown)
                root.active = false;
        }
    }
}
