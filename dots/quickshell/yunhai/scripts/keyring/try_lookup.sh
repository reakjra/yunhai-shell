#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! "${SCRIPT_DIR}/is_unlocked.sh"; then
    echo 'locked'
    exit 2
fi

data=$(timeout 5 secret-tool lookup 'application' 'yunhai-shell')
if [[ -z "$data" ]]; then
    echo 'not found'
    exit 1
fi
echo "$data"
