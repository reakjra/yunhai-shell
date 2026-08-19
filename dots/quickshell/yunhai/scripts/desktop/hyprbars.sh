#!/usr/bin/env bash
# usage: hyprbars.sh load|style|font|disable|unload [font]

set -uo pipefail

COLORS="$HOME/.local/state/quickshell/yunhai/user/generated/colors.json"
DEFAULT_BAR_COLOR=2285056819
FG=
FONT="${2:-}"
STYLE="${3:-semaphore}"
BTNCOL="${4:-themed}"
SIZE=15

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/akebono-hyprbars.lock"
flock 9

so_path() {
    [ -f "$HOME/.local/share/hyprbars/hyprbars.so" ] && { echo "$HOME/.local/share/hyprbars/hyprbars.so"; return; }
    find "$HOME/.local/share/hyprpm" "/var/cache/hyprpm/$USER" -name 'hyprbars.so' 2>/dev/null | head -1
}
loaded()  { hyprctl plugins list 2>/dev/null | grep -qiF hyprbars; }

col() {
    local hex
    hex="$(jq -r --arg k "$1" '.[$k] // empty' "$COLORS" 2>/dev/null)"
    [ -z "$hex" ] && hex="$2"
    printf 'rgb(%s)' "${hex#\#}"
}

MINSCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/minimize-active.sh"

add_btn() {
    local action="hyprctl dispatch \"$3\""
    [ -n "${4:-}" ] && action="$4"
    hyprctl eval "hl.plugin.hyprbars.add_button({ bg_color = '$1', fg_color = '$FG', size = $SIZE, icon = '$2', action = [[$action]] })" >/dev/null
}

style() {
    loaded || return 0
    local bar text font_opt=
    bar="$(col surface 131313)"; FG="$bar"
    text="$(col on_surface e2e2e2)"
    [ -n "$FONT" ] && font_opt=", bar_text_font = '$FONT'"
    hyprctl eval "hl.config({ plugin = { hyprbars = { enabled = true, bar_color = '$bar', col = { text = '$text' }$font_opt } } })" >/dev/null

    local ec tc pc
    if [ "$BTNCOL" = mac ]; then
        ec='rgb(ff5f57)'; tc='rgb(febc2e)'; pc='rgb(28c840)'
    else
        ec="$(col error ffb4ab)"; tc="$(col tertiary ffb787)"; pc="$(col primary ffb0cb)"
    fi
    if [ "$STYLE" = glyphs ]; then
        SIZE=28
        FG="$ec"; add_btn "$bar" '󰖭' "hl.dsp.window.close()"
        FG="$pc"; add_btn "$bar" '󰖯' "hl.dsp.window.float({ action = 'toggle' })"
        FG="$tc"; add_btn "$bar" '󰖰' "" "bash \"$MINSCRIPT\""
    else
        add_btn "$ec" '' "hl.dsp.window.close()"
        add_btn "$pc" '' "hl.dsp.window.float({ action = 'toggle' })"
        add_btn "$tc" '' "" "bash \"$MINSCRIPT\""
    fi
}

restyle() {
    [ "$(hyprctl -j getoption plugin:hyprbars:bar_color 2>/dev/null | jq -r '.int // empty')" = "$DEFAULT_BAR_COLOR" ] || return 0
    style
}

set_font() {
    loaded && [ -n "$FONT" ] && hyprctl eval "hl.config({ plugin = { hyprbars = { bar_text_font = '$FONT' } } })" >/dev/null
}

case "${1:-}" in
    load)
        if loaded; then
            hyprctl eval "hl.config({ plugin = { hyprbars = { enabled = true } } })" >/dev/null
            restyle
            set_font
        else
            so="$(so_path)"
            [ -z "$so" ] && { echo "hyprbars.so not found; run: sudo hyprpm add https://github.com/hyprwm/hyprland-plugins" >&2; exit 1; }
            hyprctl plugin load "$so" >/dev/null
            hyprctl reload >/dev/null
        fi
        ;;
    style)
        restyle ;;
    font)
        set_font ;;
    disable)
        loaded && hyprctl eval "hl.config({ plugin = { hyprbars = { enabled = false } } })" >/dev/null
        ;;
    reload)
        loaded && hyprctl reload >/dev/null
        ;;
    unload)
        so="$(so_path)"
        [ -n "$so" ] && hyprctl plugin unload "$so" >/dev/null 2>&1
        ;;
    *)
        echo "usage: ${0##*/} load|style|font|disable|unload [font]" >&2; exit 2 ;;
esac
