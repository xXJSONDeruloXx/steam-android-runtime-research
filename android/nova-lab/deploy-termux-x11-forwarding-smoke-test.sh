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
CLIENT_FRAMES=${NOVA_TERMUX_X11_CLIENT_FRAMES:-600}
RUN_ID=${NOVA_RUN_ID:-termux-x11-$(date -u +%Y%m%dT%H%M%SZ)-display-${DISPLAY_NUMBER}}
RUN_DIR=${NOVA_RUN_DIR:-$BUILD_DIR/manual-runs/$RUN_ID}

DISPLAY_VALUE=:$DISPLAY_NUMBER
REMOTE_STATE_DIR=/data/local/tmp/nova-x11-forwarding
REMOTE_SERVER_PID_FILE=$REMOTE_STATE_DIR/server.pid
REMOTE_CLIENT_PID_FILE=$REMOTE_STATE_DIR/client.pid
REMOTE_SERVER_LOG=$REMOTE_STATE_DIR/server.log
REMOTE_CLIENT_LOG=$REMOTE_STATE_DIR/client.log
REMOTE_CLIENT_STDOUT=$REMOTE_STATE_DIR/client.stdout
REMOTE_CLIENT_STDERR=$REMOTE_STATE_DIR/client.stderr
REMOTE_CLIENT_DIR=$DEVICE_ROOT/opt/nova-x11-forwarding
REMOTE_CLIENT=$REMOTE_CLIENT_DIR/nova-x11-animate
REMOTE_CAPTURE=$REMOTE_CLIENT_DIR/nova-x11-capture
REMOTE_X11_PPM=$DEVICE_ROOT/tmp/nova-x11-forwarding-$RUN_ID.ppm
REMOTE_X11_SOCKET=$DEVICE_ROOT/tmp/.X11-unix/X$DISPLAY_NUMBER
REMOTE_X11_LOCK=$DEVICE_ROOT/tmp/.X$DISPLAY_NUMBER-lock

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
if ! command -v sha256sum >/dev/null 2>&1; then
    echo "missing host tool: sha256sum" >&2
    exit 1
fi

mkdir -p "$RUN_DIR"
for artifact in \
    run-metadata.txt termux-x11-apk.sha256 nova-x11-animate.sha256 \
    nova-x11-capture.sha256 termux-x11-server.log termux-x11-client.log \
    x11-tree.txt x11-capture.txt x11-window.ppm android-screenshot.png \
    android-window-state.txt android-logcat.txt post-stop-verification.txt; do
    if [ -e "$RUN_DIR/$artifact" ]; then
        echo "run artifact already exists; choose a fresh NOVA_RUN_ID: $RUN_DIR/$artifact" >&2
        exit 2
    fi
done

ADB_ARGS=(-s "$ADB_SERIAL")
adb() {
    "$ADB" "${ADB_ARGS[@]}" "$@"
}

cleanup_remote() {
    local cleanup_output
    cleanup_output=$(adb shell su -c \
        "client_pid=; if [ -r $REMOTE_CLIENT_PID_FILE ]; then client_pid=\$(cat $REMOTE_CLIENT_PID_FILE); fi; if [ -n \"\$client_pid\" ] && [ -r /proc/\$client_pid/cmdline ] && tr '\\000' ' ' < /proc/\$client_pid/cmdline | grep -q 'nova-x11-animate'; then kill \"\$client_pid\" 2>/dev/null || true; fi; server_pid=; if [ -r $REMOTE_SERVER_PID_FILE ]; then server_pid=\$(cat $REMOTE_SERVER_PID_FILE); fi; if [ -n \"\$server_pid\" ] && [ -r /proc/\$server_pid/cmdline ] && tr '\\000' ' ' < /proc/\$server_pid/cmdline | grep -q 'termux-x11'; then kill \"\$server_pid\" 2>/dev/null || true; fi; am broadcast -a com.termux.x11.ACTION_STOP -p com.termux.x11 >/dev/null 2>&1 || true; am force-stop com.termux.x11 >/dev/null 2>&1 || true; rm -f $REMOTE_X11_SOCKET $REMOTE_X11_LOCK" 2>&1 || true)
    printf '%s\n' "$cleanup_output" | tr -d '\r'
}

post_stop_verify() {
    local output
    output=$(adb shell su -c \
        "server_pid=; if [ -r $REMOTE_SERVER_PID_FILE ]; then server_pid=\$(cat $REMOTE_SERVER_PID_FILE); fi; client_pid=; if [ -r $REMOTE_CLIENT_PID_FILE ]; then client_pid=\$(cat $REMOTE_CLIENT_PID_FILE); fi; server_state=absent; client_state=absent; socket_state=absent; [ -n \"\$server_pid\" ] && [ -e /proc/\$server_pid ] && server_state=present; [ -n \"\$client_pid\" ] && [ -e /proc/\$client_pid ] && client_state=present; [ -S $REMOTE_X11_SOCKET ] && socket_state=present; echo server_state=\$server_state client_state=\$client_state socket_state=\$socket_state" 2>&1 || true)
    output=$(printf '%s\n' "$output" | tr -d '\r')
    printf '%s\n' "$output" >"$RUN_DIR/post-stop-verification.txt"
    if printf '%s\n' "$output" | rg -q 'server_state=absent client_state=absent socket_state=absent'; then
        adb shell su -c "rm -f $REMOTE_CLIENT_PID_FILE $REMOTE_SERVER_PID_FILE" >/dev/null 2>&1 || true
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
        cleanup_remote >"$RUN_DIR/cleanup-output.txt" || true
        post_stop_verify || status=1
    fi
    exit "$status"
}
trap on_exit EXIT INT TERM

