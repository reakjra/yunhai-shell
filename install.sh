#!/usr/bin/env bash
set -u
cd "$(dirname "$0")"
REPO="$(pwd)"
source "$REPO/installer/lib.sh"

PKG="$REPO/installer/packages"
EXCLUDES="$REPO/installer/rsync-excludes.txt"
VENV="$HOME/.local/state/quickshell/.venv"
QS_DST="$HOME/.config/quickshell/yunhai"
HYPR_DST="$HOME/.config/hypr"
BACKUP_DIR="$HOME/.local/state/yunhai/backup-$(date +%Y%m%d-%H%M%S)"

ASSUME_YES=0 DO_AUR=1 SKIP_SYSUPDATE=0 HYPRBARS_TODO=0
PHASES=(deps setups files build)
for a in "$@"; do case $a in
    -y) ASSUME_YES=1 ;;
    --no-aur) DO_AUR=0 ;;
    --skip-sysupdate) SKIP_SYSUPDATE=1 ;;
    --deps-only)   PHASES=(deps) ;;
    --setups-only) PHASES=(setups) ;;
    --files-only)  PHASES=(files) ;;
    --build-only)  PHASES=(build) ;;
    -h|--help)
        echo "usage: ./install.sh [-y] [--no-aur] [--skip-sysupdate] [--deps-only|--setups-only|--files-only|--build-only]"
        exit 0 ;;
    *) die "unknown flag: $a" ;;
esac; done

command -v pacman &>/dev/null || die "this installer is arch-only"
[[ $EUID == 0 ]] && die "run as your user, not root"
has_phase() { [[ " ${PHASES[*]} " == *" $1 "* ]]; }

if has_phase deps; then
    step "dependencies"
    sudo -v || die "sudo is required"
    [[ $SKIP_SYSUPDATE == 1 ]] || x sudo pacman -Syu
    x sudo pacman -S --needed --noconfirm $(pkgs_from "$PKG/base-repo.lst" "$PKG/rice-repo.lst")
    if [[ $DO_AUR == 1 ]]; then
        ensure_aur_helper
        log "using $AUR_HELPER for aur packages"
        x "$AUR_HELPER" -S --needed --noconfirm $(pkgs_from "$PKG/base-aur.lst" "$PKG/rice-aur.lst")
    else
        warn "skipping aur packages (--no-aur), the shell will not run without quickshell-git"
    fi
    if [[ $ASSUME_YES == 1 ]]; then
        warn "skipping optional packages in -y mode, see installer/packages/optional.lst"
    else
        while IFS='|' read -r pkg desc; do
            pkg=$(echo "$pkg" | xargs) desc=$(echo "$desc" | xargs)
            ask "install $pkg? ($desc)" || continue
            helper=${AUR_HELPER:-$(detect_aur_helper || true)}
            if [[ -n $helper ]]; then x "$helper" -S --needed --noconfirm "$pkg"
            else x sudo pacman -S --needed --noconfirm "$pkg"; fi
        done < <(pkgs_from "$PKG/optional.lst")
    fi
fi

if has_phase setups; then
    step "system setup"
    getent group i2c >/dev/null || x sudo groupadd i2c
    x sudo usermod -aG video,i2c,input "$USER"
    [[ -f /etc/modules-load.d/i2c-dev.conf ]] || echo i2c-dev | sudo tee /etc/modules-load.d/i2c-dev.conf >/dev/null
    systemctl --user enable ydotool --now 2>/dev/null || warn "could not enable ydotool user service (fine outside a session)"
    x sudo systemctl enable bluetooth --now

    step "python venv"
    [[ -d $VENV ]] || x uv venv --prompt .venv -p 3.12 "$VENV"
    x uv pip install --python "$VENV/bin/python" -r "$REPO/installer/requirements.txt"

    if command -v gsettings &>/dev/null; then
        gsettings set org.gnome.desktop.interface font-name 'Google Sans Flex Medium 11 @opsz=11,wght=500' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    fi
    if command -v kwriteconfig6 &>/dev/null; then
        kwriteconfig6 --file kdeglobals --group KDE --key widgetStyle Darkly
        if [[ -d /usr/share/icons/Tela-dark || -d $HOME/.local/share/icons/Tela-dark ]]; then
            kwriteconfig6 --file kdeglobals --group Icons --key Theme Tela-dark
        else
            warn "Tela-dark not found, leaving the icon theme alone (install tela-icon-theme for the intended look)"
        fi
    fi
fi

if has_phase files; then
    step "config files"
    backup_once "$QS_DST"
    backup_once "$HYPR_DST"

    mkdir -p "$QS_DST" "$HYPR_DST"
    x rsync -a --delete --exclude-from="$EXCLUDES" "$REPO/dots/quickshell/yunhai/" "$QS_DST/"

    x rsync -a --delete --exclude-from="$EXCLUDES" "$REPO/dots/hypr/" "$HYPR_DST/"
    seed "$REPO/dots/hypr/custom"                  "$HYPR_DST/custom"
    seed "$REPO/dots/hypr/hyprland/shellOverrides" "$HYPR_DST/hyprland/shellOverrides"
    seed "$REPO/dots/hypr/hyprland/colors.lua"     "$HYPR_DST/hyprland/colors.lua"

    for d in "${CONFIG_DIRS[@]}"; do
        x rsync -a --delete --exclude-from="$EXCLUDES" "$REPO/dots/config/$d/" "$HOME/.config/$d/"
    done
    seed "$REPO/dots/config/fuzzel/fuzzel_theme.ini" "$HOME/.config/fuzzel/fuzzel_theme.ini"
    for f in "${CONFIG_FILES[@]}"; do
        x cp -f "$REPO/dots/config/$f" "$HOME/.config/$f"
    done

    x rsync -a "$REPO/dots/fonts/" "$HOME/.local/share/fonts/"
    fc-cache -f >/dev/null 2>&1 || true
    x rsync -a "$REPO/dots/icons/" "$HOME/.local/share/icons/"
fi

if has_phase build; then
    step "compiled bits"
    QSB=$(command -v qsb || echo /usr/lib/qt6/bin/qsb)
    [[ -x $QSB ]] || die "qsb not found, install qt6-shadertools"
    n=0
    while IFS= read -r f; do
        x "$QSB" --qt6 -o "$f.qsb" "$f" && n=$((n + 1))
    done < <(find "$QS_DST/assets/shaders" -name '*.frag')
    log "compiled $n shaders"

    x bash "$QS_DST/scripts/desktop/clipboard/build.sh"

    if command -v hyprpm &>/dev/null && ask "install hyprbars via hyprpm? (title bars for the akebono family)"; then
        hyprpm_do() { hyprpm "$@" || sudo -E hyprpm "$@"; }
        if [[ -z ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
            warn "not inside a hyprland session, hyprpm cannot build against the running version"
            HYPRBARS_TODO=1
        else
            hyprpm_do add https://github.com/hyprwm/hyprland-plugins || true
            if hyprpm_do update && hyprpm_do enable hyprbars; then
                hyprpm reload
            else
                HYPRBARS_TODO=1
            fi
        fi
    fi
fi

step "done"
log "relog, the new groups and env vars need it. then start hyprland and pick a wallpaper in the welcome app, everything themes off it."
if [[ $HYPRBARS_TODO == 1 ]]; then
    warn "no hyprbars. inside a hyprland session: hyprpm add https://github.com/hyprwm/hyprland-plugins && hyprpm update && hyprpm enable hyprbars"
fi
