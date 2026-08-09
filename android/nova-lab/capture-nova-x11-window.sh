#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ADB=${ADB:-/Users/kurt/.local/bin/adb}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
X11_CAPTURE=${NOVA_X11_CAPTURE:-$SCRIPT_DIR/build/nova-x11-capture}
DEVICE_X11_CAPTURE=${NOVA_DEVICE_X11_CAPTURE:-/tmp/nova-x11-capture}
RUN_ID=${NOVA_RUN_ID:?NOVA_RUN_ID is required}
RUN_DIR=${NOVA_RUN_DIR:?NOVA_RUN_DIR is required}
PHASE=${1:-}

case "$RUN_ID" in
    ''|*[!A-Za-z0-9._-]*)
        echo "invalid NOVA_RUN_ID: $RUN_ID" >&2
        exit 2
        ;;
esac
case "$PHASE" in
    baseline|after-a|final)
        ;;
    *)
        echo "usage: $0 baseline|after-a|final" >&2
        exit 2
        ;;
esac

if [ ! -x "$X11_CAPTURE" ]; then
    echo "missing X11 capture helper: $X11_CAPTURE" >&2
    exit 1
fi
mkdir -p "$RUN_DIR"

TREE="$RUN_DIR/x11-tree-$PHASE.txt"
CAPTURE_LOG="$RUN_DIR/x11-capture-$PHASE.txt"
PULL_LOG="$RUN_DIR/x11-pull-$PHASE.txt"
PPM="$RUN_DIR/x11-steam-$PHASE.ppm"
WINDOW_MANIFEST="$RUN_DIR/x11-window-id.txt"
STATUS="$RUN_DIR/x11-capture-$PHASE-status.txt"
REMOTE_PPM="/tmp/nova-x11-capture-run/${RUN_ID}-${PHASE}.ppm"

write_status() {
    local status_code="$1"
    local status_value=fail
    if [ "$status_code" -eq 0 ]; then
        status_value=pass
    fi
    {
        printf 'nova_run_id=%s\n' "$RUN_ID"
        printf 'capture_phase=%s\n' "$PHASE"
        printf 'x11_window_id=%s\n' "${window_id:-unset}"
        printf 'capture_status=%s\n' "$status_value"
        if [ "$status_code" -eq 0 ]; then
            printf 'x11_ppm_sha256=%s\n' "$(sha256sum "$PPM" | awk '{print $1}')"
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

"$ADB" push "$X11_CAPTURE" "$DEVICE_ROOT$DEVICE_X11_CAPTURE" \
    >"$RUN_DIR/x11-helper-push-$PHASE.txt"
"$ADB" shell su -c \
    "chmod 755 $DEVICE_ROOT$DEVICE_X11_CAPTURE"
"$ADB" shell su -c \
    "/system/bin/chroot $DEVICE_ROOT /usr/bin/env DISPLAY=:0 $DEVICE_X11_CAPTURE --tree" \
    >"$TREE"

window_id=$(sed -n \
    's/.*nova_x11_window id=\(0x[0-9A-Fa-f][0-9A-Fa-f]*\).*name="Steam Big Picture Mode".*/\1/p' \
    "$TREE" | head -n 1)
if [[ ! "$window_id" =~ ^0x[0-9A-Fa-f]+$ ]]; then
    echo "Steam Big Picture X11 window was not discovered in $TREE" >&2
    exit 1
fi

if [ "$PHASE" = "baseline" ]; then
    {
        printf 'nova_run_id=%s\n' "$RUN_ID"
        printf 'x11_window_id=%s\n' "$window_id"
    } >"$WINDOW_MANIFEST"
else
    [ -s "$WINDOW_MANIFEST" ]
    manifest_run_id=$(sed -n 's/^nova_run_id=//p' "$WINDOW_MANIFEST")
    expected_window_id=$(sed -n 's/^x11_window_id=//p' "$WINDOW_MANIFEST")
    [ "$manifest_run_id" = "$RUN_ID" ]
    if [ "$expected_window_id" != "$window_id" ]; then
        echo "X11 window changed within run: expected=$expected_window_id observed=$window_id" >&2
        exit 1
    fi
fi

"$ADB" shell su -c "/system/bin/mkdir -p /tmp/nova-x11-capture-run"
"$ADB" shell su -c \
    "/system/bin/chroot $DEVICE_ROOT /usr/bin/env DISPLAY=:0 $DEVICE_X11_CAPTURE --window-ppm $window_id $REMOTE_PPM" \
    >"$CAPTURE_LOG"
"$ADB" pull "$DEVICE_ROOT$REMOTE_PPM" "$PPM" >"$PULL_LOG" 2>&1
[ -s "$PPM" ]

echo "nova_x11_capture_status=pass phase=$PHASE window_id=$window_id ppm=$PPM"
