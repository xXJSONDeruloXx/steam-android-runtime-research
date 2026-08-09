#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ADB=${ADB:-/Users/kurt/.local/bin/adb}
RUN_ID=${NOVA_RUN_ID:?NOVA_RUN_ID is required}
RUN_DIR=${NOVA_RUN_DIR:?NOVA_RUN_DIR is required}
CDP_PORT=${NOVA_CDP_PORT:?NOVA_CDP_PORT is required}
PHASE=${1:-}

case "$PHASE" in
    baseline|after-a|final)
        ;;
    *)
        echo "usage: $0 baseline|after-a|final" >&2
        exit 2
        ;;
esac
mkdir -p "$RUN_DIR"

STATUS="$RUN_DIR/capture-status-$PHASE.txt"
ANDROID_CAPTURE="$RUN_DIR/android-$PHASE.png"
CDP_CAPTURE="$RUN_DIR/cdp-targets-$PHASE.json"
FOCUS_CAPTURE="$RUN_DIR/focus-$PHASE.txt"

write_status() {
    local status_code="$1"
    local status_value=fail
    if [ "$status_code" -eq 0 ]; then
        status_value=pass
    fi
    {
        printf 'nova_run_id=%s\n' "$RUN_ID"
        printf 'capture_phase=%s\n' "$PHASE"
        printf 'capture_status=%s\n' "$status_value"
        if [ "$status_code" -eq 0 ]; then
            sha256sum "$ANDROID_CAPTURE" "$CDP_CAPTURE" "$FOCUS_CAPTURE" \
                "$RUN_DIR/x11-steam-$PHASE.ppm"
        fi
    } >"$STATUS"
}

on_exit() {
    local status_code=$?
    trap - EXIT
    write_status "$status_code"
    exit "$status_code"
}
trap on_exit EXIT

curl --fail --silent --show-error "http://127.0.0.1:$CDP_PORT/json" \
    >"$CDP_CAPTURE"
"$ADB" shell dumpsys input 2>/dev/null | tr -d '\r' |
    awk '/FocusedWindows:/{getline; print; exit}' >"$FOCUS_CAPTURE"
"$ADB" exec-out screencap -p >"$ANDROID_CAPTURE"
[ -s "$CDP_CAPTURE" ]
[ -s "$FOCUS_CAPTURE" ]
[ -s "$ANDROID_CAPTURE" ]

NOVA_RUN_ID="$RUN_ID" NOVA_RUN_DIR="$RUN_DIR" \
    "$SCRIPT_DIR/capture-nova-x11-window.sh" "$PHASE"
[ -s "$RUN_DIR/x11-capture-$PHASE-status.txt" ]
rg -q '^capture_status=pass$' "$RUN_DIR/x11-capture-$PHASE-status.txt"

echo "nova_manual_capture_status=pass phase=$PHASE"
