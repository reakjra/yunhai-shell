import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.widgets

SidebarNavChrome {
    pageRightMargin: SettingsStyle.groupedPageMargin

    header: StyledText {
        leftPadding: 12
        topPadding: 6
        bottomPadding: 6
        text: Translation.tr("Control panel")
        font.pixelSize: Appearance.font.pixelSize.title
        font.weight: Font.DemiBold
        color: Appearance.colors.colOnLayer1
        elide: Text.ElideRight
    }
}
