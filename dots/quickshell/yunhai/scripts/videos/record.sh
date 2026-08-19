#!/usr/bin/env bash

# CURRENTLY HARDWARE RECORDING ONLY COMPATIBLE WITH CARD2 AMD GPU.

CONFIG_FILE="$HOME/.config/yunhai/global.json"
JSON_PATH=".screenRecord.savePath"

STATE_FILE="$HOME/.local/state/quickshell/yunhai/states.json"
STATE_JSON_PATH=".screenRecord.active"

# Temp file to track the current recording path
RECORDING_PATH_FILE="/tmp/quickshell-recording-path"

# Read config
CUSTOM_PATH=$(jq -r "$JSON_PATH" "$CONFIG_FILE" 2>/dev/null)
QUALITY_QP=$(jq -r '.screenRecord.qualityQp // 23' "$CONFIG_FILE" 2>/dev/null)
MAX_FPS=$(jq -r '.screenRecord.maxFps // 60' "$CONFIG_FILE" 2>/dev/null)
HW_ENCODING=$(jq -r 'if .screenRecord.hardwareEncoding == null then true else .screenRecord.hardwareEncoding end' "$CONFIG_FILE" 2>/dev/null)
RECORD_AUDIO=$(jq -r 'if .screenRecord.recordAudio == null then true else .screenRecord.recordAudio end' "$CONFIG_FILE" 2>/dev/null)

RECORDING_DIR=""

TIMER_PID=""
SECONDS_ELAPSED=-1

if [[ -n "$CUSTOM_PATH" ]]; then
    RECORDING_DIR="$CUSTOM_PATH"
else
    RECORDING_DIR="$HOME/Videos"
fi

start_timer() {
    if [[ -n "$TIMER_PID" ]]; then
        kill "$TIMER_PID" 2>/dev/null
    fi

    (
        while true; do
            SECONDS_ELAPSED=$((SECONDS_ELAPSED + 1))
            jq ".screenRecord.seconds = $SECONDS_ELAPSED" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
            sleep 1
        done
    ) &
    TIMER_PID=$!
}
stop_timer() {
    if [[ -n "$TIMER_PID" ]]; then
        kill "$TIMER_PID" 2>/dev/null
        wait "$TIMER_PID" 2>/dev/null
        TIMER_PID=""
        jq ".screenRecord.seconds = 0" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    fi
}


trap stop_timer EXIT


getdate() {
    date '+%Y-%m-%d_%H.%M.%S'
}

getaudiooutput() {
    pactl list sources | grep 'Name' | grep 'monitor' | cut -d ' ' -f2
}
getactivemonitor() {
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
}

updatestate() {
    local state_value=$1
    jq "$STATE_JSON_PATH = $state_value" "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    if [[ "$state_value" == "true" ]]; then
        start_timer
    else
        stop_timer
    fi
}

kill_wf_recorder() {
    pkill -INT wf-recorder 2>/dev/null
    # Wait up to 2s for graceful shutdown
    for _ in 1 2; do
        sleep 1
        pgrep wf-recorder > /dev/null || return 0
    done
    # Force kill if VAAPI encoder hangs
    pkill -9 wf-recorder 2>/dev/null
    sleep 0.5
}

remux_to_mp4() {
    local mkv_file="$1"
    [[ -f "$mkv_file" ]] || return 1
    local mp4_file="${mkv_file%.mkv}.mp4"
    ffmpeg -y -loglevel error -i "$mkv_file" -c copy "$mp4_file" && rm -f "$mkv_file"
}

# Build wf-recorder command based on config
build_wf_recorder_cmd() {
    local cmd="wf-recorder -o $(getactivemonitor) -r ${MAX_FPS}"

    if [[ "$HW_ENCODING" == "true" ]]; then
        cmd+=" -d /dev/dri/renderD129 -c h264_vaapi -p qp=${QUALITY_QP}"
    else
        cmd+=" -c libx264rgb -p crf=${QUALITY_QP} -p preset=ultrafast"
    fi

    echo "$cmd"
}


mkdir -p "$RECORDING_DIR"
cd "$RECORDING_DIR" || exit

# Audio: config is the default, --sound flag overrides to on
SOUND_FLAG=0
[[ "$RECORD_AUDIO" == "true" ]] && SOUND_FLAG=1

# parse --region <value> without modifying $@ so other flags like --fullscreen still work
ARGS=("$@")
MANUAL_REGION=""
FULLSCREEN_FLAG=0
for ((i=0;i<${#ARGS[@]};i++)); do
    if [[ "${ARGS[i]}" == "--region" ]]; then
        if (( i+1 < ${#ARGS[@]} )); then
            MANUAL_REGION="${ARGS[i+1]}"
        else
            notify-send "Recording cancelled" "No region specified for --region" -a 'Recorder' & disown
            updatestate false
            exit 1
        fi
    elif [[ "${ARGS[i]}" == "--sound" ]]; then
        SOUND_FLAG=1
    elif [[ "${ARGS[i]}" == "--fullscreen" ]]; then
        FULLSCREEN_FLAG=1
    fi
done

if pgrep wf-recorder > /dev/null; then
    notify-send "Recording Stopped" "Stopped" -a 'Recorder' &
    updatestate false
    REC_FILE=""
    [[ -f "$RECORDING_PATH_FILE" ]] && REC_FILE=$(cat "$RECORDING_PATH_FILE")
    kill_wf_recorder
    rm -f "$RECORDING_PATH_FILE"
    # Remux mkv → mp4 if needed
    if [[ -n "$REC_FILE" && "$REC_FILE" == *.mkv ]]; then
        remux_to_mp4 "$REC_FILE"
    fi
else
    # Hardware → mkv (crash-safe) + remux on stop, Software → mp4 directly
    if [[ "$HW_ENCODING" == "true" ]]; then
        EXT="mkv"
    else
        EXT="mp4"
    fi
    FILENAME="recording_$(getdate).${EXT}"
    FILEPATH="${RECORDING_DIR}/${FILENAME}"
    echo "$FILEPATH" > "$RECORDING_PATH_FILE"

    BASE_CMD=$(build_wf_recorder_cmd)

    notify-send "Starting recording" "recording_$(getdate).mp4" -a 'Recorder' & disown
    updatestate true

    if [[ $FULLSCREEN_FLAG -eq 1 ]]; then
        if [[ $SOUND_FLAG -eq 1 ]]; then
            $BASE_CMD -f "$FILEPATH" --audio="$(getaudiooutput)"
        else
            $BASE_CMD -f "$FILEPATH"
        fi
    else
        if [[ -n "$MANUAL_REGION" ]]; then
            region="$MANUAL_REGION"
        else
            if ! region="$(slurp 2>&1)"; then
                notify-send "Recording cancelled" "Selection was cancelled" -a 'Recorder' & disown
                updatestate false
                rm -f "$RECORDING_PATH_FILE"
                exit 1
            fi
        fi

        pos="${region%% *}"      # x,y
        size="${region##* }"     # WxH
        x="${pos%,*}"
        y="${pos#*,}"
        geometry="${x},${y} ${size}"

        if [[ $SOUND_FLAG -eq 1 ]]; then
            $BASE_CMD -f "$FILEPATH" --geometry "$geometry" --audio="$(getaudiooutput)"
        else
            $BASE_CMD -f "$FILEPATH" --geometry "$geometry"
        fi
    fi
fi
