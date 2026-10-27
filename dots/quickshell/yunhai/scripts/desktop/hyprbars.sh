#!/usr/bin/env bash
# usage: hyprbars.sh load|apply|disable|unload [font] [glyphs|semaphore] [muted|accent|mac] [height] [text size] [button size] [bar color]

set -uo pipefail

GENERATED="$HOME/.local/state/quickshell/yunhai/user/generated"
CONFIGFILE="$GENERATED/hyprbars.lua"
FONT="${2:-}"
STYLE="${3:-semaphore}"
BTNCOL="${4:-muted}"
HEIGHT="${5:-34}"
TEXTSIZE="${6:-16}"
SIZE="${7:-15}"
BARCOL="${8:-term0}"

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/akebono-hyprbars.lock"
flock 9

so_path() {
    find "$HOME/.local/share/hyprpm" "/var/cache/hyprpm/$USER" -name 'hyprbars.so' 2>/dev/null | head -1
}
loaded()  { hyprctl plugins list 2>/dev/null | grep -qiF hyprbars; }

MINSCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/minimize-active.sh"

write_config() {
    [ -n "$FONT" ] || return 1
    local config
    config="return { bar_text_font = [[$FONT]], bar_height = $HEIGHT, bar_text_size = $TEXTSIZE, bar_color = [[$BARCOL]], buttons = { style = [[$STYLE]], colors = [[$BTNCOL]], size = $SIZE, minimize = [[$MINSCRIPT]] } }"
    [ "$(cat "$CONFIGFILE" 2>/dev/null)" = "$config" ] && return 1
    mkdir -p "$GENERATED"
    printf '%s\n' "$config" >"$CONFIGFILE.tmp" && mv "$CONFIGFILE.tmp" "$CONFIGFILE"
}

case "${1:-}" in
    load)
        if ! loaded; then
            so="$(so_path)"
            [ -z "$so" ] && { echo "hyprbars.so not found; run: sudo hyprpm add https://github.com/hyprwm/hyprland-plugins" >&2; exit 1; }
            hyprctl plugin load "$so" >/dev/null
        fi
        write_config
        hyprctl reload >/dev/null
        ;;
    apply)
        loaded && write_config && hyprctl reload >/dev/null ;;
    disable)
        loaded && hyprctl eval "hl.config({ plugin = { hyprbars = { enabled = false } } })" >/dev/null
        ;;
    unload)
        so="$(so_path)"
        [ -n "$so" ] && hyprctl plugin unload "$so" >/dev/null 2>&1
        ;;
    *)
        echo "usage: ${0##*/} load|apply|disable|unload [font] [glyphs|semaphore] [muted|accent|mac] [height] [text size] [button size] [bar color]" >&2; exit 2 ;;
esac
