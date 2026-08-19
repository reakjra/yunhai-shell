#!/usr/bin/env bash

QUICKSHELL_CONFIG_NAME="yunhai"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell/yunhai"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_CONFIG_FILE="$XDG_CONFIG_HOME/yunhai/global.json"
MATUGEN_DIR="$XDG_CONFIG_HOME/matugen"
terminalscheme="$SCRIPT_DIR/terminal/scheme-base.json"

handle_kde_material_you_colors() {
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        enable_qt_apps=$(jq -r '.appearance.wallpaperTheming.enableQtApps' "$SHELL_CONFIG_FILE")
        if [ "$enable_qt_apps" == "false" ]; then
            return
        fi
    fi

    # Map $type_flag to allowed scheme variants for kde-material-you-colors-wrapper.sh
    local kde_scheme_variant=""
    case "$type_flag" in
        scheme-content|scheme-expressive|scheme-fidelity|scheme-fruit-salad|scheme-monochrome|scheme-neutral|scheme-rainbow|scheme-tonal-spot)
            kde_scheme_variant="$type_flag"
            ;;
        *)
            kde_scheme_variant="scheme-tonal-spot" # default
            ;;
    esac
    "$XDG_CONFIG_HOME"/matugen/templates/kde/kde-material-you-colors-wrapper.sh --scheme-variant "$kde_scheme_variant"
}

