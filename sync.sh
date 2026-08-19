#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source installer/lib.sh
EXCLUDES="installer/rsync-excludes.txt"

rsync -a --delete --exclude-from="$EXCLUDES" "$HOME/.config/quickshell/yunhai/" dots/quickshell/yunhai/
rsync -a --delete --exclude-from="$EXCLUDES" "$HOME/.config/hypr/" dots/hypr/
for d in "${CONFIG_DIRS[@]}"; do
    rsync -a --delete --exclude-from="$EXCLUDES" "$HOME/.config/$d/" "dots/config/$d/"
done
for f in "${CONFIG_FILES[@]}"; do
    cp -f "$HOME/.config/$f" "dots/config/$f"
done

if [[ ${1:-} == --all ]]; then
    rsync -a --delete --exclude-from="$EXCLUDES" "$HOME/.local/share/fonts/google-sans-flex" "$HOME/.local/share/fonts/Google_Sans_Code" dots/fonts/
fi

git status --short
