import qs.services
import qs.modules.common

QuickToggleModel {
    name: Translation.tr("Game mode")
    icon: "gamepad"
    toggled: GameMode.active
    mainAction: () => GameMode.toggle()
    hasMenu: true
    tooltipText: Translation.tr("Game mode | Right-click to configure")
}