cleanup_remote >"$RUN_DIR/pre-run-cleanup.txt"
if adb shell su -c "test -S $REMOTE_X11_SOCKET" >/dev/null 2>&1; then
    echo "termux_x11_pre_run=fail socket_still_present=$REMOTE_X11_SOCKET" >&2
    exit 1
fi
adb shell am force-stop com.xjsonderulo.steamandroid.novalab >/dev/null 2>&1 || true
adb install -r -g --no-streaming "$APK" >"$RUN_DIR/apk-install.txt"
adb shell am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity >"$RUN_DIR/activity-start.txt" 2>&1 || true

{
    echo "run_id=$RUN_ID"
    echo "repo_commit=$(git -C "$SCRIPT_DIR/../.." rev-parse HEAD)"
    echo "adb_serial=$ADB_SERIAL"
    echo "device_root=$DEVICE_ROOT"
    echo "display=$DISPLAY_VALUE"
    echo "termux_x11_apk=$APK"
    echo "termux_x11_apk_sha256=$(sha256sum "$APK" | awk '{print $1}')"
    echo "x11_animate=$X11_ANIMATE"
    echo "x11_animate_sha256=$(sha256sum "$X11_ANIMATE" | awk '{print $1}')"
    echo "x11_capture=$X11_CAPTURE"
    echo "x11_capture_sha256=$(sha256sum "$X11_CAPTURE" | awk '{print $1}')"
    echo "client_frames=$CLIENT_FRAMES"
    echo "presentation=Termux:X11 Android SurfaceView"
    echo "gamescope=not_used"
    echo "ahb_bridge=not_used"
    echo "surfacecontrol=not_used"
} >"$RUN_DIR/run-metadata.txt"
sha256sum "$APK" >"$RUN_DIR/termux-x11-apk.sha256"
sha256sum "$X11_ANIMATE" >"$RUN_DIR/nova-x11-animate.sha256"
sha256sum "$X11_CAPTURE" >"$RUN_DIR/nova-x11-capture.sha256"

adb push "$X11_ANIMATE" /data/local/tmp/nova-x11-animate-forwarding >/dev/null
adb push "$X11_CAPTURE" /data/local/tmp/nova-x11-capture-forwarding >/dev/null
adb shell su -c "mkdir -p $REMOTE_STATE_DIR $REMOTE_CLIENT_DIR; cp /data/local/tmp/nova-x11-animate-forwarding $REMOTE_CLIENT; cp /data/local/tmp/nova-x11-capture-forwarding $REMOTE_CAPTURE; chmod 755 $REMOTE_CLIENT $REMOTE_CAPTURE"

adb shell su -c \
    "mkdir -p $REMOTE_STATE_DIR; export TMPDIR=$DEVICE_ROOT/tmp; export XKB_CONFIG_ROOT=$DEVICE_ROOT/usr/share/X11/xkb; export CLASSPATH=\$(pm path com.termux.x11 | cut -d: -f2); export TERMUX_X11_DEBUG=1; /system/bin/app_process / --nice-name=termux-x11 com.termux.x11.CmdEntryPoint $DISPLAY_VALUE >$REMOTE_SERVER_LOG 2>&1 & echo \$! >$REMOTE_SERVER_PID_FILE"
RUN_STARTED=1

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
    "printf '%s\\n' 'client_begin run_id=$RUN_ID display=$DISPLAY_VALUE' >$REMOTE_CLIENT_LOG; chroot $DEVICE_ROOT /usr/bin/env DISPLAY=$DISPLAY_VALUE XKB_CONFIG_ROOT=/usr/share/X11/xkb $REMOTE_CLIENT $CLIENT_FRAMES 1280 720 >$REMOTE_CLIENT_STDOUT 2>$REMOTE_CLIENT_STDERR & echo \$! >$REMOTE_CLIENT_PID_FILE"

sleep 1
adb shell su -c \
    "chroot $DEVICE_ROOT /usr/bin/env DISPLAY=$DISPLAY_VALUE XKB_CONFIG_ROOT=/usr/share/X11/xkb $REMOTE_CAPTURE --tree" \
    >"$RUN_DIR/x11-tree.txt"

window_id=$(sed -n 's/^nova_x11_window id=\([^ ]*\).*name="Nova animated Xwayland Gamescope probe".*/\1/p' "$RUN_DIR/x11-tree.txt" | head -n 1)
if [[ ! "$window_id" =~ ^0x[0-9A-Fa-f]+$ ]]; then
    echo "synthetic X11 window was not discovered" >&2
    exit 1
fi
echo "termux_x11_window=pass id=$window_id"

adb shell su -c \
    "chroot $DEVICE_ROOT /usr/bin/env DISPLAY=$DISPLAY_VALUE XKB_CONFIG_ROOT=/usr/share/X11/xkb $REMOTE_CAPTURE --window-ppm $window_id $REMOTE_X11_PPM" \
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
