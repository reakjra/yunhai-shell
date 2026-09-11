pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono
import qs.modules.akebono.desktop

Item {
    id: root
    required property var host
    default property alias content: contentHost.data

    readonly property var widgetData: root.host.modelData
    readonly property string wid: root.host.wid
    readonly property bool editMode: root.host.editMode
    readonly property bool manipulating: dragArea.pressed || resizeHandle.pressed
    readonly property bool showBackground: root.widgetData.background ?? true
    property int minSize: 90
    property int maxSize: 600
    readonly property int gridSize: 24
    readonly property real shadowStr: Config.options.desktop.widgetShadowStrength
    property real shadowRadius: 24

    function snap(v) {
        return Math.round(v / root.gridSize) * root.gridSize;
    }

    SequentialAnimation on rotation {
        running: root.editMode && (Config.options.desktop.widgetWobble)
        loops: Animation.Infinite
        onStopped: root.rotation = 0
        NumberAnimation { to: 1.1; duration: 110; easing.type: Easing.InOutSine }
        NumberAnimation { to: -1.1; duration: 220; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0; duration: 110; easing.type: Easing.InOutSine }
    }

    ShaderEffect {
        id: shadowFx
        visible: Config.options.desktop.widgetShadow && root.showBackground
        readonly property real spreadPx: 8 + root.shadowStr * 14
        readonly property real offY: 1 + root.shadowStr * 9
        readonly property real pad: Math.ceil(shadowFx.spreadPx + shadowFx.offY + 6)
        x: -shadowFx.pad
        y: -shadowFx.pad + shadowFx.offY
        width: root.width + 2 * shadowFx.pad
        height: root.height + 2 * shadowFx.pad
        property vector2d size: Qt.vector2d(width, height)
        property color color: Qt.rgba(0, 0, 0, 0.1 + root.shadowStr * 0.4)
        property real radius: root.shadowRadius
        property real smoothing: AkebonoAppearance.squircleSmoothing
        property real spread: shadowFx.spreadPx
        property vector2d boxHalf: Qt.vector2d(root.width / 2, root.height / 2)
        property vector2d boxCenter: Qt.vector2d(width / 2, height / 2)
        fragmentShader: Quickshell.shellPath("assets/shaders/akebono/shadow.frag.qsb")
    }

    Item {
        id: contentHost
        anchors.fill: parent
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        enabled: root.editMode
        cursorShape: root.editMode ? Qt.OpenHandCursor : Qt.ArrowCursor
        property real grabX: 0
        property real grabY: 0
        onPressed: mouse => {
            dragArea.grabX = mouse.x;
            dragArea.grabY = mouse.y;
        }
        onPositionChanged: mouse => {
            if (!dragArea.pressed)
                return;
            const scene = dragArea.mapToItem(root.host.parent, mouse.x, mouse.y);
            let nx = scene.x - dragArea.grabX;
            let ny = scene.y - dragArea.grabY;
            if (mouse.modifiers & Qt.ShiftModifier) {
                nx = root.snap(nx);
                ny = root.snap(ny);
            }
            root.host.x = nx;
            root.host.y = ny;
        }
        onReleased: DesktopWidgets.setPos(root.wid, root.host.x, root.host.y)
    }

    Column {
        visible: root.editMode
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -6
        anchors.topMargin: -6
        spacing: 4
        z: 2

        ChromeButton {
            icon: "close"
            color: Appearance.colors.colError
            iconColor: Appearance.colors.colOnError
            onTriggered: DesktopWidgets.remove(root.wid)
        }
        ChromeButton {
            icon: root.showBackground ? "format_color_fill" : "format_color_reset"
            onTriggered: DesktopWidgets.setProp(root.wid, "background", !root.showBackground)
        }
    }

    component ChromeButton: Rectangle {
        id: button
        property string icon: ""
        property color iconColor: Appearance.colors.colOnLayer1
        signal triggered()

        width: 26
        height: 26
        radius: width / 2
        color: buttonArea.containsMouse ? Appearance.colors.colLayer2Hover : Appearance.colors.colLayer2

        MaterialSymbol {
            anchors.centerIn: parent
            text: button.icon
            iconSize: 16
            color: button.iconColor
        }
        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.triggered()
        }
    }

    MouseArea {
        id: resizeHandle
        visible: root.editMode
        width: 34
        height: 34
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        cursorShape: Qt.SizeFDiagCursor
        property real startW: 0
        property real startH: 0
        property point startScene
        onPressed: mouse => {
            resizeHandle.startW = root.width;
            resizeHandle.startH = root.height;
            resizeHandle.startScene = resizeHandle.mapToItem(root.host.parent, mouse.x, mouse.y);
        }
        onPositionChanged: mouse => {
            if (!resizeHandle.pressed)
                return;
            const p = resizeHandle.mapToItem(root.host.parent, mouse.x, mouse.y);
            let nw = resizeHandle.startW + (p.x - resizeHandle.startScene.x);
            let nh = resizeHandle.startH + (p.y - resizeHandle.startScene.y);
            if (mouse.modifiers & Qt.ShiftModifier) {
                nw = root.snap(nw);
                nh = root.snap(nh);
            }
            root.host.width = Math.max(root.minSize, Math.min(root.maxSize, nw));
            root.host.height = Math.max(root.minSize, Math.min(root.maxSize, nh));
        }
        onReleased: DesktopWidgets.setSize(root.wid, root.host.width, root.host.height)

        Rectangle {
            anchors.centerIn: parent
            width: 24
            height: 24
            radius: 12
            color: Qt.alpha(Appearance.colors.colLayer0, 0.85)
            MaterialSymbol {
                anchors.centerIn: parent
                text: "chevron_right"
                rotation: 45
                iconSize: 19
                color: Appearance.colors.colOnLayer0
            }
        }
    }
}
