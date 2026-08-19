import Quickshell

import qs.modules.akebono
import qs.modules.akebono.dock
import qs.modules.akebono.overview
import qs.modules.ii.background
import qs.modules.ii.cheatsheet
import qs.modules.akebono.shelf
import qs.modules.akebono.lock
import qs.modules.ii.mediaControls
import qs.modules.ii.notificationPopup
import qs.modules.akebono.onScreenDisplay
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.polkit
import qs.modules.lunae.screenSnip
import qs.modules.akebono.runner
import qs.modules.ii.screenTranslator
import qs.modules.ii.screenCorners
import qs.modules.akebono.sessionScreen
import qs.modules.ii.sidebarLeft
import qs.modules.ii.overlay
import qs.modules.ii.wallpaperSelector
import qs.modules.ii.wrappedFrame

Scope {
    PanelLoader { component: Background {} }
    PanelLoader { component: Cheatsheet {} }
    PanelLoader { component: Dock {} }
    PanelLoader { component: Overview {} }
    PanelLoader { component: Shelf {} }
    PanelLoader { component: Lock {} }
    PanelLoader { component: MediaControls {} }
    PanelLoader { component: NotificationPopup {} }
    PanelLoader { component: OnScreenDisplay {} }
    PanelLoader { component: OnScreenKeyboard {} }
    PanelLoader { component: Overlay {} }
    PanelLoader { component: Polkit {} }
    PanelLoader { component: LScreenSnip { activeFamily: "akebono" } }
    PanelLoader { component: GlyphPicker {} }
    PanelLoader { component: Runner {} }
    PanelLoader { component: SheetRunner {} }
    PanelLoader { component: ScreenCorners {} }
    PanelLoader { component: ScreenTranslator {} }
    PanelLoader { component: SessionScreen {} }
    PanelLoader { component: SidebarLeft {} }
    PanelLoader { component: WallpaperSelector {} }
    PanelLoader { component: WrappedFrame {} }
}