pre_process() {
    local mode_flag="$1"
    if [[ "$mode_flag" == "dark" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    elif [[ "$mode_flag" == "light" ]]; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-light'
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3'
    fi

    if [ ! -d "$CACHE_DIR"/user/generated ]; then
        mkdir -p "$CACHE_DIR"/user/generated
    fi
}

post_process() {
    local screen_width="$1"
    local screen_height="$2"
    local wallpaper_path="$3"

    # Save non-color sections from kdeglobals before kde-material-you-colors
    # rewrites the file (it replaces the entire file, losing fonts/styles/etc.)
    local kdeglobals_preserve=""
    if [ -f "$HOME/.config/kdeglobals" ]; then
        kdeglobals_preserve=$(python3 -c "
import re
with open('$HOME/.config/kdeglobals') as f:
    lines = f.readlines()
# Sections kde-material-you-colors manages (will be regenerated)
color_sections = {'ColorEffects:Disabled','ColorEffects:Inactive',
    'Colors:Button','Colors:Complementary','Colors:Header','Colors:Header][Inactive',
    'Colors:Selection','Colors:Tooltip','Colors:View','Colors:Window','Icons'}
# Keys in [General] that kde-material-you-colors manages
managed_general = {'ColorScheme','ColorSchemeHash'}
# Keys in [WM] that kde-material-you-colors manages (color-related)
managed_wm = {'activeBackground','activeBlend','activeForeground',
    'inactiveBackground','inactiveBlend','inactiveForeground'}
section = ''
preserved = []
for line in lines:
    m = re.match(r'^\[(.+)\]$', line.strip())
    if m:
        section = m.group(1)
        if section not in color_sections:
            preserved.append(line)
    elif section in color_sections:
        continue  # skip color section contents
    elif section == 'General' and '=' in line:
        k = line.split('=',1)[0]
        if k not in managed_general:
            preserved.append(line)
    elif section == 'WM' and '=' in line:
        k = line.split('=',1)[0]
        if k not in managed_wm:
            preserved.append(line)
    else:
        preserved.append(line)
print(''.join(preserved), end='')
" 2>/dev/null)
    fi

    handle_kde_material_you_colors &
    local kde_pid=$!
    "$SCRIPT_DIR/code/material-code-set-color.sh" &
    local code_pid=$!

    # Wait for kde-material-you-colors to finish before merging KDE colors into colors.json
    wait $kde_pid 2>/dev/null

    # Restore preserved non-color settings that kde-material-you-colors wiped
    if [ -n "$kdeglobals_preserve" ] && [ -f "$HOME/.config/kdeglobals" ]; then
        python3 -c "
import re, sys
# Parse the new kdeglobals (color data from kde-material-you-colors)
with open('$HOME/.config/kdeglobals') as f:
    new_content = f.read()
# Parse preserved non-color settings
preserved = sys.stdin.read()
# Merge: start with new content, then inject preserved settings
# into their matching sections (or append new sections)
def parse_sections(text):
    sections = {}
    order = []
    section = ''
    for line in text.splitlines(keepends=True):
        m = re.match(r'^\[(.+)\]$', line.strip())
        if m:
            section = m.group(1)
            if section not in sections:
                sections[section] = []
                order.append(section)
        elif section:
            sections[section].append(line)
    return sections, order
new_secs, new_order = parse_sections(new_content)
pres_secs, pres_order = parse_sections(preserved)
# For each preserved section, merge keys into new content
for sec in pres_order:
    if sec in new_secs:
        # Section exists in new: add missing keys
        existing_keys = set()
        for line in new_secs[sec]:
            if '=' in line:
                existing_keys.add(line.split('=',1)[0])
        for line in pres_secs[sec]:
            if '=' in line:
                k = line.split('=',1)[0]
                if k not in existing_keys:
                    new_secs[sec].append(line)
    else:
        # Section missing from new: add entire section
        new_secs[sec] = pres_secs[sec]
        new_order.append(sec)
out = []
for sec in new_order:
    out.append(f'[{sec}]\n')
    out.extend(new_secs[sec])
    if out and not out[-1].endswith('\n'):
        out.append('\n')
    out.append('\n')
with open('$HOME/.config/kdeglobals', 'w') as f:
    f.writelines(out)
" <<< "$kdeglobals_preserve" 2>/dev/null
    fi
    python3 -c "
import re, json, sys
kdeglobals_path = '$HOME/.config/kdeglobals'
json_path = '$STATE_DIR/user/generated/colors.json'
try:
    sections = {}
    section = ''
    with open(kdeglobals_path) as f:
        for line in f:
            line = line.strip()
            m = re.match(r'^\[(.+)\]\$', line)
            if m:
                section = m.group(1)
                sections.setdefault(section, {})
            elif '=' in line and section:
                k, v = line.split('=', 1)
                sections[section][k] = v
    def to_hex(val):
        val = val.strip()
        if val.startswith('#'):
            return val
        parts = val.split(',')
        if len(parts) == 3:
            return '#{:02x}{:02x}{:02x}'.format(int(parts[0]), int(parts[1]), int(parts[2]))
        return val
    def get(sec, key):
        return to_hex(sections.get(sec, {}).get(key, ''))
    kde_colors = {
        'kdeViewBg': get('Colors:View', 'BackgroundNormal'),
        'kdeViewAltBg': get('Colors:View', 'BackgroundAlternate'),
        'kdeWindowBg': get('Colors:Window', 'BackgroundNormal'),
        'kdeWindowAltBg': get('Colors:Window', 'BackgroundAlternate'),
        'kdeButtonBg': get('Colors:Button', 'BackgroundNormal'),
        'kdeButtonAltBg': get('Colors:Button', 'BackgroundAlternate'),
        'kdeSelectionBg': get('Colors:Selection', 'BackgroundNormal'),
        'kdeSelectionText': get('Colors:Selection', 'ForegroundNormal'),
        'kdeTitlebarBg': get('WM', 'activeBackground'),
        'kdeTitlebarText': get('WM', 'activeForeground'),
        'kdeInactiveTitlebarBg': get('WM', 'inactiveBackground'),
        'kdeInactiveTitlebarText': get('WM', 'inactiveForeground'),
        'kdeViewText': get('Colors:View', 'ForegroundNormal'),
        'kdeWindowText': get('Colors:Window', 'ForegroundNormal'),
        'kdeInactiveText': get('Colors:View', 'ForegroundInactive'),
        'kdeLinkText': get('Colors:View', 'ForegroundLink'),
        'kdeVisitedText': get('Colors:View', 'ForegroundVisited'),
        'kdeErrorText': get('Colors:View', 'ForegroundNegative'),
        'kdeWarningText': get('Colors:View', 'ForegroundNeutral'),
        'kdeSuccessText': get('Colors:View', 'ForegroundPositive'),
        'kdeAccent': get('General', 'AccentColor'),
        'kdeTooltipBg': get('Colors:Tooltip', 'BackgroundNormal'),
        'kdeTooltipText': get('Colors:Tooltip', 'ForegroundNormal'),
        'kdeComplementaryBg': get('Colors:Complementary', 'BackgroundNormal'),
        'kdeComplementaryText': get('Colors:Complementary', 'ForegroundNormal'),
    }
    with open(json_path) as f:
        colors = json.load(f)
    # Use Material's designed-on colors for proper contrast
    # Since kdeSelectionBg uses primary, text should use on_primary
    bg = colors.get('background', '#ffffff').lstrip('#')
    is_dark = (0.299*int(bg[0:2],16) + 0.587*int(bg[2:4],16) + 0.114*int(bg[4:6],16)) / 255 < 0.5
    if is_dark:
        kde_colors['kdeSelectionText'] = colors.get('on_primary', '#ffffff')
    else:
        kde_colors['kdeSelectionText'] = colors.get('on_primary', '#000000')
    # kde-material-you-colors doesn't write AccentColor to kdeglobals,
    # and any manually-set accent persists there as a stale value.
    # Always derive these from Material colors for consistency with wallpaper.
    kde_colors['kdeAccent'] = colors.get('primary', '')
    kde_colors['kdeSelectionBg'] = colors.get('primary', '')
    kde_colors['kdeButtonAltBg'] = colors.get('surface_container_highest', '')
    kde_colors['kdeLinkText'] = colors.get('primary', '')
    colors.update({k: v for k, v in kde_colors.items() if v})
    with open(json_path, 'w') as f:
        json.dump(colors, f, indent=2)
except Exception as e:
    print(f'Warning: could not merge KDE colors: {e}', file=sys.stderr)
"
    # Derive GTK colors from Material colors already in colors.json
    # (avoids reading gtk-3.0/gtk.css which can have wrong-mode colors)
    python3 -c "
import json, sys
json_path = '$STATE_DIR/user/generated/colors.json'
try:
    with open(json_path) as f:
        colors = json.load(f)
    mapping = {
        'gtkAccent': 'primary',
        'gtkAccentFg': 'on_primary',
        'gtkWindowBg': 'background',
        'gtkWindowFg': 'on_background',
        'gtkHeaderbarBg': 'surface_dim',
        'gtkHeaderbarFg': 'on_surface',
        'gtkViewBg': 'surface',
        'gtkViewFg': 'on_surface',
        'gtkCardBg': 'surface',
        'gtkCardFg': 'on_surface',
        'gtkPopoverBg': 'surface_dim',
        'gtkPopoverFg': 'on_surface',
    }
    gtk_colors = {}
    for gtk_key, material_key in mapping.items():
        if material_key in colors:
            gtk_colors[gtk_key] = colors[material_key]
    colors.update(gtk_colors)
    with open(json_path, 'w') as f:
        json.dump(colors, f, indent=2)
except Exception as e:
    print(f'Warning: could not derive GTK colors: {e}', file=sys.stderr)
"
    # Wait for VSCode color script to finish before returning
    wait $code_pid 2>/dev/null
}

check_and_prompt_upscale() {
    local img="$1"
    min_width_desired="$(hyprctl monitors -j | jq '([.[].width] | max)' | xargs)" # max monitor width
    min_height_desired="$(hyprctl monitors -j | jq '([.[].height] | max)' | xargs)" # max monitor height

    if command -v identify &>/dev/null && [ -f "$img" ]; then
        local img_width img_height
        if is_video "$img"; then # Not check resolution for videos, just let em pass
            img_width=$min_width_desired
            img_height=$min_height_desired
        else
            img_width=$(identify -format "%w" "$img" 2>/dev/null)
            img_height=$(identify -format "%h" "$img" 2>/dev/null)
        fi
        if [[ "$img_width" -lt "$min_width_desired" || "$img_height" -lt "$min_height_desired" ]]; then
            action=$(notify-send "Upscale?" \
                "Image resolution (${img_width}x${img_height}) is lower than screen resolution (${min_width_desired}x${min_height_desired})" \
                -A "open_upscayl=Open Upscayl"\
                -a "Wallpaper switcher")
            if [[ "$action" == "open_upscayl" ]]; then
                if command -v upscayl &>/dev/null; then
                    nohup upscayl > /dev/null 2>&1 &
                else
                    action2=$(notify-send \
                        -a "Wallpaper switcher" \
                        -c "im.error" \
                        -A "install_upscayl=Install Upscayl (Arch)" \
                        "Install Upscayl?" \
                        "yay -S upscayl-bin")
                    if [[ "$action2" == "install_upscayl" ]]; then
                        kitty -1 yay -S upscayl-bin
                        if command -v upscayl &>/dev/null; then
                            nohup upscayl > /dev/null 2>&1 &
                        fi
                    fi
                fi
            fi
        fi
    fi
}

CUSTOM_DIR="$XDG_CONFIG_HOME/hypr/custom"
RESTORE_SCRIPT_DIR="$CUSTOM_DIR/scripts"
RESTORE_SCRIPT="$RESTORE_SCRIPT_DIR/__restore_video_wallpaper.sh"
THUMBNAIL_DIR="$RESTORE_SCRIPT_DIR/mpvpaper_thumbnails"
VIDEO_OPTS="no-audio loop hwdec=auto scale=bilinear interpolation=no video-sync=display-resample panscan=1.0 video-scale-x=1.0 video-scale-y=1.0 video-align-x=0.5 video-align-y=0.5 load-scripts=no"

is_video() {
    local extension="${1##*.}"
    [[ "$extension" == "mp4" || "$extension" == "webm" || "$extension" == "mkv" || "$extension" == "avi" || "$extension" == "mov" ]] && return 0 || return 1
}

kill_existing_mpvpaper() {
    pkill -f -9 mpvpaper || true
}

create_restore_script() {
    local video_path=$1
    cat > "$RESTORE_SCRIPT.tmp" << EOF
#!/bin/bash
# Generated by switchwall.sh - Don't modify it by yourself.
# Time: $(date)

pkill -f -9 mpvpaper

for monitor in \$(hyprctl monitors -j | jq -r '.[] | .name'); do
    nohup mpvpaper -o "$VIDEO_OPTS" "\$monitor" "$video_path" >/dev/null 2>&1 &
    sleep 0.1
done
EOF
    mv "$RESTORE_SCRIPT.tmp" "$RESTORE_SCRIPT"
    chmod +x "$RESTORE_SCRIPT"
}

remove_restore() {
    cat > "$RESTORE_SCRIPT.tmp" << EOF
#!/bin/bash
# The content of this script will be generated by switchwall.sh - Don't modify it by yourself.
EOF
    mv "$RESTORE_SCRIPT.tmp" "$RESTORE_SCRIPT"
}

set_wallpaper_path() {
    local path="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        local tmpfile
        tmpfile=$(mktemp /tmp/ii-config.XXXXXX)
        jq --arg path "$path" '.background.wallpaperPath = $path' "$SHELL_CONFIG_FILE" > "$tmpfile" && mv "$tmpfile" "$SHELL_CONFIG_FILE" || rm -f "$tmpfile"
    fi
}

set_thumbnail_path() {
    local path="$1"
    if [ -f "$SHELL_CONFIG_FILE" ]; then
        local tmpfile
        tmpfile=$(mktemp /tmp/ii-config.XXXXXX)
        jq --arg path "$path" '.background.thumbnailPath = $path' "$SHELL_CONFIG_FILE" > "$tmpfile" && mv "$tmpfile" "$SHELL_CONFIG_FILE" || rm -f "$tmpfile"
    fi
}

categorize_wallpaper() {
    img_cat=$("$SCRIPT_DIR/../ai/gemini-categorize-wallpaper.sh" "$1")
    echo "$img_cat" > "$STATE_DIR/user/generated/wallpaper/category.txt"
}

switch() {
    imgpath="$1"
    mode_flag="$2"
    type_flag="$3"
    color_flag="$4"
    color="$5"
    noswitch_flag="$6"

    # Start Gemini auto-categorization if enabled
    aiStylingEnabled=$(jq -r '.background.widgets.clock.cookie.aiStyling' "$SHELL_CONFIG_FILE")
    if [[ "$aiStylingEnabled" == "true" ]]; then
        categorize_wallpaper "$imgpath" &
    fi

    read scale screenx screeny screensizey < <(hyprctl monitors -j | jq '.[] | select(.focused) | .scale, .x, .y, .height' | xargs)
    cursorposx=$(hyprctl cursorpos -j | jq '.x' 2>/dev/null) || cursorposx=960
    cursorposx=$(bc <<< "scale=0; ($cursorposx - $screenx) * $scale / 1")
    cursorposy=$(hyprctl cursorpos -j | jq '.y' 2>/dev/null) || cursorposy=540
    cursorposy=$(bc <<< "scale=0; ($cursorposy - $screeny) * $scale / 1")
    cursorposy_inverted=$((screensizey - cursorposy))

    matugen_args=(--source-color-index 0)

    if [[ "$color_flag" == "1" ]]; then
        matugen_args+=(color hex "$color")
        generate_colors_material_args=(--color "$color")
    else
        if [[ -z "$imgpath" ]]; then
            echo 'Aborted'
            exit 0
        fi

        check_and_prompt_upscale "$imgpath" &
        kill_existing_mpvpaper

        if is_video "$imgpath"; then
            mkdir -p "$THUMBNAIL_DIR"

            missing_deps=()
            if ! command -v mpvpaper &> /dev/null; then
                missing_deps+=("mpvpaper")
            fi
            if ! command -v ffmpeg &> /dev/null; then
                missing_deps+=("ffmpeg")
            fi
            if [ ${#missing_deps[@]} -gt 0 ]; then
                echo "Missing deps: ${missing_deps[*]}"
                echo "Arch: sudo pacman -S ${missing_deps[*]}"
                action=$(notify-send \
                    -a "Wallpaper switcher" \
                    -c "im.error" \
                    -A "install_arch=Install (Arch)" \
                    "Can't switch to video wallpaper" \
                    "Missing dependencies: ${missing_deps[*]}")
                if [[ "$action" == "install_arch" ]]; then
                    kitty -1 sudo pacman -S "${missing_deps[*]}"
                    if command -v mpvpaper &>/dev/null && command -v ffmpeg &>/dev/null; then
                        notify-send 'Wallpaper switcher' 'Alright, try again!' -a "Wallpaper switcher"
                    fi
                fi
                exit 0
            fi

            # Set wallpaper path (skip in --noswitch mode, path hasn't changed)
            [[ -z "$noswitch_flag" ]] && set_wallpaper_path "$imgpath"

            # Set video wallpaper
            local video_path="$imgpath"
            monitors=$(hyprctl monitors -j | jq -r '.[] | .name')
            for monitor in $monitors; do
                nohup mpvpaper -o "$VIDEO_OPTS" "$monitor" "$video_path" >/dev/null 2>&1 &
                sleep 0.1
            done

            # Extract first frame for color generation
            thumbnail="$THUMBNAIL_DIR/$(basename "$imgpath").jpg"
            ffmpeg -y -i "$imgpath" -vframes 1 "$thumbnail" 2>/dev/null

            # Set thumbnail path (skip in --noswitch mode)
            [[ -z "$noswitch_flag" ]] && set_thumbnail_path "$thumbnail"

            if [ -f "$thumbnail" ]; then
                matugen_args+=(image "$thumbnail")
                generate_colors_material_args=(--path "$thumbnail")
                create_restore_script "$video_path"
            else
                echo "Cannot create image to colorgen"
                remove_restore
                exit 1
            fi
        else
            matugen_args+=(image "$imgpath")
            generate_colors_material_args=(--path "$imgpath")
            # Update wallpaper path in config (skip in --noswitch mode, path hasn't changed)
            [[ -z "$noswitch_flag" ]] && set_wallpaper_path "$imgpath"
            remove_restore
        fi
    fi

    # Determine mode if not set
    if [[ -z "$mode_flag" ]]; then
        current_mode=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null | tr -d "'")
        if [[ "$current_mode" == "prefer-dark" ]]; then
            mode_flag="dark"
        else
            mode_flag="light"
        fi
    fi

    # enforce dark mode for terminal
    if [[ -n "$mode_flag" ]]; then
        matugen_args+=(--mode "$mode_flag")
        if [[ $(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode' "$SHELL_CONFIG_FILE") == "true" ]]; then
            generate_colors_material_args+=(--mode "dark")
        else
            generate_colors_material_args+=(--mode "$mode_flag")
        fi
    fi
    [[ -n "$type_flag" ]] && matugen_args+=(--type "$type_flag") && generate_colors_material_args+=(--scheme "$type_flag")
    generate_colors_material_args+=(--termscheme "$terminalscheme" --blend_bg_fg)
    generate_colors_material_args+=(--cache "$STATE_DIR/user/generated/color.txt")

    pre_process "$mode_flag"

    if [ -f "$SHELL_CONFIG_FILE" ]; then
        enable_apps_shell=$(jq -r '.appearance.wallpaperTheming.enableAppsAndShell' "$SHELL_CONFIG_FILE")
        if [ "$enable_apps_shell" == "false" ]; then
            echo "App and shell theming disabled, skipping matugen and color generation"
            return
        fi
    fi

    if [ -f "$SHELL_CONFIG_FILE" ]; then
        harmony=$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.harmony' "$SHELL_CONFIG_FILE")
        harmonize_threshold=$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.harmonizeThreshold' "$SHELL_CONFIG_FILE")
        term_fg_boost=$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost' "$SHELL_CONFIG_FILE")
        term_bg_tone=$(jq -r '.appearance.wallpaperTheming.terminalGenerationProps.termBgTone' "$SHELL_CONFIG_FILE")
        [[ "$harmony" != "null" && -n "$harmony" ]] && generate_colors_material_args+=(--harmony "$harmony")
        [[ "$harmonize_threshold" != "null" && -n "$harmonize_threshold" ]] && generate_colors_material_args+=(--harmonize_threshold "$harmonize_threshold")
        [[ "$term_fg_boost" != "null" && -n "$term_fg_boost" ]] && generate_colors_material_args+=(--term_fg_boost "$term_fg_boost")
        [[ "$term_bg_tone" != "null" && -n "$term_bg_tone" ]] && generate_colors_material_args+=(--term_bg_tone "$term_bg_tone")
    fi

    matugen "${matugen_args[@]}"

    # generate alternate mode M3 colors in background for preset light/dark support
    {
        alt_mode=$([[ "$mode_flag" == "dark" ]] && echo "light" || echo "dark")
        alt_args=()
        skip_next=false
        for arg in "${matugen_args[@]}"; do
            if $skip_next; then skip_next=false; continue; fi
            if [[ "$arg" == "--mode" ]]; then skip_next=true; continue; fi
            alt_args+=("$arg")
        done
        matugen -c "$MATUGEN_DIR/config_alt.toml" "${alt_args[@]}" --mode "$alt_mode" 2>/dev/null
    } &

    source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"
    python3 "$SCRIPT_DIR/generate_colors_material.py" "${generate_colors_material_args[@]}" \
        > "$STATE_DIR"/user/generated/material_colors.scss
    # Merge terminal colors into colors.json so QuickShell can pick them up
    python3 -c "
import json, re, sys
scss_path = '$STATE_DIR/user/generated/material_colors.scss'
json_path = '$STATE_DIR/user/generated/colors.json'
try:
    with open(scss_path) as f: scss = f.read()
    with open(json_path) as f: colors = json.load(f)
    for m in re.finditer(r'\\\$term(\d+): (#[0-9a-fA-F]{6});', scss):
        colors['term' + m.group(1)] = m.group(2)
    with open(json_path, 'w') as f: json.dump(colors, f, indent=2)
except Exception as e:
    print(f'Warning: could not merge terminal colors: {e}', file=sys.stderr)
"
    "$SCRIPT_DIR"/applycolor.sh
    deactivate

    max_width_desired="$(hyprctl monitors -j | jq '([.[].width] | min)' | xargs)"
    max_height_desired="$(hyprctl monitors -j | jq '([.[].height] | min)' | xargs)"
    post_process "$max_width_desired" "$max_height_desired" "$imgpath"
}

main() {
    # Kill any previous switchwall instance so rapid changes don't pile up
    SWITCHWALL_PIDFILE="/tmp/switchwall.pid"
    if [ -f "$SWITCHWALL_PIDFILE" ]; then
        prev_pid=$(cat "$SWITCHWALL_PIDFILE" 2>/dev/null)
        if [ -n "$prev_pid" ] && kill -0 "$prev_pid" 2>/dev/null; then
            pkill -P "$prev_pid" 2>/dev/null || true
            kill "$prev_pid" 2>/dev/null || true
            sleep 0.1
        fi
    fi
    echo $$ > "$SWITCHWALL_PIDFILE"
    trap 'rm -f "$SWITCHWALL_PIDFILE" /tmp/ii-config.*' EXIT

    imgpath=""
    mode_flag=""
    type_flag=""
    color_flag=""
    color=""
    noswitch_flag=""

    get_type_from_config() {
        jq -r '.appearance.palette.type' "$SHELL_CONFIG_FILE" 2>/dev/null || echo "auto"
    }
    get_accent_color_from_config() {
        jq -r '.appearance.palette.accentColor' "$SHELL_CONFIG_FILE" 2>/dev/null || echo ""
    }
    set_accent_color() {
        local color="$1"
        local tmpfile
        tmpfile=$(mktemp /tmp/ii-config.XXXXXX)
        jq --arg color "$color" '.appearance.palette.accentColor = $color' "$SHELL_CONFIG_FILE" > "$tmpfile" && mv "$tmpfile" "$SHELL_CONFIG_FILE" || rm -f "$tmpfile"
    }

    detect_scheme_type_from_image() {
        local img="$1"
        source "$(eval echo $ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate"
        "$SCRIPT_DIR"/scheme_for_image.py "$img" 2>/dev/null | tr -d '\n'
        deactivate
    }

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --mode)
                mode_flag="$2"
                shift 2
                ;;
            --type)
                type_flag="$2"
                shift 2
                ;;
            --color)
                if [[ "$2" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
                    set_accent_color "$2"
                    shift 2
                elif [[ "$2" == "clear" ]]; then
                    set_accent_color ""
                    shift 2
                else
                    set_accent_color $(hyprpicker --no-fancy)
                    shift
                fi
                ;;
            --image)
                imgpath="$2"
                shift 2
                ;;
            --noswitch)
                noswitch_flag="1"
                imgpath=$(jq -r '.background.wallpaperPath' "$SHELL_CONFIG_FILE" 2>/dev/null || echo "")
                shift
                ;;
            *)
                if [[ -z "$imgpath" ]]; then
                    imgpath="$1"
                fi
                shift
                ;;
        esac
    done

    config_color="$(get_accent_color_from_config)"
    if [[ "$config_color" =~ ^#?[A-Fa-f0-9]{6}$ ]]; then
        color_flag="1"
        color="$config_color"
    fi

    if [[ -z "$type_flag" ]]; then
        type_flag="$(get_type_from_config)"
    fi

    # Validate type_flag (allow 'auto' as well)
    allowed_types=(scheme-content scheme-expressive scheme-fidelity scheme-fruit-salad scheme-monochrome scheme-neutral scheme-rainbow scheme-tonal-spot auto)
    valid_type=0
    for t in "${allowed_types[@]}"; do
        if [[ "$type_flag" == "$t" ]]; then
            valid_type=1
            break
        fi
    done
    if [[ $valid_type -eq 0 ]]; then
        echo "[switchwall.sh] Warning: Invalid type '$type_flag', defaulting to 'auto'" >&2
        type_flag="auto"
    fi

    # Only prompt for wallpaper if not using --color and not using --noswitch and no imgpath set
    if [[ -z "$imgpath" && -z "$color_flag" && -z "$noswitch_flag" ]]; then
        cd "$(xdg-user-dir PICTURES)/Wallpapers/showcase" 2>/dev/null || cd "$(xdg-user-dir PICTURES)/Wallpapers" 2>/dev/null || cd "$(xdg-user-dir PICTURES)" || return 1
        imgpath="$(kdialog --getopenfilename . --title 'Choose wallpaper')"
    fi

    # If user provided a wallpaper (not --noswitch), clear saved accent color so wallpaper actually applies
    if [[ -n "$imgpath" && -z "$noswitch_flag" ]]; then
        set_accent_color ""
        color_flag=""
        color=""
    fi

    # Swap to a -light/-dark variant of the wallpaper if one exists for this mode
    if [[ "$mode_flag" == "dark" || "$mode_flag" == "light" ]] && [[ -n "$imgpath" ]]; then
        imgdir="$(dirname "$imgpath")"
        imgbase="$(basename "$imgpath")"
        imgname="${imgbase%.*}"
        imgext="${imgbase##*.}"
        stripped_name="${imgname%-dark}"
        stripped_name="${stripped_name%-light}"
        variant_path="${imgdir}/${stripped_name}-${mode_flag}.${imgext}"
        if [[ -f "$variant_path" ]]; then
            imgpath="$variant_path"
        elif [[ -f "${imgdir}/${stripped_name}.${imgext}" ]]; then
            imgpath="${imgdir}/${stripped_name}.${imgext}"
        fi
    fi

    # If type_flag is 'auto', detect scheme type from image (after imgpath is set)
    if [[ "$type_flag" == "auto" ]]; then
        if [[ -n "$imgpath" && -f "$imgpath" ]]; then
            detected_type="$(detect_scheme_type_from_image "$imgpath")"
            valid_detected=0
            for t in "${allowed_types[@]}"; do
                if [[ "$detected_type" == "$t" && "$detected_type" != "auto" ]]; then
                    valid_detected=1
                    break
                fi
            done
            if [[ $valid_detected -eq 1 ]]; then
                type_flag="$detected_type"
            else
                echo "[switchwall] Warning: Could not auto-detect a valid scheme, defaulting to 'scheme-tonal-spot'" >&2
                type_flag="scheme-tonal-spot"
            fi
        else
            echo "[switchwall] Warning: No image to auto-detect scheme from, defaulting to 'scheme-tonal-spot'" >&2
            type_flag="scheme-tonal-spot"
        fi
    fi

    switch "$imgpath" "$mode_flag" "$type_flag" "$color_flag" "$color" "$noswitch_flag"
}

main "$@"
