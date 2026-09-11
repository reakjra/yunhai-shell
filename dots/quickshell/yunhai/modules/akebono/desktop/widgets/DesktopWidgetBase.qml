pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import qs.modules.common
import qs.modules.common.desktop
import qs.modules.common.widgets
import qs.modules.akebono
import qs.modules.akebono.desktop

Item {
    id: root
    required property var host
    default property alias content: contentHost.data
    property alias backdrop: backdropHost.data
    property bool backdropVisible: false
    property color surfaceColor: Appearance.colors.colLayer1

    readonly property var widgetData: root.host.modelData
    readonly property string wid: root.host.wid
    readonly property bool editMode: root.host.editMode
    readonly property bool manipulating: dragArea.pressed || resizeHandle.pressed
    readonly property bool showBackground: root.widgetData.background ?? true
    readonly property int number: root.host.index + 1
    property real themeRadius: 22
    readonly property var shape: WidgetShapes.forId(root.widgetData.shape ?? "")
    readonly property var chipShape: WidgetShapes.forId(root.widgetData.chipShape ?? "")
    readonly property real shapeRadius: Math.min(root.shape.radius ?? root.themeRadius, Math.min(root.width, root.height) / 2)
    readonly property real shapeSmoothing: root.shape.smoothing ?? AkebonoAppearance.squircleSmoothing
    readonly property string styleId: root.widgetData.style ?? WidgetStyles.defaultFor(root.widgetData.type)
    readonly property real shapeSkew: root.shape.skew ?? 0
    readonly property bool scalloped: (root.shape.lobes ?? 0) > 0
    readonly property real insetBasis: root.shape.square === true ? Math.min(root.width, root.height) / 2 : root.shapeRadius
    readonly property real contentInset: root.shape.inset !== undefined ? root.insetBasis * root.shape.inset : Math.max(0, root.shapeRadius - 28) * 0.5
    readonly property real skewInset: Math.abs(root.shapeSkew) * root.height / 2
    property int minSize: 90
    property int maxSize: 600
    readonly property int gridSize: 24
    readonly property real shadowStr: Config.options.desktop.widgetShadowStrength

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
        visible: Config.options.desktop.widgetShadow && root.showBackground && !root.scalloped
        readonly property real spreadPx: 8 + root.shadowStr * 14
        readonly property real offY: 1 + root.shadowStr * 9
        readonly property real pad: Math.ceil(shadowFx.spreadPx + shadowFx.offY + 6)
        x: -shadowFx.pad
        y: -shadowFx.pad + shadowFx.offY
        width: root.width + 2 * shadowFx.pad
        height: root.height + 2 * shadowFx.pad
        property vector2d size: Qt.vector2d(width, height)
        property color color: Qt.rgba(0, 0, 0, 0.1 + root.shadowStr * 0.4)
        property real radius: root.shapeRadius
        property real smoothing: root.shapeSmoothing
        property real spread: shadowFx.spreadPx
        property vector2d boxHalf: Qt.vector2d(root.width / 2, root.height / 2)
        property vector2d boxCenter: Qt.vector2d(width / 2, height / 2)
        fragmentShader: Quickshell.shellPath("assets/shaders/akebono/shadow.frag.qsb")
    }

    ShapeSurface {
        anchors.fill: parent
        visible: root.showBackground
        shape: root.shape
        themeRadius: root.themeRadius
        color: root.surfaceColor
    }

    Item {
        id: backdropHost
        anchors.fill: parent
        visible: root.backdropVisible
        transform: SkewMatrix {}
        layer.enabled: root.backdropVisible
        layer.effect: OpacityMask {
            maskSource: ShapeSurface {
                width: backdropHost.width
                height: backdropHost.height
                shape: root.shape
                themeRadius: root.themeRadius
                applySkew: false
                color: "white"
            }
        }
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

    Rectangle {
        visible: root.editMode
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: -6
        anchors.topMargin: -6
        z: 2
        implicitWidth: Math.max(26, numberLabel.implicitWidth + 12)
        implicitHeight: 26
        radius: 13
        color: Appearance.colors.colLayer2

        StyledText {
            id: numberLabel
            anchors.centerIn: parent
            text: root.number
            font.pixelSize: Appearance.font.pixelSize.small
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
        }
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
            icon: "settings"
            onTriggered: Quickshell.execDetached(["env", "YUNHAI_SETTINGS_PAGE=modules/settings/DesktopConfig.qml", `YUNHAI_SETTINGS_SECTION=${root.wid}`, "qs", "-p", Quickshell.shellPath("settings.qml")])
        }
    }

    component SkewMatrix: Matrix4x4 {
        matrix: Qt.matrix4x4(1, root.shapeSkew, 0, -root.shapeSkew * root.height / 2,
                             0, 1, 0, 0,
                             0, 0, 1, 0,
                             0, 0, 0, 1)
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
            const w = Math.max(root.minSize, Math.min(root.maxSize, nw));
            const h = Math.max(root.minSize, Math.min(root.maxSize, nh));
            const square = WidgetShapes.isSquare(root.widgetData.shape ?? "");
            root.host.width = square ? Math.max(w, h) : w;
            root.host.height = square ? Math.max(w, h) : h;
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
