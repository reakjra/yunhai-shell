pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.akebono
import qs.modules.akebono.desktop.widgets

DesktopWidgetBase {
    id: root
    themeRadius: 28
    readonly property string imgSource: widgetData.source ?? ""

    onImgSourceChanged: {
        gifLoader.sourceComponent = null;
        gifLoader.sourceComponent = gifComponent;
    }

    backdropVisible: root.imgSource !== ""
    backdrop: Loader {
        id: gifLoader
        anchors.fill: parent
        active: root.imgSource !== ""
        sourceComponent: gifComponent
    }

    Component {
        id: gifComponent
        AnimatedImage {
            anchors.fill: parent
            source: root.imgSource
            fillMode: AnimatedImage.PreserveAspectCrop
            asynchronous: true
            cache: false
            playing: true
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        visible: !root.backdropVisible
        spacing: 4
        MaterialSymbol {
            Layout.alignment: Qt.AlignHCenter
            text: "add_photo_alternate"
            iconSize: 38
            color: Appearance.colors.colSubtext
        }
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: "Drop an image"
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }
    }
}
