#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
ADB_SERIAL=${ADB_SERIAL:-675a2365}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
DISPLAY_NUMBER=${NOVA_TERMUX_X11_DISPLAY:-0}
APK=${NOVA_TERMUX_X11_APK:?set NOVA_TERMUX_X11_APK to the official Termux:X11 APK}
X11_ANIMATE=${NOVA_X11_ANIMATE:-$BUILD_DIR/nova-x11-animate}
X11_CAPTURE=${NOVA_X11_CAPTURE:-$BUILD_DIR/nova-x11-capture}
RUNTIME_CLEANUP="$SCRIPT_DIR/device/nova-runtime-cleanup.sh"
X11_PRIVATE_NAMESPACE_HELPER="$SCRIPT_DIR/device/nova-x11-private-namespace.sh"
X11_CLEANUP_HELPER="$SCRIPT_DIR/device/nova-termux-x11-cleanup.sh"
DEVICE_RUNTIME_CLEANUP=/data/local/tmp/nova-runtime-cleanup.sh
CLIENT_FRAMES=${NOVA_TERMUX_X11_CLIENT_FRAMES:-600}
RUN_ID=${NOVA_RUN_ID:-termux-x11-$(date -u +%Y%m%dT%H%M%SZ)-display-${DISPLAY_NUMBER}}
RUN_DIR=${NOVA_RUN_DIR:-$BUILD_DIR/manual-runs/$RUN_ID}
XKB_CONFIG_ROOT_RELATIVE=/usr/share/xkeyboard-config-2

DISPLAY_VALUE=:$DISPLAY_NUMBER
REMOTE_STATE_DIR=/data/local/tmp/nova-x11-forwarding-state-$RUN_ID
REMOTE_SERVER_PID_FILE=$REMOTE_STATE_DIR/server.pid
REMOTE_CLIENT_PID_FILE=$REMOTE_STATE_DIR/client.pid
REMOTE_SERVER_LOG=$REMOTE_STATE_DIR/server.log
REMOTE_CLIENT_LOG=$REMOTE_STATE_DIR/client.log
REMOTE_CLIENT_STDOUT=$REMOTE_STATE_DIR/client.stdout
REMOTE_CLIENT_STDERR=$REMOTE_STATE_DIR/client.stderr
REMOTE_CLIENT=$DEVICE_ROOT/tmp/nova-x11-animate-$RUN_ID
REMOTE_CAPTURE=$DEVICE_ROOT/tmp/nova-x11-capture-$RUN_ID
REMOTE_X11_PPM=$DEVICE_ROOT/tmp/nova-x11-forwarding-$RUN_ID.ppm
REMOTE_X11_SOCKET=$DEVICE_ROOT/tmp/.X11-unix/X$DISPLAY_NUMBER
REMOTE_X11_LOCK=$DEVICE_ROOT/tmp/.X$DISPLAY_NUMBER-lock
CHROOT_CLIENT=/tmp/nova-x11-animate-$RUN_ID
CHROOT_CAPTURE=/tmp/nova-x11-capture-$RUN_ID
CHROOT_X11_PPM=/tmp/nova-x11-forwarding-$RUN_ID.ppm
REMOTE_PRIVATE_NAMESPACE_HELPER=/data/local/tmp/nova-x11-private-namespace-$RUN_ID.sh
REMOTE_X11_CLEANUP_HELPER=/data/local/tmp/nova-termux-x11-cleanup-$RUN_ID.sh

case "$RUN_ID" in
    ''|*[!A-Za-z0-9._-]*)
        echo "invalid NOVA_RUN_ID: $RUN_ID" >&2
        exit 2
        ;;
esac
case "$DISPLAY_NUMBER" in
    ''|*[!0-9]*)
        echo "NOVA_TERMUX_X11_DISPLAY must be numeric: $DISPLAY_NUMBER" >&2
        exit 2
        ;;
esac
case "$CLIENT_FRAMES" in
    ''|*[!0-9]*)
        echo "NOVA_TERMUX_X11_CLIENT_FRAMES must be numeric: $CLIENT_FRAMES" >&2
        exit 2
        ;;
esac

if [ ! -f "$APK" ]; then
    echo "missing Termux:X11 APK: $APK" >&2
    exit 1
fi
if [ ! -x "$X11_ANIMATE" ]; then
    echo "missing X11 animation client: $X11_ANIMATE" >&2
    exit 1
fi
if [ ! -x "$X11_CAPTURE" ]; then
    echo "missing X11 capture helper: $X11_CAPTURE" >&2
    exit 1
fi
if [ ! -x "$X11_PRIVATE_NAMESPACE_HELPER" ]; then
    echo "missing X11 namespace helper: $X11_PRIVATE_NAMESPACE_HELPER" >&2
    exit 1
