#!/usr/bin/env bash
# usage: hyprbars.sh load|style|layout|reload|disable|unload [font] [glyphs|semaphore] [muted|accent|mac] [height] [text size] [button size]

set -uo pipefail

GENERATED="$HOME/.local/state/quickshell/yunhai/user/generated"
COLORS="$GENERATED/colors.json"
LAYOUTFILE="$GENERATED/hyprbars.lua"
DEFAULT_BAR_COLOR=2285056819
TRANSPARENT='rgba(00000000)'
FG=
FONT="${2:-}"
STYLE="${3:-semaphore}"
BTNCOL="${4:-muted}"
HEIGHT="${5:-34}"
TEXTSIZE="${6:-16}"
SIZE="${7:-15}"

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/akebono-hyprbars.lock"
flock 9

so_path() {
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
    local bar text
    bar="$(col term0 131313)"; FG="$bar"
    text="$(col on_surface e2e2e2)"
    hyprctl eval "hl.config({ plugin = { hyprbars = { enabled = true, bar_color = '$bar', col = { text = '$text' } } } })" >/dev/null

    local ec tc pc
    case "$BTNCOL" in
        mac) ec='rgb(ff5f57)'; tc='rgb(febc2e)'; pc='rgb(28c840)' ;;
        accent) ec="$(col error ffb4ab)"; tc="$(col tertiary ffb787)"; pc="$(col primary ffb0cb)" ;;
        *) ec="$(col error ffb4ab)"; tc="$(col outline 919191)"; pc="$tc" ;;
    esac
    if [ "$STYLE" = glyphs ]; then
        FG="$ec"; add_btn "$TRANSPARENT" '󰖭' "hl.dsp.window.close()"
        FG="$pc"; add_btn "$TRANSPARENT" '󰖯' "hl.dsp.window.float({ action = 'toggle' })"
        FG="$tc"; add_btn "$TRANSPARENT" '󰖰' "" "bash \"$MINSCRIPT\""
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

write_layout() {
    [ -n "$FONT" ] || return 1
    local layout
    layout="return { bar_text_font = [[$FONT]], bar_height = $HEIGHT, bar_text_size = $TEXTSIZE }"
    [ "$(cat "$LAYOUTFILE" 2>/dev/null)" = "$layout" ] && return 1
    mkdir -p "$GENERATED"
    printf '%s\n' "$layout" >"$LAYOUTFILE.tmp" && mv "$LAYOUTFILE.tmp" "$LAYOUTFILE"
}

case "${1:-}" in
    load)
        if ! loaded; then
            so="$(so_path)"
            [ -z "$so" ] && { echo "hyprbars.so not found; run: sudo hyprpm add https://github.com/hyprwm/hyprland-plugins" >&2; exit 1; }
            write_layout
            hyprctl plugin load "$so" >/dev/null
            hyprctl reload >/dev/null
        elif write_layout; then
            hyprctl reload >/dev/null
        else
            hyprctl eval "hl.config({ plugin = { hyprbars = { enabled = true } } })" >/dev/null
            restyle
        fi
        ;;
    style)
        restyle ;;
    layout)
        loaded && { write_layout; hyprctl reload >/dev/null; } ;;
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
        echo "usage: ${0##*/} load|style|layout|reload|disable|unload [font] [glyphs|semaphore] [muted|accent|mac] [height] [text size] [button size]" >&2; exit 2 ;;
esac
