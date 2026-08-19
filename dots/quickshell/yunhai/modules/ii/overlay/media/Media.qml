import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.ii.overlay

StyledOverlayWidget {
    id: root
    title: Translation.tr("Media")
    minimumWidth: 350
    minimumHeight: 150
    allowOffscreen: true

    contentItem: MediaContent {
        radius: root.contentRadius
    }
}