fi
if [ ! -x "$X11_CLEANUP_HELPER" ]; then
    echo "missing X11 cleanup helper: $X11_CLEANUP_HELPER" >&2
    exit 1
fi
if ! command -v sha256sum >/dev/null 2>&1; then
    echo "missing host tool: sha256sum" >&2
    exit 1
fi

mkdir -p "$RUN_DIR"
for artifact in \
    run-metadata.txt termux-x11-apk.sha256 nova-x11-animate.sha256 \
    nova-x11-capture.sha256 nova-x11-private-namespace.sha256 \
    nova-termux-x11-cleanup.sha256 termux-x11-server.log \
    termux-x11-client.log termux-x11-client.stdout termux-x11-client.stderr \
    x11-tree.txt x11-capture.txt x11-window.ppm android-screenshot.png \
    android-window-state.txt android-logcat.txt nova-runtime-cleanup.txt \
    nova-runtime-cleanup-preflight.txt post-stop-verification.txt; do
    if [ -e "$RUN_DIR/$artifact" ]; then
        echo "run artifact already exists; choose a fresh NOVA_RUN_ID: $RUN_DIR/$artifact" >&2
        exit 2
    fi
done

ADB_ARGS=(-s "$ADB_SERIAL")
adb() {
    "$ADB" "${ADB_ARGS[@]}" "$@"
}

prepare_remote_state() {
    adb shell "mkdir -p $REMOTE_STATE_DIR; chmod 777 $REMOTE_STATE_DIR"
}

stage_x11_helpers() {
    adb push "$X11_PRIVATE_NAMESPACE_HELPER" "$REMOTE_PRIVATE_NAMESPACE_HELPER" >/dev/null
    adb push "$X11_CLEANUP_HELPER" "$REMOTE_X11_CLEANUP_HELPER" >/dev/null
    adb shell "chmod 755 $REMOTE_PRIVATE_NAMESPACE_HELPER $REMOTE_X11_CLEANUP_HELPER"
}

cleanup_nova_runtime() {
    local output status=0
    adb push "$RUNTIME_CLEANUP" "$DEVICE_RUNTIME_CLEANUP" >/dev/null 2>&1 || status=$?
    if [ "$status" -eq 0 ]; then
        output=$(adb shell su -c "/system/bin/sh $DEVICE_RUNTIME_CLEANUP $DEVICE_ROOT" 2>&1) || status=$?
    else
        output=
    fi
    output=$(printf '%s\n' "$output" | tr -d '\r')
    printf '%s\n' "$output"
    if [ "$status" -ne 0 ] || ! printf '%s\n' "$output" | rg -q '^nova_runtime_cleanup=pass '; then
        echo "nova_runtime_cleanup=fail" >&2
        return 1
    fi
}

cleanup_remote() {
    local cleanup_output status=0
    prepare_remote_state >/dev/null 2>&1 || true
    cleanup_output=$(adb shell su -c \
        "$REMOTE_X11_CLEANUP_HELPER cleanup $REMOTE_STATE_DIR $REMOTE_CLIENT $REMOTE_CAPTURE $REMOTE_X11_PPM $REMOTE_X11_SOCKET $REMOTE_X11_LOCK $REMOTE_PRIVATE_NAMESPACE_HELPER" 2>&1) || status=$?
    cleanup_output=$(printf '%s\n' "$cleanup_output" | tr -d '\r')
    printf '%s\n' "$cleanup_output"
    return "$status"
}

post_stop_verify() {
    local output status=0
    output=$(adb shell su -c \
        "$REMOTE_X11_CLEANUP_HELPER verify $REMOTE_STATE_DIR $REMOTE_X11_SOCKET" 2>&1) || status=$?
    output=$(printf '%s\n' "$output" | tr -d '\r')
    printf '%s\n' "$output" >"$RUN_DIR/post-stop-verification.txt"
    if [ "$status" -eq 0 ] && printf '%s\n' "$output" | rg -q 'server_state=absent client_state=absent server_parent_state=absent socket_state=absent'; then
        adb shell "rm -r $REMOTE_STATE_DIR" >/dev/null 2>&1 || true
        echo "termux_x11_post_stop=pass"
        return 0
    fi
    echo "termux_x11_post_stop=fail" >&2
    return 1
}

