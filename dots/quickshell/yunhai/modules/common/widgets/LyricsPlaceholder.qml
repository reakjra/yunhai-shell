import QtQuick
import qs.services
import qs.modules.common

StyledText {
    visible: !LyricsService.hasLyrics
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.WordWrap
    text: LyricsService.loading ? Translation.tr("Finding lyrics…") : (LyricsService.instrumental ? Translation.tr("♪ Instrumental") : Translation.tr("No lyrics found"))
    font.pixelSize: Appearance.font.pixelSize.normal
    color: Appearance.colors.colSubtext
}
