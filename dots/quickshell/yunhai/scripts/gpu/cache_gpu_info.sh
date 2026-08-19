#!/usr/bin/env bash
set -euo pipefail
LC_NUMERIC=C

# One-shot script: detect GPUs, cache static info to state dir
# Run once on QS startup, pollers read this instead of re-detecting

STATE_DIR="${1:-$HOME/.local/state/quickshell/yunhai/user}"
mkdir -p "$STATE_DIR"
OUT="$STATE_DIR/gpu-info.json"

dgpu_vendor="" dgpu_name="" dgpu_card="" dgpu_hwmon=""
igpu_vendor="" igpu_name="" igpu_card="" igpu_hwmon=""

# Available sensor flags
dgpu_has_usage=false dgpu_has_vram=false
dgpu_has_temp_edge=false dgpu_has_temp_junction=false dgpu_has_temp_mem=false
dgpu_has_fan_rpm=false dgpu_has_fan_percent=false
dgpu_has_power=false dgpu_has_power_limit=false

igpu_has_usage=false igpu_has_vram=false igpu_has_temp=false

get_gpu_name() {
    local bdf="$1" fallback="$2"
    if ! command -v lspci >/dev/null 2>&1; then
        echo "$fallback"; return
    fi
    local desc
    desc="$(LC_ALL=C lspci -s "$bdf" 2>/dev/null || true)"
    [[ -z "$desc" ]] && { echo "$fallback"; return; }

    # prefer bracket with product name (Radeon/GeForce/Arc), fall back to last bracket
    if [[ "$desc" =~ \[([^\]]*(Radeon|GeForce|Arc)[^\]]*)\] ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$desc" =~ .*\[([^\]]+)\] ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        local tmp="${desc#*: }"
        tmp="$(echo "$tmp" | sed -E 's/\(rev[^)]+\)//g; s/[[:space:]]+$//')"
        echo "$tmp"
    fi
}

find_hwmon() {
    local card_path="$1"
    for hm in "$card_path"/hwmon/hwmon*; do
        [[ -d "$hm" ]] && echo "$hm" && return
    done
    echo ""
}

check_hwmon_sensors() {
    local hm="$1" prefix="$2"
    [[ -z "$hm" || ! -d "$hm" ]] && return

    # temperature sensors
    for lbl in "$hm"/temp*_label; do
        [[ -r "$lbl" ]] || continue
        local labeltxt
        labeltxt=$(tr '[:upper:]' '[:lower:]' < "$lbl")
        local base="${lbl%_label}"
        [[ -r "${base}_input" ]] || continue
        case "$labeltxt" in
            *edge*) eval "${prefix}_has_temp_edge=true" ;;
            *junction*|*hotspot*|*junc*) eval "${prefix}_has_temp_junction=true" ;;
            *mem*|*vram*) eval "${prefix}_has_temp_mem=true" ;;
        esac
    done

    # fan
    for fin in "$hm"/fan*_input; do
        [[ -r "$fin" ]] && eval "${prefix}_has_fan_rpm=true" && break
    done

    # power
    [[ -r "$hm/power1_average" ]] && eval "${prefix}_has_power=true"
    [[ -r "$hm/power1_cap" ]] && eval "${prefix}_has_power_limit=true"
}

# --- Detect NVIDIA dGPU ---
if command -v nvidia-smi &>/dev/null && nvidia-smi -L &>/dev/null 2>&1; then
    dgpu_vendor="nvidia"
    dgpu_name=$(nvidia-smi --query-gpu=name --format=csv,noheader,nounits 2>/dev/null | head -n1 || echo "NVIDIA GPU")
    dgpu_card="nvidia-smi"
    dgpu_has_usage=true
    dgpu_has_vram=true
    dgpu_has_temp_edge=true
    dgpu_has_fan_percent=true
    dgpu_has_power=true
    dgpu_has_power_limit=true
fi

# --- Detect AMD/Intel dGPU ---
if [[ -z "$dgpu_vendor" ]]; then
    for d in /sys/class/drm/card*/device; do
        [[ -r "$d/vendor" ]] || continue
        vendor_id=$(<"$d/vendor")

        # AMD dGPU
        if [[ "$vendor_id" == *"1002"* ]]; then
            vtot=0
            [[ -r "$d/mem_info_vram_total" ]] && vtot=$(<"$d/mem_info_vram_total")
            if (( vtot > 0 )); then
                dgpu_vendor="amd"
                card_name=$(basename "$(dirname "$d")")
                dgpu_card="$card_name"
                bdf="$(basename "$(readlink -f "$d")")"
                dgpu_name=$(get_gpu_name "$bdf" "AMD GPU")
                dgpu_hwmon=$(find_hwmon "$d")
                [[ -r "$d/gpu_busy_percent" ]] && dgpu_has_usage=true
                [[ -r "$d/mem_info_vram_used" ]] && dgpu_has_vram=true
                check_hwmon_sensors "$dgpu_hwmon" "dgpu"
                break
            fi
        fi

        # Intel Arc dGPU
        if [[ "$vendor_id" == *"8086"* ]]; then
            [[ -r "$d/lmem_total_bytes" ]] || continue
            vtot=$(<"$d/lmem_total_bytes")
            if (( vtot > 0 )); then
                dgpu_vendor="intel"
                card_name=$(basename "$(dirname "$d")")
                dgpu_card="$card_name"
                bdf="$(basename "$(readlink -f "$d")")"
                dgpu_name=$(get_gpu_name "$bdf" "Intel Arc GPU")
                dgpu_hwmon=$(find_hwmon "$d")
                dgpu_has_vram=true
                command -v intel_gpu_top &>/dev/null && dgpu_has_usage=true
                check_hwmon_sensors "$dgpu_hwmon" "dgpu"
                break
            fi
        fi
    done
