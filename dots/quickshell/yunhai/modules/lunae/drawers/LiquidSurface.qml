pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.lunae
import qs.modules.lunae.widgets

ShaderEffect {
    id: root

    required property Item panels
    required property real barWidth
    required property bool barVisible
    property real barProgress: 1
    property real barDeformX: 1
    property real barDeformY: 1

    readonly property real ap: LunaeAppearance.rounding.armpit
    readonly property real rLarge: LunaeAppearance.rounding.panelLarge
    readonly property real rSmall: LunaeAppearance.rounding.panelSmall
    readonly property bool frameOn: Config.options.screen.fakeScreenRounding === 3
    readonly property bool flushBarBody: Config.options.bar.barBackgroundStyle === 1

    function bodyGeo(p, li, ti, ri, bi) {
        if (!p.visible)
            return Qt.vector4d(0, 0, 0, 0)
        const hw = (p.width - li - ri) / 2
        const hh = (p.height - ti - bi) / 2
        if (hw <= 0 || hh <= 0)
            return Qt.vector4d(0, 0, 0, 0)
        return Qt.vector4d(p.x + li + hw, p.y + ti + hh, hw, hh)
    }

    function corners(g, tr, br, bl, tl) {
        const m = Math.min(g.z, g.w)
        return Qt.vector4d(Math.min(tr, m), Math.min(br, m), Math.min(bl, m), Math.min(tl, m))
    }

    property vector2d size: Qt.vector2d(width, height)
    property real k: ap
    property real chromeMode: frameOn && barVisible ? 1 : 0
    property real frameThickness: Config.options.screen.wrappedFrameThickness
    property real frameRadius: Appearance.rounding.screenRounding
    property color fillColor: Appearance.colors.colLayer0
    property color shadowColor: Qt.alpha(Appearance.colors.colShadow, Config.options.bar?.panelShadow !== false ? 0.7 : 0)
    property real shadowSoftness: 8

    property real hugT: panels.barPopupPanel.hugBottom ? 1 : 0
    Behavior on hugT {
        LunaeAnim {}
    }

    property vector4d s0g: barProgress > 0.004 && (frameOn || flushBarBody)
        ? Qt.vector4d(barWidth * barProgress - barWidth / 2, height / 2, barWidth / 2, height / 2)
        : Qt.vector4d(0, 0, 0, 0)
    property vector4d s0r: Qt.vector4d(0, 0, 0, 0)

    property vector4d s1g: bodyGeo(panels.hubPanel, ap, 0, ap, 0)
    property vector4d s1r: corners(s1g, 0, rLarge, rLarge, 0)

    property vector4d s2g: {
        const p = panels.barPopupPanel
        return bodyGeo({ visible: p.visible, x: p.bodyX, y: p.y, width: p.bodyWidth, height: p.height },
            0, ap, p.hugSize * hugT, ap * (1 - hugT))
    }
    property vector4d s2r: corners(s2g, rSmall, rSmall * (1 - hugT), 0, 0)

    property vector4d s3g: bodyGeo(panels.notifPanel, ap, 0, 0, ap)
    property vector4d s3r: corners(s3g, 0, 0, rSmall, 0)

    property vector4d s4g: panels.splitMode
        ? bodyGeo(panels.sidebarNotifSplitPanel, ap, 0, 0, ap)
        : bodyGeo(panels.sidebarPanel, ap, 0, 0, 0)
    property vector4d s4r: panels.splitMode ? corners(s4g, 0, 0, rSmall, 0) : Qt.vector4d(0, 0, 0, 0)

    property vector4d s5g: bodyGeo(panels.sidebarToggleSplitPanel, ap, ap, 0, 0)
    property vector4d s5r: corners(s5g, 0, 0, 0, rSmall)

    property vector4d s6g: panels.wallpaperPanel.visible
        ? bodyGeo(panels.wallpaperPanel, ap, 0, ap, 0)
        : bodyGeo(panels.searchPanel, ap, 0, ap, 0)
    property vector4d s6r: corners(s6g, rLarge, 0, 0, rLarge)

    property vector4d s7g: panels.osdRightPanel.visible
        ? bodyGeo(panels.osdRightPanel, 0, ap, 0, ap)
        : bodyGeo(panels.osdTopPanel, ap, 0, ap, 0)
    property vector4d s7r: panels.osdRightPanel.visible
        ? corners(s7g, 0, 0, rLarge, rLarge)
        : corners(s7g, 0, rLarge, rLarge, 0)

    property vector4d d01: Qt.vector4d(barDeformX, barDeformY, panels.hubPanel.deformX, panels.hubPanel.deformY)
    property vector4d d23: Qt.vector4d(
        panels.barPopupPanel.deformX, panels.barPopupPanel.deformY,
        panels.notifPanel.deformX, panels.notifPanel.deformY)
    property vector4d d45: panels.splitMode
        ? Qt.vector4d(
            panels.sidebarNotifSplitPanel.deformX, panels.sidebarNotifSplitPanel.deformY,
            panels.sidebarToggleSplitPanel.deformX, panels.sidebarToggleSplitPanel.deformY)
        : Qt.vector4d(
            panels.sidebarPanel.deformX, panels.sidebarPanel.deformY,
            panels.sidebarToggleSplitPanel.deformX, panels.sidebarToggleSplitPanel.deformY)
    property vector4d d67: Qt.vector4d(
        panels.wallpaperPanel.visible ? panels.wallpaperPanel.deformX : panels.searchPanel.deformX,
        panels.wallpaperPanel.visible ? panels.wallpaperPanel.deformY : panels.searchPanel.deformY,
        1, 1)

    fragmentShader: Quickshell.shellPath("assets/shaders/lunae/surface.frag.qsb")
}