on_exit() {
    local status=$?
    trap - EXIT INT TERM
    if [ "${RUN_STARTED:-0}" = "1" ]; then
        adb shell su -c "cat $REMOTE_SERVER_LOG" >"$RUN_DIR/termux-x11-server.log" 2>/dev/null || true
        adb shell su -c "cat $REMOTE_CLIENT_LOG" >"$RUN_DIR/termux-x11-client.log" 2>/dev/null || true
        adb shell su -c "cat $REMOTE_CLIENT_STDOUT" >"$RUN_DIR/termux-x11-client.stdout" 2>/dev/null || true
        adb shell su -c "cat $REMOTE_CLIENT_STDERR" >"$RUN_DIR/termux-x11-client.stderr" 2>/dev/null || true
        adb logcat -d -v threadtime -s "CmdEntryPoint:*" "LorieNative:*" "MainActivity:*" "Lorie:*" "gles-renderer:*" "AndroidRuntime:*" >"$RUN_DIR/android-logcat.txt" || true
        cleanup_remote >"$RUN_DIR/cleanup-output.txt" || status=1
        post_stop_verify || status=1
        cleanup_nova_runtime >"$RUN_DIR/nova-runtime-cleanup.txt" || status=1
    fi
    exit "$status"
}
trap on_exit EXIT INT TERM

stage_x11_helpers
cleanup_remote >"$RUN_DIR/pre-run-cleanup.txt"
cleanup_nova_runtime >"$RUN_DIR/nova-runtime-cleanup-preflight.txt"
if adb shell su -c "test -S $REMOTE_X11_SOCKET" >/dev/null 2>&1; then
    echo "termux_x11_pre_run=fail socket_still_present=$REMOTE_X11_SOCKET" >&2
    exit 1
fi
adb shell am force-stop com.xjsonderulo.steamandroid.novalab >/dev/null 2>&1 || true
adb install -r -g --no-streaming "$APK" >"$RUN_DIR/apk-install.txt"
TERMUX_X11_CLASSPATH=$(adb shell pm path com.termux.x11 | tr -d '\r' | sed -n 's/^package://p' | head -n 1)
case "$TERMUX_X11_CLASSPATH" in
    /data/app/*/base.apk)
        ;;
    *)
        echo "invalid Termux:X11 APK path: $TERMUX_X11_CLASSPATH" >&2
        exit 1
        ;;
esac
adb logcat -c
adb shell am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >"$RUN_DIR/activity-start.txt" 2>&1 || true

{
    echo "run_id=$RUN_ID"
    echo "repo_commit=$(git -C "$SCRIPT_DIR/../.." rev-parse HEAD)"
    echo "adb_serial=$ADB_SERIAL"
    echo "device_root=$DEVICE_ROOT"
    echo "display=$DISPLAY_VALUE"
    echo "xkb_config_root=$DEVICE_ROOT$XKB_CONFIG_ROOT_RELATIVE"
    echo "state_dir=$REMOTE_STATE_DIR"
    echo "staged_client=$REMOTE_CLIENT"
    echo "staged_capture=$REMOTE_CAPTURE"
    echo "termux_x11_apk=$APK"
    echo "termux_x11_device_apk=$TERMUX_X11_CLASSPATH"
    echo "termux_x11_apk_sha256=$(sha256sum "$APK" | awk '{print $1}')"
    echo "x11_animate=$X11_ANIMATE"
    echo "x11_animate_sha256=$(sha256sum "$X11_ANIMATE" | awk '{print $1}')"
    echo "x11_capture=$X11_CAPTURE"
    echo "x11_capture_sha256=$(sha256sum "$X11_CAPTURE" | awk '{print $1}')"
    echo "x11_private_namespace_helper=$X11_PRIVATE_NAMESPACE_HELPER"
    echo "x11_private_namespace_helper_sha256=$(sha256sum "$X11_PRIVATE_NAMESPACE_HELPER" | awk '{print $1}')"
    echo "x11_cleanup_helper=$X11_CLEANUP_HELPER"
    echo "x11_cleanup_helper_sha256=$(sha256sum "$X11_CLEANUP_HELPER" | awk '{print $1}')"
    echo "remote_private_namespace_helper=$REMOTE_PRIVATE_NAMESPACE_HELPER"
    echo "remote_cleanup_helper=$REMOTE_X11_CLEANUP_HELPER"
    echo "client_frames=$CLIENT_FRAMES"
    echo "presentation=Termux:X11 Android SurfaceView"
    echo "gamescope=not_used"
    echo "ahb_bridge=not_used"
    echo "surfacecontrol=not_used"
} >"$RUN_DIR/run-metadata.txt"
sha256sum "$APK" >"$RUN_DIR/termux-x11-apk.sha256"
sha256sum "$X11_ANIMATE" >"$RUN_DIR/nova-x11-animate.sha256"
sha256sum "$X11_CAPTURE" >"$RUN_DIR/nova-x11-capture.sha256"
sha256sum "$X11_PRIVATE_NAMESPACE_HELPER" >"$RUN_DIR/nova-x11-private-namespace.sha256"
sha256sum "$X11_CLEANUP_HELPER" >"$RUN_DIR/nova-termux-x11-cleanup.sha256"

RUN_STARTED=1
prepare_remote_state
adb push "$X11_ANIMATE" "$REMOTE_CLIENT" >/dev/null
adb push "$X11_CAPTURE" "$REMOTE_CAPTURE" >/dev/null

adb shell su -c \
    "/system/bin/env TMPDIR=$DEVICE_ROOT/tmp XKB_CONFIG_ROOT=$DEVICE_ROOT$XKB_CONFIG_ROOT_RELATIVE CLASSPATH=$TERMUX_X11_CLASSPATH TERMUX_X11_DEBUG=1 /system/bin/app_process / --nice-name=termux-x11 com.termux.x11.CmdEntryPoint $DISPLAY_VALUE >$REMOTE_SERVER_LOG 2>&1 & echo \$! >$REMOTE_SERVER_PID_FILE"

socket_ready=0
for attempt in $(seq 1 60); do
    if adb shell su -c "test -S $REMOTE_X11_SOCKET" >/dev/null 2>&1; then
        socket_ready=1
        break
    fi
    sleep 0.25
done
if [ "$socket_ready" -ne 1 ]; then
    echo "termux_x11_server=fail socket=$REMOTE_X11_SOCKET" >&2
    exit 1
fi
echo "termux_x11_server=pass display=$DISPLAY_VALUE socket=$REMOTE_X11_SOCKET"

adb shell su -c \
    "echo client_begin_run_id=$RUN_ID display=$DISPLAY_VALUE >$REMOTE_CLIENT_LOG; $REMOTE_PRIVATE_NAMESPACE_HELPER chroot $DEVICE_ROOT /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp TMPDIR=/tmp DISPLAY=$DISPLAY_VALUE XKB_CONFIG_ROOT=$XKB_CONFIG_ROOT_RELATIVE $CHROOT_CLIENT $CLIENT_FRAMES 1280 720 >$REMOTE_CLIENT_STDOUT 2>$REMOTE_CLIENT_STDERR & echo \$! >$REMOTE_CLIENT_PID_FILE"

sleep 1
adb shell su -c \
    "$REMOTE_PRIVATE_NAMESPACE_HELPER chroot $DEVICE_ROOT /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp TMPDIR=/tmp DISPLAY=$DISPLAY_VALUE XKB_CONFIG_ROOT=$XKB_CONFIG_ROOT_RELATIVE $CHROOT_CAPTURE --tree" \
    >"$RUN_DIR/x11-tree.txt"

window_id=$(sed -n 's/^nova_x11_window id=\([^ ]*\).*name="Nova animated Xwayland Gamescope probe".*/\1/p' "$RUN_DIR/x11-tree.txt" | head -n 1)
if [[ ! "$window_id" =~ ^0x[0-9A-Fa-f]+$ ]]; then
    echo "synthetic X11 window was not discovered" >&2
    exit 1
