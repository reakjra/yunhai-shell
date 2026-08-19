pragma ComponentBehavior: Bound

import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono
import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

Item {
    id: root
    property var shelf
    signal closeRequested()

    readonly property var wd: Weather.data

    implicitWidth: 350
    implicitHeight: col.implicitHeight + 36

    function parseTime12(s) {
        const m = /(\d+):(\d+)\s*(AM|PM)/i.exec(s ?? "");
        if (!m)
            return -1;
        let h = parseInt(m[1]) % 12;
        if (m[3].toUpperCase() === "PM")
            h += 12;
        return h * 60 + parseInt(m[2]);
    }

    readonly property real nowMinutes: {
        DateTime.time;
        const d = new Date();
        return d.getHours() * 60 + d.getMinutes();
    }
    readonly property real riseMin: parseTime12(wd?.sunrise)
    readonly property real setMin: parseTime12(wd?.sunset)
    readonly property bool astroValid: riseMin >= 0 && setMin > riseMin
    readonly property bool isDay: astroValid && nowMinutes >= riseMin && nowMinutes <= setMin
    readonly property real arcFrac: {
        if (!astroValid)
            return 0;
        if (isDay)
            return Math.max(0, Math.min(1, (nowMinutes - riseMin) / (setMin - riseMin)));
        const nightLen = 1440 - (setMin - riseMin);
        const sinceSet = nowMinutes > setMin ? nowMinutes - setMin : nowMinutes + 1440 - setMin;
        return Math.max(0, Math.min(1, sinceSet / nightLen));
    }
    readonly property color arcColor: isDay ? Appearance.colors.colPrimary : Appearance.colors.colSecondary

    component InfoChip: Squircle {
        id: chip
        property string icon
        property string label
        property string value
        Layout.fillWidth: true
        implicitHeight: 54
        radius: 16
        color: Appearance.colors.colLayer1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: chip.icon
                iconSize: 22
                color: Appearance.colors.colPrimary
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: chip.value
                    font.pixelSize: Appearance.font.pixelSize.normal
                    color: Appearance.colors.colOnLayer1
                    elide: Text.ElideRight
                }
                StyledText {
                    Layout.fillWidth: true
                    text: chip.label
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }
            }
        }
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 18
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                StyledText {
                    text: root.wd?.temp ?? "--°"
                    font.pixelSize: 42
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer0
                }
                StyledText {
                    Layout.fillWidth: true
                    text: `${root.wd?.city ?? ""} • ${Translation.tr("Feels like %1").arg(root.wd?.tempFeelsLike ?? "--°")}`
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colSubtext
                    elide: Text.ElideRight
                }
            }

            Squircle {
                implicitWidth: 50
                implicitHeight: 50
                radius: 17
                color: Appearance.colors.colPrimaryContainer

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: Icons.getWeatherIcon(root.wd?.wCode) ?? "cloud"
                    fill: 1
                    iconSize: 27
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }
        }

        Squircle {
            Layout.fillWidth: true
            implicitHeight: 118
            radius: 20
            color: Appearance.colors.colLayer1

            Item {
                id: arcArea
                anchors.fill: parent
                anchors.margins: 12
                readonly property real baseY: height - 24
                readonly property real cx: width / 2
                readonly property real rx: width / 2 - 26
                readonly property real ry: baseY - 16
                readonly property real sunX: cx - rx * Math.cos(root.arcFrac * Math.PI)
                readonly property real sunY: baseY - ry * Math.sin(root.arcFrac * Math.PI)

                Rectangle {
                    x: 0
                    y: arcArea.baseY - height / 2
                    width: parent.width
                    height: 1.5
                    radius: 1
                    color: Appearance.colors.colOutlineVariant
                    opacity: 0.5
                }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    ShapePath {
                        strokeColor: Appearance.colors.colOutlineVariant
                        strokeWidth: 2
                        fillColor: "transparent"
                        strokeStyle: ShapePath.DashLine
                        dashPattern: [0.5, 4]
                        capStyle: ShapePath.RoundCap

                        PathAngleArc {
                            centerX: arcArea.cx
                            centerY: arcArea.baseY
                            radiusX: arcArea.rx
                            radiusY: arcArea.ry
                            startAngle: 180
                            sweepAngle: 180
                        }
                    }
                }

                Shape {
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer
                    visible: root.arcFrac > 0.015

                    ShapePath {
                        strokeColor: root.arcColor
                        strokeWidth: 3
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap

                        PathAngleArc {
                            centerX: arcArea.cx
                            centerY: arcArea.baseY
                            radiusX: arcArea.rx
                            radiusY: arcArea.ry
                            startAngle: 180
                            sweepAngle: 180 * root.arcFrac
                        }
                    }
                }

                Rectangle {
                    x: arcArea.sunX - width / 2
                    y: arcArea.sunY - height / 2
                    width: 26
                    height: 26
                    radius: 13
                    color: root.arcColor

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: root.isDay ? "light_mode" : "dark_mode"
                        fill: 1
                        iconSize: 16
                        color: root.isDay ? Appearance.m3colors.m3onPrimary : Appearance.m3colors.m3onSecondary
                    }
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    spacing: 4

                    MaterialSymbol {
                        text: "wb_twilight"
                        iconSize: 15
                        color: Appearance.colors.colSubtext
                    }
                    StyledText {
                        text: (root.isDay ? root.wd?.sunrise : root.wd?.sunset) ?? "--"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                }

                RowLayout {
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    spacing: 4

                    StyledText {
                        text: (root.isDay ? root.wd?.sunset : root.wd?.sunrise) ?? "--"
                        font.pixelSize: Appearance.font.pixelSize.smaller
                        color: Appearance.colors.colSubtext
                    }
                    MaterialSymbol {
                        text: "routine"
                        iconSize: 15
                        color: Appearance.colors.colSubtext
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 8
            rowSpacing: 8

            InfoChip {
                icon: "air"
                label: Translation.tr("Wind")
                value: `${root.wd?.wind ?? "--"} ${root.wd?.windDir ?? ""}`
            }
            InfoChip {
                icon: "humidity_percentage"
                label: Translation.tr("Humidity")
                value: String(root.wd?.humidity ?? "--")
            }
            InfoChip {
                icon: "rainy"
                label: Translation.tr("Precipitation")
                value: String(root.wd?.precip ?? "--")
            }
            InfoChip {
                icon: "wb_sunny"
                label: Translation.tr("UV index")
                value: String(root.wd?.uv ?? "--")
            }
            InfoChip {
                icon: "visibility"
                label: Translation.tr("Visibility")
                value: String(root.wd?.visib ?? "--")
            }
            InfoChip {
                icon: "compress"
                label: Translation.tr("Pressure")
                value: String(root.wd?.press ?? "--")
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Translation.tr("Updated %1").arg(root.wd?.lastRefresh ?? "--")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }
    }
}
