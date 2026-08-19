CONFIG_DIRS=(matugen kde-material-you-colors fuzzel fontconfig kitty fish wlogout zshrc.d xdg-desktop-portal)
CONFIG_FILES=(starship.toml chrome-flags.conf code-flags.conf thorium-flags.conf)

STY_RST=$'\e[0m'
STY_RED=$'\e[31m'
STY_GREEN=$'\e[32m'
STY_YELLOW=$'\e[33m'
STY_BLUE=$'\e[34m'
STY_CYAN=$'\e[36m'

log()  { printf '%s[yunhai]%s %s\n' "$STY_CYAN" "$STY_RST" "$*"; }
step() { printf '\n%s[yunhai] == %s ==%s\n' "$STY_BLUE" "$*" "$STY_RST"; }
warn() { printf '%s[yunhai]%s %s\n' "$STY_YELLOW" "$STY_RST" "$*"; }
die()  { printf '%s[yunhai]%s %s\n' "$STY_RED" "$STY_RST" "$*" >&2; exit 1; }

ask() {
    [[ ${ASSUME_YES:-0} == 1 ]] && return 0
    local a
    read -rp "${STY_YELLOW}[yunhai]${STY_RST} $* [y/N] " a
    [[ $a == [yY] ]]
}

x() {
    while true; do
        "$@" && return 0
        warn "command failed: $*"
        local p
        read -rp "  [r]etry / [i]gnore / [e]xit: " p
        case $p in
            [iI]) return 0 ;;
            [eE]) die "aborted" ;;
        esac
    done
}

pkgs_from() { grep -hvE '^\s*(#|$)' "$@"; }

AUR_HELPER=""

detect_aur_helper() {
    local h
    for h in paru yay; do
        command -v "$h" &>/dev/null && { echo "$h"; return 0; }
    done
    return 1
}

ensure_aur_helper() {
    AUR_HELPER=$(detect_aur_helper) && return 0
    ask "no aur helper found (paru or yay), install paru-bin with makepkg now?" || die "an aur helper is required for aur packages (or rerun with --no-aur)"
    x sudo pacman -S --needed --noconfirm base-devel git
    local tmp
    tmp=$(mktemp -d)
    x git clone https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
    (cd "$tmp/paru-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    AUR_HELPER=$(detect_aur_helper) || die "paru install failed"
}

seed() {
    local src=$1 dst=$2
    [[ -e $dst ]] && return 0
    mkdir -p "$(dirname "$dst")"
    cp -a "$src" "$dst"
    log "seeded $dst"
}

backup_once() {
    local target=$1
    [[ -e $target ]] || return 0
    mkdir -p "$BACKUP_DIR"
    cp -a "$target" "$BACKUP_DIR/"
    log "backed up $target -> $BACKUP_DIR/"
}
