import Quickshell

import qs.modules.common

import qs.modules.lunae.background
import qs.modules.ii.lock
import qs.modules.lunae.onScreenDisplay
import qs.modules.ii.overlay
import qs.modules.lunae.drawers
import qs.modules.ii.sidebarLeft

import qs.modules.ii.cheatsheet
import qs.modules.ii.mediaControls
import qs.modules.ii.onScreenKeyboard
import qs.modules.lunae.polkit
import qs.modules.lunae.screenSnip
import qs.modules.ii.screenCorners
import qs.modules.ii.screenTranslator
import qs.modules.ii.sessionScreen
import qs.modules.lunae.wallpaperSelector

Scope {
    PanelLoader { component: Background {} }
    PanelLoader { component: Cheatsheet {} }
    PanelLoader { component: Drawers {} }
    PanelLoader { component: Lock {} }
    PanelLoader { component: MediaControls {} }
    PanelLoader { component: OnScreenDisplay {} }
    PanelLoader { component: OnScreenKeyboard {} }
    PanelLoader { component: Overlay {} }
    PanelLoader { component: Polkit {} }
    PanelLoader { component: LScreenSnip {} }
    PanelLoader { component: ScreenCorners {} }
    PanelLoader { component: ScreenTranslator {} }
    PanelLoader { component: SessionScreen {} }
    PanelLoader { component: SidebarLeft {} }
    PanelLoader { component: WallpaperSelector {} }
}

// i need to do a major cleanup of useless files + readjust calls, (e.g, why verticalBar calls from bar if bar doesnt exist in this panel family? need to bring everything in verticalBar)
