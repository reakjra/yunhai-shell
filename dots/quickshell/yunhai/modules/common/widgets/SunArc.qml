pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.services
import qs.modules.common

Item {
    id: root

    property string sunrise: ""
    property string sunset: ""
    property real sunSize: 26
    property real trackWidth: 2
    property real progressWidth: 3
    property real labelSize: Appearance.font.pixelSize.smaller
    property bool showLabels: true
    property color dayColor: Appearance.colors.colPrimary
    property color nightColor: Appearance.colors.colSecondary
    property color trackColor: Appearance.colors.colOutlineVariant
    property color labelColor: Appearance.colors.colSubtext

    function parseClock(value: string): real {
        const m = /(\d+):(\d+)\s*(AM|PM)/i.exec(value ?? "");
        if (!m)
            return -1;
        const h = parseInt(m[1]) % 12 + (m[3].toUpperCase() === "PM" ? 12 : 0);
        return h * 60 + parseInt(m[2]);
    }

    readonly property real riseMinutes: root.parseClock(root.sunrise)
    readonly property real setMinutes: root.parseClock(root.sunset)
    readonly property bool valid: root.riseMinutes >= 0 && root.setMinutes > root.riseMinutes
    readonly property real nowMinutes: {
        DateTime.time;
        const d = new Date();
        return d.getHours() * 60 + d.getMinutes();
    }
    readonly property bool isDay: root.valid && root.nowMinutes >= root.riseMinutes && root.nowMinutes <= root.setMinutes
    readonly property real progress: {
        if (!root.valid)
            return 0;
        if (root.isDay)
            return (root.nowMinutes - root.riseMinutes) / (root.setMinutes - root.riseMinutes);
        const nightLength = 1440 - (root.setMinutes - root.riseMinutes);
        const sinceSet = root.nowMinutes > root.setMinutes ? root.nowMinutes - root.setMinutes : root.nowMinutes + 1440 - root.setMinutes;
        return Math.max(0, Math.min(1, sinceSet / nightLength));
    }
    readonly property color arcColor: root.isDay ? root.dayColor : root.nightColor

    readonly property real baseY: root.height - (root.showLabels ? root.labelSize + 11 : root.sunSize / 2)
    readonly property real centerX: root.width / 2
    readonly property real radiusX: Math.max(1, root.width / 2 - root.sunSize)
    readonly property real radiusY: Math.max(1, root.baseY - root.sunSize / 2 - 3)

    Rectangle {
        y: root.baseY - height / 2
        width: parent.width
        height: 1.5
        radius: 1
        color: root.trackColor
        opacity: 0.5
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.trackColor
            strokeWidth: root.trackWidth
            fillColor: "transparent"
            strokeStyle: ShapePath.DashLine
            dashPattern: [0.5, 4]
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.centerX
                centerY: root.baseY
                radiusX: root.radiusX
                radiusY: root.radiusY
                startAngle: 180
                sweepAngle: 180
            }
        }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        visible: root.progress > 0.015

        ShapePath {
            strokeColor: root.arcColor
            strokeWidth: root.progressWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.centerX
                centerY: root.baseY
                radiusX: root.radiusX
                radiusY: root.radiusY
                startAngle: 180
                sweepAngle: 180 * root.progress
            }
        }
    }

    Rectangle {
        x: root.centerX - root.radiusX * Math.cos(root.progress * Math.PI) - width / 2
        y: root.baseY - root.radiusY * Math.sin(root.progress * Math.PI) - height / 2
        width: root.sunSize
        height: root.sunSize
        radius: width / 2
        color: root.arcColor

        MaterialSymbol {
            anchors.centerIn: parent
            text: root.isDay ? "light_mode" : "dark_mode"
            fill: 1
            iconSize: Math.round(root.sunSize * 0.62)
            color: root.isDay ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSecondary
        }
    }

    component EdgeLabel: RowLayout {
        id: edge
        property string icon: ""
        property string time: ""
        anchors.bottom: parent.bottom
        visible: root.showLabels
        spacing: 4
        layoutDirection: edge.reversed ? Qt.RightToLeft : Qt.LeftToRight
        property bool reversed: false

        MaterialSymbol {
            text: edge.icon
            iconSize: Math.round(root.labelSize * 1.25)
            color: root.labelColor
        }
        StyledText {
            text: root.valid ? edge.time : "--"
            font.pixelSize: root.labelSize
            color: root.labelColor
        }
    }

    EdgeLabel {
        anchors.left: parent.left
        icon: "wb_twilight"
        time: root.isDay ? root.sunrise : root.sunset
    }

    EdgeLabel {
        anchors.right: parent.right
        reversed: true
        icon: "routine"
        time: root.isDay ? root.sunset : root.sunrise
    }
}
