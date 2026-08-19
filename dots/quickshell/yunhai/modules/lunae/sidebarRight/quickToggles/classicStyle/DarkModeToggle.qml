import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Quickshell

QuickToggleButton {
    id: root
    toggled: Appearance.m3colors.darkmode
    buttonIcon: "contrast"

    altAction: () => {}

    onClicked: {
        MaterialThemeLoader.switchDarkLightMode(!Appearance.m3colors.darkmode);
    }

    StyledToolTip {
        text: Translation.tr("Dark mode")
    }
}
