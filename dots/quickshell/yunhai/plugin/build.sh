#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

BUILD=build
IMPORTS=../imports

cmake -S . -B "$BUILD" -G Ninja -DCMAKE_BUILD_TYPE=Release >/dev/null
cmake --build "$BUILD" >/dev/null

rm -rf "$IMPORTS"
mkdir -p "$IMPORTS"
cp -r "$BUILD/imports/." "$IMPORTS/"

mapfile -t built < <(find "$BUILD" -name '*.so' -not -path "*/imports/*")

while IFS= read -r dir; do
    for plugin in "$dir"/*.so; do
        for needed in $(objdump -p "$plugin" | awk '/NEEDED/ {print $2}'); do
            for lib in "${built[@]}"; do
                [[ $(basename "$lib") == "$needed" ]] && cp "$lib" "$dir/"
            done
        done
    done
    sed -i '/^prefer /d; s/^optional plugin/plugin/' "$dir/qmldir"
    rm -f "$dir"/*.qrc
done < <(find "$IMPORTS" -name qmldir -printf '%h\n')

echo "built qml plugins into $(cd "$IMPORTS" && pwd)"
