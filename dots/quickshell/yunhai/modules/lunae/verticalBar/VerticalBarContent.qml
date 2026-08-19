import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.lunae.bar as Bar

Item {
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    property bool showBarBackground: Config.options.bar.barBackgroundStyle === 1
    

    component HorizontalBarSeparator: Rectangle {
        Layout.leftMargin: Appearance.sizes.baseBarHeight / 3
        Layout.rightMargin: Appearance.sizes.baseBarHeight / 3
        Layout.fillWidth: true
        implicitHeight: 1
        color: Appearance.colors.colOutlineVariant
    }

    property int topSidebarButtonHeight
    property int bottomSidebarButtonHeight: barBottomSectionMouseArea.implicitHeight - 24

    property var fullModel: Config.options?.bar?.layouts?.center

    property int centerIdx: (fullModel || []).findIndex(item => item.centered)

    property var leftList: centerIdx === -1 ? [] : fullModel.slice(0, centerIdx)
    property var centerList: centerIdx === -1 ? fullModel : [fullModel[centerIdx]]
    property var rightList: centerIdx === -1 ? [] : fullModel.slice(centerIdx + 1)

    FocusedScrollMouseArea {
        id: barTopSectionMouseArea
        anchors.top: parent.top
        implicitHeight: topSectionColumnLayout.implicitHeight
        implicitWidth: Appearance.sizes.baseVerticalBarWidth
        height: (root.height - middleSection.height) / 2
        width: Appearance.sizes.verticalBarWidth

        onScrollDown: Brightness.decreaseBrightness()
        onScrollUp: Brightness.increaseBrightness()
        onMovedAway: GlobalStates.osdBrightnessOpen = false
        onPressed: event => {
            if (event.button === Qt.LeftButton)
                GlobalStates.sidebarLeftOpen = !GlobalStates.sidebarLeftOpen;
        }

        ColumnLayout {
            id: topSectionColumnLayout
            anchors.fill: parent
            spacing: 10

            Bar.BarGroup {
                id: topSidebarButtonGroup
                vertical: true
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Appearance.rounding.screenRounding / 2

                startRadius: Appearance.rounding.full
                endRadius: Config.options.bar.layouts.left.length > 0 ? Appearance.rounding.verysmall : Appearance.rounding.full

                Component.onCompleted: topSidebarButtonHeight = leftButton.height + 2

                Bar.LeftSidebarButton {
                    id: leftButton
                    colBackground: barTopSectionMouseArea.hovered ? Appearance.colors.colLayer1Hover : ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                }
            }
            
            Item {
                Layout.fillHeight: true
            }
            
        }
    }

    Item {
        id: topStopper
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: Appearance.rounding.screenRounding + topSidebarButtonHeight
        }
        height: 1
    }

    ColumnLayout {
        id: topSection
        anchors {
            top: topStopper.bottom
            horizontalCenter: parent.horizontalCenter
        }
        spacing: 4

        Repeater {
            id: leftRepeater
            model: Config.options.bar.layouts.left
            delegate: Bar.BarComponent {
                vertical: true
                list: Config.options.bar.layouts.left
                barSection: 0
            }
        }
    }

    Item {
        id: middleSection
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
        }

        ColumnLayout {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: centerCenter.top
                bottomMargin: 4
            }
            Repeater {
                id: middleLeftRepeater
                model: root.leftList
                delegate: Bar.BarComponent {
                    vertical: true
                    list: Config.options.bar.layouts.center
                    barSection: 1
                    originalIndex: Config.options.bar.layouts.center.findIndex(e => e.id === modelData.id)
                }
            }
        }

        ColumnLayout {
            id: centerCenter
            anchors {
                horizontalCenter: parent.horizontalCenter
                verticalCenter: parent.verticalCenter
            }
            Repeater {
                model: root.centerList
                delegate: Bar.BarComponent {
                    vertical: true
                    list: Config.options.bar.layouts.center
                    barSection: 1
                    originalIndex: Config.options.bar.layouts.center.findIndex(e => e.id === modelData.id)
                }
            }
        }

        ColumnLayout {
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: centerCenter.bottom
                topMargin: 4
            }
            Repeater {
                id: middleRightRepeater
                model: root.rightList
                delegate: Bar.BarComponent {
                    vertical: true
                    list: Config.options.bar.layouts.center
                    barSection: 1
                    originalIndex: Config.options.bar.layouts.center.findIndex(e => e.id === modelData.id)
                }
            }
        }

    }

    ColumnLayout {
        id: bottomSection
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: bottomStopper.top
        }
        spacing: 4

        Repeater {
            id: rightRepeater
            model: Config.options.bar.layouts.right
            delegate: Bar.BarComponent {
                vertical: true
                list: Config.options.bar.layouts.right
                barSection: 2
            }
        }
    }

    Item {
        id: bottomStopper
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            bottomMargin: Appearance.rounding.screenRounding + bottomSidebarButtonHeight
        }
        height: 1
    }

    FocusedScrollMouseArea {
        id: barBottomSectionMouseArea

        z: -1
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            top: middleSection.bottom
        }
        implicitWidth: Appearance.sizes.baseVerticalBarWidth
        implicitHeight: bottomSectionColumnLayout.implicitHeight
        
        onScrollDown: Audio.decrementVolume();
        onScrollUp: Audio.incrementVolume();
        onMovedAway: GlobalStates.osdVolumeOpen = false;
        onPressed: event => {
            if (event.button === Qt.LeftButton) {
                GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen;
            }
        }

        ColumnLayout {
            id: bottomSectionColumnLayout
            anchors.fill: parent
            spacing: 4

            Item { 
                Layout.fillWidth: true
                Layout.fillHeight: true 
            }

            Bar.BarGroup {
                vertical: true
                Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
                Layout.bottomMargin: 4
                Layout.fillHeight: false

                startRadius: Config.options.bar.layouts.right.length > 0 ? Appearance.rounding.verysmall : Appearance.rounding.full
                endRadius: Appearance.rounding.full

                Item {
                    id: rightSidebarButton
                    property color colText: Config.options.lunae.colorful ? Appearance.colors.colSecondary : Appearance.colors.colOnLayer0

                    implicitHeight: indicatorsColumnLayout.implicitHeight + 4 * 2
                    implicitWidth: indicatorsColumnLayout.implicitWidth + 6 * 2

                    Rectangle {
                        anchors.fill: parent
                        radius: Appearance.rounding.full
                        color: Appearance.colors.colLayer1Hover
                    }

                    ColumnLayout {
                        id: indicatorsColumnLayout
                        anchors.centerIn: parent
                        property real realSpacing: 6
                        spacing: 0

                        Revealer {
                            vertical: true
                            reveal: Audio.sink?.audio?.muted ?? false
                            Layout.fillWidth: true
                            Layout.bottomMargin: reveal ? indicatorsColumnLayout.realSpacing : 0
                            Behavior on Layout.bottomMargin {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            MaterialSymbol {
                                text: "volume_off"
                                iconSize: Appearance.font.pixelSize.larger
                                color: rightSidebarButton.colText
                            }
                        }
                        Revealer {
                            vertical: true
                            reveal: Audio.source?.audio?.muted ?? false
                            Layout.fillWidth: true
                            Layout.bottomMargin: reveal ? indicatorsColumnLayout.realSpacing : 0
                            Behavior on Layout.bottomMargin {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            MaterialSymbol {
                                text: "mic_off"
                                iconSize: Appearance.font.pixelSize.larger
                                color: rightSidebarButton.colText
                            }
                        }
                        Bar.HyprlandXkbIndicator {
                            vertical: true
                            Layout.alignment: Qt.AlignHCenter
                            Layout.bottomMargin: indicatorsColumnLayout.realSpacing
                            color: rightSidebarButton.colText
                        }
                        Revealer {
                            vertical: true
                            reveal: Notifications.silent || Notifications.unread > 0
                            Layout.fillWidth: true
                            Layout.bottomMargin: reveal ? indicatorsColumnLayout.realSpacing : 0
                            implicitHeight: reveal ? notificationUnreadCount.implicitHeight : 0
                            implicitWidth: reveal ? notificationUnreadCount.implicitWidth : 0
                            Behavior on Layout.bottomMargin {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                            Bar.NotificationUnreadCount {
                                id: notificationUnreadCount
                            }
                        }
                        MaterialSymbol {
                            text: Network.materialSymbol
                            iconSize: Appearance.font.pixelSize.larger
                            color: rightSidebarButton.colText
                        }
                        MaterialSymbol {
                            Layout.topMargin: indicatorsColumnLayout.realSpacing
                            visible: BluetoothStatus.available
                            text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                            iconSize: Appearance.font.pixelSize.larger
                            color: rightSidebarButton.colText
                        }
                    }
                }
            }

            Bar.BarGroup {
                vertical: true
                Layout.alignment: Qt.AlignBottom | Qt.AlignHCenter
                Layout.bottomMargin: Appearance.rounding.screenRounding / 2
                Layout.fillHeight: false

                startRadius: Appearance.rounding.full
                endRadius: Appearance.rounding.full

                RippleButton {
                    implicitHeight: 32
                    implicitWidth: 32
                    buttonRadius: Appearance.rounding.full
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                    colRippleToggled: Appearance.colors.colSecondaryContainerActive
                    toggled: GlobalStates.activeBarPopup === "power"

                    onClicked: {
                        if (GlobalStates.activeBarPopup === "power") {
                            GlobalStates.activeBarPopup = ""
                        } else {
                            const pos = this.mapToItem(null, 0, this.height / 2)
                            GlobalStates.barPopupY = pos.y
                            GlobalStates.activeBarPopup = "power"
                        }
                    }

                    contentItem: Item {
                        MaterialSymbol {
                            anchors.centerIn: parent
                            horizontalAlignment: Qt.AlignHCenter
                            verticalAlignment: Qt.AlignVCenter
                            text: "power_settings_new"
                            iconSize: Appearance.font.pixelSize.larger
                            color: Appearance.m3colors.m3error
                        }
                    }
                }
            }
        }
    }
}
