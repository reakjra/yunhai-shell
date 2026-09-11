pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.desktop
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.akebono
import qs.modules.akebono.desktop
import qs.modules.akebono.desktop.widgets

WidgetCard {
    id: root
    minSize: 130

    readonly property string selectedKey: root.widgetData.device ?? ""
    readonly property int deviceIndex: {
        const devices = Battery.batteries;
        for (let i = 0; i < devices.length; ++i) {
            if (Battery.keyFor(devices[i]) === root.selectedKey)
                return i;
        }
        return devices.length > 0 ? 0 : -1;
    }
    readonly property var device: root.deviceIndex >= 0 ? Battery.batteries[root.deviceIndex] : null
    readonly property bool charging: root.device !== null && Battery.isDeviceCharging(root.device)
    readonly property bool low: root.device !== null && root.device.percentage <= Battery.thresholdFor(Battery.keyFor(root.device)) / 100
    readonly property bool systemBattery: root.device !== null && root.device.isLaptopBattery
    readonly property real glyphSize: Math.round(Math.min(root.width, root.height) * 0.42)
    readonly property color glyphColor: root.low && !root.charging ? Appearance.colors.colError : Appearance.colors.colOnLayer1
    readonly property bool cyclable: root.editMode && Battery.batteries.length > 1

    function cycle(step) {
        const devices = Battery.batteries;
        if (devices.length === 0)
            return;
        const next = (root.deviceIndex + step + devices.length) % devices.length;
        DesktopWidgets.setProp(root.wid, "device", Battery.keyFor(devices[next]));
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        StyledText {
            Layout.fillWidth: true
            text: root.device !== null ? Battery.labelFor(root.device) : Translation.tr("No device")
            font.pixelSize: Appearance.font.pixelSize.normal
            font.weight: Font.DemiBold
            color: Appearance.colors.colOnLayer1
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            MaterialSymbol {
                anchors.centerIn: parent
                visible: root.systemBattery
                text: root.systemBattery ? DeviceIcons.symbolForLevel(root.device.percentage, root.charging, root.low) : ""
                fill: 1
                iconSize: root.glyphSize
                color: root.glyphColor
            }

            CustomIcon {
                anchors.centerIn: parent
                width: root.glyphSize
                height: root.glyphSize
                visible: root.device !== null && !root.systemBattery
                iconFolder: DeviceIcons.folder
                source: root.device !== null && !root.systemBattery ? DeviceIcons.fileForDevice(root.device) : ""
                colorize: true
                color: root.glyphColor
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                radius: height / 2
                color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, 0.82)

                Rectangle {
                    width: parent.width * (root.device !== null ? root.device.percentage : 0)
                    height: parent.height
                    radius: parent.radius
                    color: root.low && !root.charging ? Appearance.colors.colError : Appearance.colors.colPrimary

                    Behavior on width {
                        NumberAnimation {
                            duration: 220
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            MaterialSymbol {
                visible: root.charging
                text: "bolt"
                fill: 1
                iconSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colPrimary
            }

            StyledText {
                text: root.device !== null ? `${Math.round(root.device.percentage * 100)}%` : "--"
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colSubtext
            }
        }
    }

    CycleButton {
        parent: root
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 2
        icon: "chevron_left"
        onTriggered: root.cycle(-1)
    }

    CycleButton {
        parent: root
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 2
        icon: "chevron_right"
        onTriggered: root.cycle(1)
    }

    component CycleButton: Rectangle {
        id: button
        property string icon: ""
        signal triggered()

        z: 1
        visible: root.cyclable
        implicitWidth: 24
        implicitHeight: 24
        radius: width / 2
        color: buttonArea.containsMouse ? Appearance.colors.colLayer2Hover : Qt.alpha(Appearance.colors.colLayer2, 0.9)

        MaterialSymbol {
            anchors.centerIn: parent
            text: button.icon
            iconSize: 16
            color: Appearance.colors.colOnLayer1
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.triggered()
        }
    }
}