fi

# --- Detect iGPU ---
# Intel iGPU
if command -v intel_gpu_top &>/dev/null; then
    for d in /sys/class/drm/card*/device; do
        [[ -r "$d/vendor" ]] || continue
        [[ "$(<"$d/vendor")" == *"8086"* ]] || continue
        [[ ! -r "$d/lmem_total_bytes" ]] || continue
        igpu_vendor="intel"
        card_name=$(basename "$(dirname "$d")")
        igpu_card="$card_name"
        bdf="$(basename "$(readlink -f "$d")")"
        igpu_name=$(get_gpu_name "$bdf" "Intel iGPU")
        igpu_has_usage=true
        igpu_has_vram=true
        igpu_has_temp=true
        break
    done
fi

# AMD iGPU
if [[ -z "$igpu_vendor" ]]; then
    for d in /sys/class/drm/card*/device; do
        [[ -r "$d/vendor" ]] || continue
        [[ "$(<"$d/vendor")" == *"1002"* ]] || continue
        vtot=0
        [[ -r "$d/mem_info_vram_total" ]] && vtot=$(<"$d/mem_info_vram_total")
        vtype=""
        [[ -r "$d/vram_type" ]] && vtype=$(tr '[:upper:]' '[:lower:]' < "$d/vram_type")
        gtt=0
        [[ -r "$d/gtt_total" ]] && gtt=$(<"$d/gtt_total")

        if { [[ "$vtot" -eq 0 ]] || [[ "$vtype" == "none" ]]; } && (( gtt > 0 )); then
            igpu_vendor="amd"
            card_name=$(basename "$(dirname "$d")")
            igpu_card="$card_name"
            bdf="$(basename "$(readlink -f "$d")")"
            igpu_name=$(get_gpu_name "$bdf" "AMD iGPU")
            [[ -r "$d/gpu_busy_percent" ]] && igpu_has_usage=true
            igpu_has_vram=true
            # check temp
            local_hwmon=$(find_hwmon "$d")
            if [[ -n "$local_hwmon" ]]; then
                for tin in "$local_hwmon"/temp*_input; do
                    [[ -r "$tin" ]] && igpu_has_temp=true && break
                done
            fi
            break
        fi
    done
fi

# --- Write JSON ---
# Use a temp file for atomic write
tmp=$(mktemp "$STATE_DIR/.gpu-info.XXXXXX")

cat > "$tmp" <<ENDJSON
{
  "dgpu": {
    "available": $([ -n "$dgpu_vendor" ] && echo true || echo false),
    "vendor": $([ -n "$dgpu_vendor" ] && printf '"%s"' "$dgpu_vendor" || echo null),
    "name": $([ -n "$dgpu_name" ] && printf '"%s"' "${dgpu_name//\"/\\\"}" || echo null),
    "card": $([ -n "$dgpu_card" ] && printf '"%s"' "$dgpu_card" || echo null),
    "sensors": {
      "usage": $dgpu_has_usage,
      "vram": $dgpu_has_vram,
      "tempEdge": $dgpu_has_temp_edge,
      "tempJunction": $dgpu_has_temp_junction,
      "tempMem": $dgpu_has_temp_mem,
      "fanRpm": $dgpu_has_fan_rpm,
      "fanPercent": $dgpu_has_fan_percent,
      "power": $dgpu_has_power,
      "powerLimit": $dgpu_has_power_limit
    }
  },
  "igpu": {
    "available": $([ -n "$igpu_vendor" ] && echo true || echo false),
    "vendor": $([ -n "$igpu_vendor" ] && printf '"%s"' "$igpu_vendor" || echo null),
    "name": $([ -n "$igpu_name" ] && printf '"%s"' "${igpu_name//\"/\\\"}" || echo null),
    "card": $([ -n "$igpu_card" ] && printf '"%s"' "$igpu_card" || echo null),
    "sensors": {
      "usage": $igpu_has_usage,
      "vram": $igpu_has_vram,
      "temp": $igpu_has_temp
    }
  }
}
ENDJSON

mv "$tmp" "$OUT"
