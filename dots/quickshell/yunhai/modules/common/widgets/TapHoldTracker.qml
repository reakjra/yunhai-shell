import QtQuick

QtObject {
    id: root

    required property MouseArea area
    property bool holding: false

    signal tapped()
    signal held()

    readonly property Connections areaConnections: Connections {
        target: root.area

        function onPressed() {
            root.holding = false;
        }
        function onPressAndHold() {
            root.holding = true;
            root.held();
        }
        function onReleased() {
            if (!root.holding && root.area.containsMouse)
                root.tapped();
        }
    }
}
