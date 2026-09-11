#!/usr/bin/env bash

QUICKSHELL_CONFIG_NAME="yunhai"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
CONFIG_DIR="$XDG_CONFIG_HOME/quickshell/$QUICKSHELL_CONFIG_NAME"
CACHE_DIR="$XDG_CACHE_HOME/quickshell"
STATE_DIR="$XDG_STATE_HOME/quickshell/yunhai"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

term_alpha=100 #Set this to < 100 make all your terminals transparent
# sleep 0 # idk i wanted some delay or colors dont get applied properly
if [ ! -d "$STATE_DIR"/user/generated ]; then
  mkdir -p "$STATE_DIR"/user/generated
fi
cd "$CONFIG_DIR" || exit

colornames=''
colorstrings=''
colorlist=()
colorvalues=()

colornames=$(cat $STATE_DIR/user/generated/material_colors.scss | cut -d: -f1)
colorstrings=$(cat $STATE_DIR/user/generated/material_colors.scss | cut -d: -f2 | cut -d ' ' -f2 | cut -d ";" -f1)
IFS=$'\n'
colorlist=($colornames)     # Array of color names
colorvalues=($colorstrings) # Array of color values

if [ ${#colorlist[@]} -eq 0 ]; then
  echo "No colors in $STATE_DIR/user/generated/material_colors.scss, skipping" >&2
  exit 1
fi

render() {
  local template="$1" target="$2" sedscript="$3" tmp
  tmp=$(mktemp "$target.XXXXXX") || return 1
  if sed -f "$sedscript" "$template" > "$tmp"; then
    mv "$tmp" "$target"
  else
    rm -f "$tmp"
    return 1
  fi
}

apply_kitty() {
  # Check if kitty theme template exists
  if [ ! -f "$SCRIPT_DIR/terminal/kitty-theme.conf" ]; then
    echo "Template file not found for Kitty theme. Skipping that."
    return
  fi
  mkdir -p "$STATE_DIR"/user/generated/terminal
  render "$SCRIPT_DIR/terminal/kitty-theme.conf" "$STATE_DIR/user/generated/terminal/kitty-theme.conf" "$1" || return

  # Reload running kitty instances (no-op if none)
  pids=$(pidof kitty 2>/dev/null)
  if [ -n "$pids" ]; then
    kill -SIGUSR1 $pids 2>/dev/null || true
  fi
}

apply_anyterm() {
  # Check if terminal escape sequence template exists
  if [ ! -f "$SCRIPT_DIR/terminal/sequences.txt" ]; then
    echo "Template file not found for Terminal. Skipping that."
    return
  fi
  mkdir -p "$STATE_DIR"/user/generated/terminal
  render "$SCRIPT_DIR/terminal/sequences.txt" "$STATE_DIR/user/generated/terminal/sequences.txt" "$1" || return

  for file in /dev/pts/*; do
    if [[ $file =~ ^/dev/pts/[0-9]+$ ]]; then
      {
      cat "$STATE_DIR"/user/generated/terminal/sequences.txt >"$file"
      } & disown || true
    fi
  done
}

apply_term() {
  local sedscript
  sedscript=$(mktemp) || return
  for i in "${!colorlist[@]}"; do
    printf 's/%s #/%s/g\n' "${colorlist[$i]}" "${colorvalues[$i]#\#}"
  done > "$sedscript"
  printf 's/$alpha/%s/g\n' "$term_alpha" >> "$sedscript"

  apply_kitty "$sedscript"
  apply_anyterm "$sedscript"
  rm -f "$sedscript"
}

apply_qt() {
  sh "$CONFIG_DIR/scripts/kvantum/materialQT.sh"          # generate kvantum theme
  python "$CONFIG_DIR/scripts/kvantum/changeAdwColors.py" # apply config colors
}

if pgrep -x qs >/dev/null 2>&1; then
  exit 0
fi

# Check if terminal theming is enabled in config
CONFIG_FILE="$XDG_CONFIG_HOME/yunhai/global.json"
if [ -f "$CONFIG_FILE" ]; then
  enable_terminal=$(jq -r '.appearance.wallpaperTheming.enableTerminal' "$CONFIG_FILE")
  if [ "$enable_terminal" = "true" ]; then
    apply_term &
  fi
else
  echo "Config file not found at $CONFIG_FILE. Applying terminal theming by default."
  apply_term &
fi

# apply_qt & # Qt theming is already handled by kde-material-colors
