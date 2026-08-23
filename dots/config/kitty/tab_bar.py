from kitty.tab_bar import as_rgb, draw_title
from kitty.utils import color_as_int

LEFT_CAP = ""
RIGHT_CAP = ""


def _rgb(color):
    return as_rgb(color_as_int(color))


def draw_tab(draw_data, screen, tab, before, max_title_length, index, is_last, extra_data):
    pill = draw_data.active_bg if tab.is_active else draw_data.inactive_bg
    text = draw_data.active_fg if tab.is_active else draw_data.inactive_fg
    bar = draw_data.default_bg

    screen.cursor.bg = _rgb(bar)
    screen.cursor.fg = _rgb(pill)
    screen.draw(LEFT_CAP)

    screen.cursor.bg = _rgb(pill)
    screen.cursor.fg = _rgb(text)
    screen.cursor.bold = tab.is_active
    draw_title(draw_data, screen, tab, index, max_title_length - 3)
    screen.cursor.bold = False

    screen.cursor.bg = _rgb(bar)
    screen.cursor.fg = _rgb(pill)
    screen.draw(RIGHT_CAP)

    screen.cursor.fg = _rgb(bar)
    screen.draw(" ")

    return screen.cursor.x