fi
echo "termux_x11_window=pass id=$window_id"

adb shell su -c \
    "$REMOTE_PRIVATE_NAMESPACE_HELPER chroot $DEVICE_ROOT /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp TMPDIR=/tmp DISPLAY=$DISPLAY_VALUE XKB_CONFIG_ROOT=$XKB_CONFIG_ROOT_RELATIVE $CHROOT_CAPTURE --window-ppm $window_id $CHROOT_X11_PPM" \
    >"$RUN_DIR/x11-capture.txt"
adb pull "$REMOTE_X11_PPM" "$RUN_DIR/x11-window.ppm" >"$RUN_DIR/x11-pull.txt" 2>&1
[ -s "$RUN_DIR/x11-window.ppm" ]

adb exec-out screencap -p >"$RUN_DIR/android-screenshot.png"
[ -s "$RUN_DIR/android-screenshot.png" ]
adb shell dumpsys window windows >"$RUN_DIR/android-window-state.txt"
adb logcat -d -v threadtime -s "CmdEntryPoint:*" "MainActivity:*" "Lorie:*" "gles-renderer:*" >"$RUN_DIR/android-logcat.txt" || true

if ! rg -q 'mCurrentFocus=.*com\.termux\.x11|mFocusedApp=.*com\.termux\.x11' "$RUN_DIR/android-window-state.txt"; then
    echo "termux_x11_activity_focus=unknown_or_missing" >&2
fi
echo "termux_x11_android_capture=pass sha256=$(sha256sum "$RUN_DIR/android-screenshot.png" | awk '{print $1}')"
echo "termux_x11_x11_capture=pass sha256=$(sha256sum "$RUN_DIR/x11-window.ppm" | awk '{print $1}')"

sleep 1
