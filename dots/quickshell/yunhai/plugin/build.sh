#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

PROFILE=${1:-release}
MODULE=../imports/Yunhai

if ! command -v cargo >/dev/null; then
    echo "cargo not found: install rust to build the qml plugin" >&2
    exit 1
fi

if [[ $PROFILE == release ]]; then
    cargo build --release
else
    cargo build
fi

rm -rf "$MODULE"
mkdir -p "$MODULE"
cp "target/$PROFILE/libYunhai.so" "$MODULE/"
cp target/cxxqt/qml_modules/Yunhai/plugin.qmltypes "$MODULE/"
sed '/^prefer /d; s/^optional plugin/plugin/' target/cxxqt/qml_modules/Yunhai/qmldir > "$MODULE/qmldir"

cargo clean

echo "built qml plugin into $(cd "$MODULE" && pwd)"
