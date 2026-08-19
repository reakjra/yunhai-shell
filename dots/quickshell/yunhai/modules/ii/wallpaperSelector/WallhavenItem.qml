import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

MouseArea {
    id: root
    property string thumbUrl
    property string fullUrl
    property string wallId
    property string resolution
    property string ratio
    property int views
    property int favorites
    property bool isDownloading: false
    property bool showActions: false

    property alias colBackground: background.color
    property alias colText: infoText.color
    property alias radius: background.radius
    property alias margins: background.anchors.margins
    margins: Appearance.sizes.wallpaperSelectorItemMargins

    signal activated()

    hoverEnabled: true
    onClicked: root.activated()

    Rectangle {
        id: background
        anchors.fill: parent
        radius: Appearance.rounding.normal
        Behavior on color {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }

        ColumnLayout {
            id: contentLayout
            anchors {
                fill: parent
                margins: Appearance.sizes.wallpaperSelectorItemPadding
            }
            spacing: 4

            Item {
                id: imageContainer
                Layout.fillHeight: true
                Layout.fillWidth: true

                Image {
                    id: thumbImage
                    anchors.fill: parent
                    source: root.thumbUrl
                    fillMode: Image.PreserveAspectCrop
                    clip: true
                    cache: true
                    asynchronous: true

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: imageContainer.width
                            height: imageContainer.height
                            radius: Appearance.rounding.small
                        }
                    }
                }

                Loader {
                    active: thumbImage.status === Image.Loading
                    anchors.centerIn: parent
                    sourceComponent: MaterialLoadingIndicator {}
                }

                // Download overlay
                Rectangle {
                    visible: root.isDownloading
                    anchors.fill: parent
                    radius: Appearance.rounding.small
                    color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.4)
                    MaterialLoadingIndicator {
                        anchors.centerIn: parent
                    }
                }

                // Three-dot menu
                RippleButton {
                    id: menuButton
                    anchors.top: parent.top
                    anchors.right: parent.right
                    property real buttonSize: 30
                    anchors.margins: Math.max(Appearance.rounding.small - buttonSize / 2, 8)
                    implicitHeight: buttonSize
                    implicitWidth: buttonSize
                    visible: root.containsMouse || root.showActions
                    z: 1

                    buttonRadius: Appearance.rounding.full
                    colBackground: ColorUtils.transparentize(Appearance.m3colors.m3surface, 0.3)
                    colBackgroundHover: ColorUtils.transparentize(ColorUtils.mix(Appearance.m3colors.m3surface, Appearance.m3colors.m3onSurface, 0.8), 0.2)
                    colRipple: ColorUtils.transparentize(ColorUtils.mix(Appearance.m3colors.m3surface, Appearance.m3colors.m3onSurface, 0.6), 0.1)

                    contentItem: MaterialSymbol {
                        horizontalAlignment: Text.AlignHCenter
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.m3colors.m3onSurface
                        text: "more_vert"
                    }

                    onClicked: root.showActions = !root.showActions
                }

                Loader {
                    id: contextMenuLoader
                    active: root.showActions
                    anchors.top: menuButton.bottom
                    anchors.right: parent.right
                    anchors.margins: 8
                    z: 2

                    sourceComponent: Item {
                        width: contextMenu.width
                        height: contextMenu.height

                        StyledRectangularShadow {
                            target: contextMenu
                        }
                        Rectangle {
                            id: contextMenu
                            anchors.centerIn: parent
                            opacity: root.showActions ? 1 : 0
                            visible: opacity > 0
                            radius: Appearance.rounding.small
                            color: Appearance.m3colors.m3surfaceContainer
                            implicitHeight: contextMenuColumn.implicitHeight + radius * 2
                            implicitWidth: contextMenuColumn.implicitWidth

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Appearance.animation.elementMoveFast.duration
                                    easing.type: Appearance.animation.elementMoveFast.type
                                    easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                                }
                            }

                            ColumnLayout {
                                id: contextMenuColumn
                                anchors.centerIn: parent
                                spacing: 0

                                MenuButton {
                                    Layout.fillWidth: true
                                    buttonText: Translation.tr("Download")
                                    onClicked: {
                                        root.showActions = false
                                        Wallhaven.downloadWallpaper(root.fullUrl, root.wallId, false)
                                    }
                                }
                                MenuButton {
                                    Layout.fillWidth: true
                                    buttonText: Translation.tr("Download & Apply")
                                    onClicked: {
                                        root.showActions = false
                                        Wallhaven.downloadWallpaper(root.fullUrl, root.wallId, true)
                                    }
                                }
                            }
                        }
                    }
                }

                // Fav count badge
                Rectangle {
                    visible: root.favorites > 0
                    anchors {
                        bottom: parent.bottom
                        right: parent.right
                        margins: 6
                    }
                    width: favRow.implicitWidth + 10
                    height: favRow.implicitHeight + 4
                    radius: Appearance.rounding.full
                    color: ColorUtils.transparentize(Appearance.m3colors.m3surfaceContainer, 0.3)

                    Row {
                        id: favRow
                        anchors.centerIn: parent
                        spacing: 2
                        MaterialSymbol {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "favorite"
                            iconSize: Appearance.font.pixelSize.smaller
                            fill: 1
                            color: Appearance.colors.colError
                        }
                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.favorites
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer0
                        }
                    }
                }
            }

            StyledText {
                id: infoText
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Appearance.font.pixelSize.smaller
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                text: root.ratio ? `${root.resolution} · ${root.ratio}` : root.resolution
            }
        }
    }
}
