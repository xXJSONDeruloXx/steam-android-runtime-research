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
X11_WINDOW_NAME=${NOVA_TERMUX_X11_WINDOW_NAME-Nova animated Xwayland Gamescope probe}
WINDOW_WAIT_SECONDS=${NOVA_TERMUX_X11_WINDOW_WAIT_SECONDS:-1}
RUNTIME_CLEANUP="$SCRIPT_DIR/device/nova-runtime-cleanup.sh"
X11_PRIVATE_NAMESPACE_HELPER="$SCRIPT_DIR/device/nova-x11-private-namespace.sh"
X11_CLEANUP_HELPER="$SCRIPT_DIR/device/nova-termux-x11-cleanup.sh"
X11_CLIENT_LAUNCHER="$SCRIPT_DIR/device/nova-termux-x11-client-launcher.sh"
X11_ROOTFS_DEVICES_HELPER="$SCRIPT_DIR/device/nova-termux-x11-rootfs-devices.sh"
NETWORK_OBSERVER_HOST="$SCRIPT_DIR/probe-termux-x11-network-state.sh"
NETWORK_OBSERVER_DEVICE="$SCRIPT_DIR/device/nova-termux-x11-network-observer.sh"
MOUNT_PRIVATE_HELPER=${NOVA_MOUNT_PRIVATE_HELPER:-$BUILD_DIR/nova-mount-private}
DEVICE_RUNTIME_CLEANUP=/data/local/tmp/nova-runtime-cleanup.sh
CLIENT_FRAMES=${NOVA_TERMUX_X11_CLIENT_FRAMES:-600}
ALLOW_X11_CAPTURE_FAILURE=${NOVA_TERMUX_X11_ALLOW_X11_CAPTURE_FAILURE:-0}
CAPTURE_DELAY_SECONDS=${NOVA_TERMUX_X11_CAPTURE_DELAY_SECONDS:-0}
INPUT_MODE=${NOVA_TERMUX_X11_INPUT_MODE:-none}
INPUT_KEYCODE=${NOVA_TERMUX_X11_INPUT_KEYCODE:-66}
INPUT_KEYCODES=${NOVA_TERMUX_X11_INPUT_KEYCODES:-}
INPUT_KEY_NAME=${NOVA_TERMUX_X11_INPUT_KEY_NAME:-KEYCODE_ENTER}
INPUT_DELAY_SECONDS=${NOVA_TERMUX_X11_INPUT_DELAY_SECONDS:-1}
INPUT_AFTER_DELAY_SECONDS=${NOVA_TERMUX_X11_INPUT_AFTER_DELAY_SECONDS:-4}
STEAM_TIMEOUT_SECONDS=${NOVA_TERMUX_X11_STEAM_TIMEOUT_SECONDS:-60}
STEAM_UID=${NOVA_TERMUX_X11_STEAM_UID:-501}
STEAM_GID=${NOVA_TERMUX_X11_STEAM_GID:-20}
BIND_ANDROID_DEV=${NOVA_TERMUX_X11_BIND_ANDROID_DEV:-0}
NETWORK_OBSERVER=${NOVA_TERMUX_X11_NETWORK_OBSERVER:-0}
NETWORK_OBSERVER_DURATION_SECONDS=${NOVA_TERMUX_X11_NETWORK_OBSERVER_DURATION_SECONDS:-45}
NETWORK_OBSERVER_INTERVAL_SECONDS=${NOVA_TERMUX_X11_NETWORK_OBSERVER_INTERVAL_SECONDS:-5}
DBUS_SESSION_MODE=${NOVA_TERMUX_X11_DBUS_SESSION:-0}
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
REMOTE_STEAM_LOG=$DEVICE_ROOT/tmp/nova-steam-client.log
REMOTE_STEAM_STDOUT=$DEVICE_ROOT/tmp/nova-steam-client.stdout
REMOTE_STEAM_STDERR=$DEVICE_ROOT/tmp/nova-steam-client.stderr
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
REMOTE_CLIENT_LAUNCHER=/data/local/tmp/nova-termux-x11-client-launcher-$RUN_ID.sh
REMOTE_ROOTFS_DEVICES_HELPER=/data/local/tmp/nova-termux-x11-rootfs-devices-$RUN_ID.sh
REMOTE_MOUNT_PRIVATE=/data/local/tmp/nova-mount-private-$RUN_ID
REMOTE_NETWORK_OBSERVER=$DEVICE_ROOT/tmp/nova-termux-x11-network-observer-$RUN_ID.sh
SERVER_PROCESS_TOKEN=termux-x11
CLIENT_PROCESS_TOKEN=nova-x11-animate-$RUN_ID
REMOTE_CLIENT_HOST_PID=
NETWORK_OBSERVER_HOST_PID=

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
case "$ALLOW_X11_CAPTURE_FAILURE" in
    0|1)
        ;;
    *)
        echo "NOVA_TERMUX_X11_ALLOW_X11_CAPTURE_FAILURE must be 0 or 1" >&2
        exit 2
        ;;
esac
case "$WINDOW_WAIT_SECONDS" in
    ''|*[!0-9]*)
        echo "NOVA_TERMUX_X11_WINDOW_WAIT_SECONDS must be numeric" >&2
        exit 2
        ;;
esac
if [ "$WINDOW_WAIT_SECONDS" -lt 1 ]; then
    echo "NOVA_TERMUX_X11_WINDOW_WAIT_SECONDS must be at least 1" >&2
    exit 2
fi
case "$CAPTURE_DELAY_SECONDS" in
    ''|*[!0-9]*)
        echo "NOVA_TERMUX_X11_CAPTURE_DELAY_SECONDS must be numeric" >&2
        exit 2
        ;;
esac
case "$INPUT_MODE" in
    none|android-keyevent|android-keyevent-sequence)
        ;;
    *)
        echo "NOVA_TERMUX_X11_INPUT_MODE must be none, android-keyevent, or android-keyevent-sequence" >&2
        exit 2
        ;;
esac
case "$INPUT_KEYCODE:$INPUT_DELAY_SECONDS:$INPUT_AFTER_DELAY_SECONDS" in
    ''|*[!0-9:]*|*:*:*:*)
        echo "NOVA_TERMUX_X11 input keycode/delays must be numeric" >&2
        exit 2
        ;;
esac
case "$STEAM_TIMEOUT_SECONDS" in
    ''|*[!0-9]*)
        echo "NOVA_TERMUX_X11_STEAM_TIMEOUT_SECONDS must be numeric" >&2
        exit 2
        ;;
esac
if [ "$STEAM_TIMEOUT_SECONDS" -lt 1 ]; then
    echo "NOVA_TERMUX_X11_STEAM_TIMEOUT_SECONDS must be at least 1" >&2
    exit 2
fi
INPUT_SEQUENCE_CODES=()
if [ "$INPUT_MODE" = "android-keyevent-sequence" ]; then
    case "$INPUT_KEYCODES" in
        ''|*[!0-9,]*|,*|*,|*,,*)
            echo "NOVA_TERMUX_X11_INPUT_KEYCODES must be a comma-separated numeric sequence" >&2
            exit 2
            ;;
    esac
    IFS=',' read -r -a INPUT_SEQUENCE_CODES <<<"$INPUT_KEYCODES"
    if [ "${#INPUT_SEQUENCE_CODES[@]}" -lt 2 ]; then
        echo "NOVA_TERMUX_X11_INPUT_KEYCODES must contain at least two events" >&2
        exit 2
    fi
else
    INPUT_SEQUENCE_CODES=("$INPUT_KEYCODE")
fi
case "$STEAM_UID:$STEAM_GID" in
    ''|*[!0-9:]*|*:*:*)
        echo "NOVA_TERMUX_X11_STEAM_UID/GID must be numeric" >&2
        exit 2
        ;;
esac
case "$BIND_ANDROID_DEV" in
    0|1)
        ;;
    *)
        echo "NOVA_TERMUX_X11_BIND_ANDROID_DEV must be 0 or 1" >&2
        exit 2
        ;;
esac
case "$NETWORK_OBSERVER" in
    0|1)
        ;;
    *)
        echo "NOVA_TERMUX_X11_NETWORK_OBSERVER must be 0 or 1" >&2
        exit 2
        ;;
esac
case "$DBUS_SESSION_MODE" in
    0|1)
        ;;
    *)
        echo "NOVA_TERMUX_X11_DBUS_SESSION must be 0 or 1" >&2
        exit 2
        ;;
esac
case "$NETWORK_OBSERVER_DURATION_SECONDS:$NETWORK_OBSERVER_INTERVAL_SECONDS" in
    ''|*[!0-9:]*|*:*:*)
        echo "NOVA_TERMUX_X11_NETWORK_OBSERVER duration/interval must be numeric" >&2
        exit 2
        ;;
esac
if [ "$NETWORK_OBSERVER" -eq 1 ] &&
    { [ "$NETWORK_OBSERVER_DURATION_SECONDS" -lt 1 ] || [ "$NETWORK_OBSERVER_INTERVAL_SECONDS" -lt 1 ]; }; then
    echo "NOVA_TERMUX_X11_NETWORK_OBSERVER duration/interval must be at least 1 second" >&2
    exit 2
fi

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
if [ ! -x "$X11_CLIENT_LAUNCHER" ]; then
    echo "missing X11 client launcher: $X11_CLIENT_LAUNCHER" >&2
    exit 1
fi
if [ ! -x "$X11_ROOTFS_DEVICES_HELPER" ]; then
    echo "missing rootfs device helper: $X11_ROOTFS_DEVICES_HELPER" >&2
    exit 1
fi
if [ "$NETWORK_OBSERVER" -eq 1 ]; then
    if [ ! -x "$NETWORK_OBSERVER_HOST" ]; then
        echo "missing network observer host helper: $NETWORK_OBSERVER_HOST" >&2
        exit 1
    fi
    if [ ! -x "$NETWORK_OBSERVER_DEVICE" ]; then
        echo "missing network observer device helper: $NETWORK_OBSERVER_DEVICE" >&2
        exit 1
    fi
fi
if [ "$BIND_ANDROID_DEV" -eq 1 ]; then
    if [ ! -x "$MOUNT_PRIVATE_HELPER" ]; then
        "$SCRIPT_DIR/build-mount-private.sh" >/dev/null
    fi
    if [ ! -x "$MOUNT_PRIVATE_HELPER" ]; then
        echo "missing mount-private helper: $MOUNT_PRIVATE_HELPER" >&2
        exit 1
    fi
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
    nova-termux-x11-client-launcher.sha256 nova-termux-x11-rootfs-devices.sha256 \
    termux-x11-client.log termux-x11-client.stdout termux-x11-client.stderr \
    steam-client.log steam-client.stdout steam-client.stderr \
    client-launch-command.txt client-host-pid.txt \
    x11-tree.txt x11-capture.txt x11-window.ppm android-screenshot.png \
    android-window-state.txt android-logcat.txt nova-runtime-cleanup.txt \
    nova-runtime-cleanup-preflight.txt rootfs-devices-preflight.txt \
    nova-mount-private.sha256 \
    android-input-focus.txt android-input-focus-before-input.txt \
    android-input-focus-after-input.txt \
    android-input-sequence.txt \
    post-stop-verification.txt android-window-state-before-input.txt \
    android-window-state-after-input.txt android-input-keyevent.txt \
    android-screenshot-before-input.png android-screenshot-after-input.png \
    x11-tree-after-input.txt x11-capture-after-input.txt \
    x11-window-before-input.ppm x11-window-after-input.ppm \
    x11-pull-after-input.txt network-observer-status.txt \
    network-chroot-observer.txt; do
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
    adb shell "mkdir -p $REMOTE_STATE_DIR; chmod 777 $REMOTE_STATE_DIR; echo $REMOTE_CLIENT >$REMOTE_STATE_DIR/client.path; echo $REMOTE_CAPTURE >$REMOTE_STATE_DIR/capture.path; echo $REMOTE_X11_PPM >$REMOTE_STATE_DIR/ppm.path; echo $REMOTE_X11_SOCKET >$REMOTE_STATE_DIR/socket.path; echo $REMOTE_X11_LOCK >$REMOTE_STATE_DIR/lock.path; echo $SERVER_PROCESS_TOKEN >$REMOTE_STATE_DIR/server-token; echo $CLIENT_PROCESS_TOKEN >$REMOTE_STATE_DIR/client-token; echo 0 >$REMOTE_STATE_DIR/client-active"
}

stage_x11_helpers() {
    adb push "$X11_PRIVATE_NAMESPACE_HELPER" "$REMOTE_PRIVATE_NAMESPACE_HELPER" >/dev/null
    adb push "$X11_CLEANUP_HELPER" "$REMOTE_X11_CLEANUP_HELPER" >/dev/null
    adb push "$X11_CLIENT_LAUNCHER" "$REMOTE_CLIENT_LAUNCHER" >/dev/null
    adb push "$X11_ROOTFS_DEVICES_HELPER" "$REMOTE_ROOTFS_DEVICES_HELPER" >/dev/null
    if [ "$NETWORK_OBSERVER" -eq 1 ]; then
        adb push "$NETWORK_OBSERVER_DEVICE" "$REMOTE_NETWORK_OBSERVER" >/dev/null
    fi
    helper_paths="$REMOTE_PRIVATE_NAMESPACE_HELPER $REMOTE_X11_CLEANUP_HELPER $REMOTE_CLIENT_LAUNCHER $REMOTE_ROOTFS_DEVICES_HELPER"
    if [ "$NETWORK_OBSERVER" -eq 1 ]; then
        helper_paths="$helper_paths $REMOTE_NETWORK_OBSERVER"
    fi
    if [ "$BIND_ANDROID_DEV" -eq 1 ]; then
        adb push "$MOUNT_PRIVATE_HELPER" "$REMOTE_MOUNT_PRIVATE" >/dev/null
        adb shell "chmod 755 $helper_paths $REMOTE_MOUNT_PRIVATE"
    else
        adb shell "chmod 755 $helper_paths"
    fi
}

prepare_rootfs_devices() {
    local output status=0
    output=$(adb shell su -c \
        "$REMOTE_ROOTFS_DEVICES_HELPER $DEVICE_ROOT" 2>&1) || status=$?
    output=$(printf '%s\n' "$output" | tr -d '\r')
    printf '%s\n' "$output"
    if [ "$status" -ne 0 ] || ! printf '%s\n' "$output" | rg -q '^nova_rootfs_devices=pass '; then
        echo "nova_rootfs_devices=fail" >&2
        return 1
    fi
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
    local phase="${1:-runtime}" cleanup_output status=0
    prepare_remote_state >/dev/null 2>&1 || true
    cleanup_output=$(adb shell su -c \
        "$REMOTE_X11_CLEANUP_HELPER cleanup $REMOTE_STATE_DIR $REMOTE_PRIVATE_NAMESPACE_HELPER $phase" 2>&1) || status=$?
    cleanup_output=$(printf '%s\n' "$cleanup_output" | tr -d '\r')
    printf '%s\n' "$cleanup_output"
    return "$status"
}

post_stop_verify() {
    local output status=0
    output=$(adb shell su -c \
        "$REMOTE_X11_CLEANUP_HELPER verify $REMOTE_STATE_DIR" 2>&1) || status=$?
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
        if [ -n "${REMOTE_CLIENT_HOST_PID:-}" ]; then
            wait "$REMOTE_CLIENT_HOST_PID" >/dev/null 2>&1 || true
        fi
        if [ -n "${NETWORK_OBSERVER_HOST_PID:-}" ]; then
            observer_status=0
            wait "$NETWORK_OBSERVER_HOST_PID" >/dev/null 2>&1 || observer_status=$?
            if [ "$observer_status" -ne 0 ]; then
                status=1
            fi
            NETWORK_OBSERVER_HOST_PID=
        fi
        adb shell su -c "cat $REMOTE_SERVER_LOG" >"$RUN_DIR/termux-x11-server.log" 2>/dev/null || true
        adb shell su -c "cat $REMOTE_CLIENT_LOG" >"$RUN_DIR/termux-x11-client.log" 2>/dev/null || true
        adb shell su -c "cat $REMOTE_CLIENT_STDOUT" >"$RUN_DIR/termux-x11-client.stdout" 2>/dev/null || true
        adb shell su -c "cat $REMOTE_CLIENT_STDERR" >"$RUN_DIR/termux-x11-client.stderr" 2>/dev/null || true
        adb shell su -c "cat $REMOTE_STEAM_LOG" >"$RUN_DIR/steam-client.log" 2>/dev/null || true
        adb shell su -c "cat $REMOTE_STEAM_STDOUT" >"$RUN_DIR/steam-client.stdout" 2>/dev/null || true
        adb shell su -c "cat $REMOTE_STEAM_STDERR" >"$RUN_DIR/steam-client.stderr" 2>/dev/null || true
        adb logcat -d -v threadtime -s "CmdEntryPoint:*" "LorieNative:*" "MainActivity:*" "Lorie:*" "gles-renderer:*" "AndroidRuntime:*" >"$RUN_DIR/android-logcat.txt" || true
        cleanup_remote runtime >"$RUN_DIR/cleanup-output.txt" || status=1
        post_stop_verify || status=1
        cleanup_nova_runtime >"$RUN_DIR/nova-runtime-cleanup.txt" || status=1
        if [ "$BIND_ANDROID_DEV" -eq 1 ]; then
            adb shell su -c "/system/bin/rm -f $REMOTE_MOUNT_PRIVATE" >/dev/null 2>&1 || status=1
        fi
        if [ "$NETWORK_OBSERVER" -eq 1 ]; then
            adb shell su -c "/system/bin/rm -f $REMOTE_NETWORK_OBSERVER" >/dev/null 2>&1 || status=1
        fi
    fi
    exit "$status"
}
trap on_exit EXIT INT TERM

stage_x11_helpers
cleanup_remote preflight >"$RUN_DIR/pre-run-cleanup.txt"
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
    echo "steam_client_log=$REMOTE_STEAM_LOG"
    echo "steam_client_stdout=$REMOTE_STEAM_STDOUT"
    echo "steam_client_stderr=$REMOTE_STEAM_STDERR"
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
    echo "rootfs_devices_helper=$X11_ROOTFS_DEVICES_HELPER"
    echo "rootfs_devices_helper_sha256=$(sha256sum "$X11_ROOTFS_DEVICES_HELPER" | awk '{print $1}')"
    echo "remote_rootfs_devices_helper=$REMOTE_ROOTFS_DEVICES_HELPER"
    echo "bind_android_dev=$BIND_ANDROID_DEV"
    echo "client_namespace_mode=$([ "$BIND_ANDROID_DEV" -eq 1 ] && echo chroot-dev || echo chroot)"
    if [ "$BIND_ANDROID_DEV" -eq 1 ]; then
        echo "mount_private_helper=$MOUNT_PRIVATE_HELPER"
        echo "mount_private_helper_sha256=$(sha256sum "$MOUNT_PRIVATE_HELPER" | awk '{print $1}')"
        echo "remote_mount_private=$REMOTE_MOUNT_PRIVATE"
    fi
    echo "x11_client_launcher=$X11_CLIENT_LAUNCHER"
    echo "x11_client_launcher_sha256=$(sha256sum "$X11_CLIENT_LAUNCHER" | awk '{print $1}')"
    echo "remote_client_launcher=$REMOTE_CLIENT_LAUNCHER"
    echo "server_process_token=$SERVER_PROCESS_TOKEN"
    echo "client_process_token=$CLIENT_PROCESS_TOKEN"
    echo "client_launch=foreground adb shell su command with host-side background"
    echo "client_frames=$CLIENT_FRAMES"
    echo "allow_x11_capture_failure=$ALLOW_X11_CAPTURE_FAILURE"
    echo "capture_delay_seconds=$CAPTURE_DELAY_SECONDS"
    echo "input_mode=$INPUT_MODE"
    echo "input_keycode=$INPUT_KEYCODE"
    echo "input_keycodes=${INPUT_KEYCODES:-unset}"
    echo "input_key_name=$INPUT_KEY_NAME"
    echo "input_delay_seconds=$INPUT_DELAY_SECONDS"
    echo "input_after_delay_seconds=$INPUT_AFTER_DELAY_SECONDS"
    echo "steam_timeout_seconds=$STEAM_TIMEOUT_SECONDS"
    echo "steam_uid=$STEAM_UID:$STEAM_GID"
    echo "dbus_session=$DBUS_SESSION_MODE"
    echo "network_observer=$NETWORK_OBSERVER"
    if [ "$NETWORK_OBSERVER" -eq 1 ]; then
        echo "network_observer_host=$NETWORK_OBSERVER_HOST"
        echo "network_observer_host_sha256=$(sha256sum "$NETWORK_OBSERVER_HOST" | awk '{print $1}')"
        echo "network_observer_device=$NETWORK_OBSERVER_DEVICE"
        echo "network_observer_device_sha256=$(sha256sum "$NETWORK_OBSERVER_DEVICE" | awk '{print $1}')"
        echo "network_observer_remote=$REMOTE_NETWORK_OBSERVER"
        echo "network_observer_duration_seconds=$NETWORK_OBSERVER_DURATION_SECONDS"
        echo "network_observer_interval_seconds=$NETWORK_OBSERVER_INTERVAL_SECONDS"
    fi
    echo "x11_window_name=${X11_WINDOW_NAME-any viewable depth-1 child}"
    echo "x11_window_wait_seconds=$WINDOW_WAIT_SECONDS"
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
sha256sum "$X11_CLIENT_LAUNCHER" >"$RUN_DIR/nova-termux-x11-client-launcher.sha256"
sha256sum "$X11_ROOTFS_DEVICES_HELPER" >"$RUN_DIR/nova-termux-x11-rootfs-devices.sha256"
if [ "$BIND_ANDROID_DEV" -eq 1 ]; then
    sha256sum "$MOUNT_PRIVATE_HELPER" >"$RUN_DIR/nova-mount-private.sha256"
fi
if [ "$NETWORK_OBSERVER" -eq 1 ]; then
    sha256sum "$NETWORK_OBSERVER_HOST" >"$RUN_DIR/probe-termux-x11-network-state.sha256"
    sha256sum "$NETWORK_OBSERVER_DEVICE" >"$RUN_DIR/nova-termux-x11-network-observer.sha256"
fi

RUN_STARTED=1
if [ "$BIND_ANDROID_DEV" -eq 1 ]; then
    echo "nova_rootfs_devices=skipped mode=android-dev-bind" >"$RUN_DIR/rootfs-devices-preflight.txt"
else
    prepare_rootfs_devices >"$RUN_DIR/rootfs-devices-preflight.txt"
fi
prepare_remote_state
adb shell su -c "/system/bin/rm -f $REMOTE_STEAM_LOG $REMOTE_STEAM_STDOUT $REMOTE_STEAM_STDERR"
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

adb shell "echo client_begin_run_id=$RUN_ID display=$DISPLAY_VALUE >$REMOTE_CLIENT_LOG"
adb shell "echo 1 >$REMOTE_STATE_DIR/client-active"
client_namespace_mode=chroot
client_namespace_args="$DEVICE_ROOT"
if [ "$BIND_ANDROID_DEV" -eq 1 ]; then
    client_namespace_mode=chroot-dev
    client_namespace_args="$REMOTE_MOUNT_PRIVATE $DEVICE_ROOT"
fi
adb shell su -c \
    "$REMOTE_CLIENT_LAUNCHER $REMOTE_PRIVATE_NAMESPACE_HELPER $REMOTE_CLIENT_STDOUT $REMOTE_CLIENT_STDERR $client_namespace_mode $client_namespace_args /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp TMPDIR=/tmp DISPLAY=$DISPLAY_VALUE XKB_CONFIG_ROOT=$XKB_CONFIG_ROOT_RELATIVE NOVA_TERMUX_X11_STEAM_UID=$STEAM_UID NOVA_TERMUX_X11_STEAM_GID=$STEAM_GID NOVA_TERMUX_X11_STEAM_TIMEOUT_SECONDS=$STEAM_TIMEOUT_SECONDS NOVA_TERMUX_X11_DBUS_SESSION=$DBUS_SESSION_MODE $CHROOT_CLIENT $CLIENT_FRAMES 1280 720" \
    >"$RUN_DIR/client-launch-command.txt" 2>&1 &
REMOTE_CLIENT_HOST_PID=$!
printf '%s\n' "$REMOTE_CLIENT_HOST_PID" >"$RUN_DIR/client-host-pid.txt"

window_id=
for attempt in $(seq 1 "$WINDOW_WAIT_SECONDS"); do
    tree_status=0
    adb shell su -c \
        "$REMOTE_PRIVATE_NAMESPACE_HELPER chroot $DEVICE_ROOT /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp TMPDIR=/tmp DISPLAY=$DISPLAY_VALUE XKB_CONFIG_ROOT=$XKB_CONFIG_ROOT_RELATIVE $CHROOT_CAPTURE --tree" \
        >"$RUN_DIR/x11-tree.txt" 2>&1 || tree_status=$?
    if [ -n "$X11_WINDOW_NAME" ]; then
        window_id=$(sed -n "s/^nova_x11_window id=\\([^ ]*\\).*name=\"$X11_WINDOW_NAME\".*/\\1/p" "$RUN_DIR/x11-tree.txt" | head -n 1)
    else
        window_id=$(sed -n 's/^nova_x11_window id=\([^ ]*\).*depth=1 map_state=viewable.*/\1/p' "$RUN_DIR/x11-tree.txt" | head -n 1)
    fi
    if [[ "$window_id" =~ ^0x[0-9A-Fa-f]+$ ]]; then
        break
    fi
    window_id=
    if [ "$attempt" -lt "$WINDOW_WAIT_SECONDS" ]; then
        sleep 1
    fi
done
if [[ ! "$window_id" =~ ^0x[0-9A-Fa-f]+$ ]]; then
    echo "X11 window was not discovered after ${WINDOW_WAIT_SECONDS}s" >&2
    exit 1
fi
echo "termux_x11_window=pass id=$window_id"

if [ "$CAPTURE_DELAY_SECONDS" -gt 0 ]; then
    echo "termux_x11_capture_delay=pass seconds=$CAPTURE_DELAY_SECONDS"
    sleep "$CAPTURE_DELAY_SECONDS"
fi

capture_status=0
adb shell su -c \
    "$REMOTE_PRIVATE_NAMESPACE_HELPER chroot $DEVICE_ROOT /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp TMPDIR=/tmp DISPLAY=$DISPLAY_VALUE XKB_CONFIG_ROOT=$XKB_CONFIG_ROOT_RELATIVE $CHROOT_CAPTURE --window-ppm $window_id $CHROOT_X11_PPM" \
    >"$RUN_DIR/x11-capture.txt" 2>&1 || capture_status=$?
echo "termux_x11_capture_status=$capture_status" >>"$RUN_DIR/x11-capture.txt"
if [ "$capture_status" -ne 0 ]; then
    if [ "$ALLOW_X11_CAPTURE_FAILURE" -ne 1 ]; then
        exit 1
    fi
    echo "termux_x11_x11_capture=observational_failure status=$capture_status"
else
    adb pull "$REMOTE_X11_PPM" "$RUN_DIR/x11-window.ppm" >"$RUN_DIR/x11-pull.txt" 2>&1
    [ -s "$RUN_DIR/x11-window.ppm" ]
fi

adb exec-out screencap -p >"$RUN_DIR/android-screenshot.png"
[ -s "$RUN_DIR/android-screenshot.png" ]
adb shell dumpsys window windows >"$RUN_DIR/android-window-state.txt"
adb shell dumpsys input >"$RUN_DIR/android-input-focus.txt"
adb logcat -d -v threadtime -s "CmdEntryPoint:*" "MainActivity:*" "Lorie:*" "gles-renderer:*" >"$RUN_DIR/android-logcat.txt" || true

if ! sed -n '/FocusedWindows:/{n;p;q;}' "$RUN_DIR/android-input-focus.txt" | rg -q 'com\.termux\.x11'; then
    echo "termux_x11_activity_focus=unknown_or_missing" >&2
fi
echo "termux_x11_android_capture=pass sha256=$(sha256sum "$RUN_DIR/android-screenshot.png" | awk '{print $1}')"
if [ "$capture_status" -eq 0 ]; then
    echo "termux_x11_x11_capture=pass sha256=$(sha256sum "$RUN_DIR/x11-window.ppm" | awk '{print $1}')"
fi

if [ "$NETWORK_OBSERVER" -eq 1 ]; then
    observer_mount_private=-
    if [ "$BIND_ANDROID_DEV" -eq 1 ]; then
        observer_mount_private="$REMOTE_MOUNT_PRIVATE"
    fi
    "$NETWORK_OBSERVER_HOST" "$ADB" "$ADB_SERIAL" "$DEVICE_ROOT" "$RUN_ID" "$RUN_DIR" \
        "$REMOTE_PRIVATE_NAMESPACE_HELPER" "$client_namespace_mode" \
        "$observer_mount_private" "$REMOTE_NETWORK_OBSERVER" \
        "$NETWORK_OBSERVER_DURATION_SECONDS" "$NETWORK_OBSERVER_INTERVAL_SECONDS" \
        >"$RUN_DIR/network-observer.log" 2>&1 &
    NETWORK_OBSERVER_HOST_PID=$!
    echo "termux_x11_network_observer=started pid=$NETWORK_OBSERVER_HOST_PID"
fi

if [ "$INPUT_MODE" != "none" ]; then
    focus_contains() {
        local focus_file="$1"
        local package_pattern="$2"
        sed -n '/FocusedWindows:/{n;p;q;}' "$focus_file" | rg -q "$package_pattern"
    }

    if [ "$INPUT_MODE" = "android-keyevent" ]; then
        INPUT_SEQUENCE_LOG="$RUN_DIR/android-input-keyevent.txt"
    else
        INPUT_SEQUENCE_LOG="$RUN_DIR/android-input-sequence.txt"
    fi
    : >"$INPUT_SEQUENCE_LOG"
    if [ "$INPUT_MODE" = "android-keyevent-sequence" ]; then
        echo "input_mode=android-keyevent-sequence" >>"$INPUT_SEQUENCE_LOG"
        echo "input_keycodes=$INPUT_KEYCODES" >>"$INPUT_SEQUENCE_LOG"
    fi

    previous_android="$RUN_DIR/android-screenshot.png"
    previous_x11="$RUN_DIR/x11-window.ppm"
    previous_x11_status=$capture_status
    input_step=0
    for input_code in "${INPUT_SEQUENCE_CODES[@]}"; do
        input_step=$((input_step + 1))
        step_label=$(printf '%02d' "$input_step")
        if [ "$INPUT_MODE" = "android-keyevent" ]; then
            before_android="$RUN_DIR/android-screenshot-before-input.png"
            after_android="$RUN_DIR/android-screenshot-after-input.png"
            before_window="$RUN_DIR/android-window-state-before-input.txt"
            before_focus="$RUN_DIR/android-input-focus-before-input.txt"
            after_window="$RUN_DIR/android-window-state-after-input.txt"
            after_focus="$RUN_DIR/android-input-focus-after-input.txt"
            after_tree="$RUN_DIR/x11-tree-after-input.txt"
            after_capture="$RUN_DIR/x11-capture-after-input.txt"
            after_ppm="$RUN_DIR/x11-window-after-input.ppm"
            after_pull="$RUN_DIR/x11-pull-after-input.txt"
        else
            before_android="$RUN_DIR/android-screenshot-step-${step_label}-before-input.png"
            after_android="$RUN_DIR/android-screenshot-step-${step_label}-after-input.png"
            before_window="$RUN_DIR/android-window-state-step-${step_label}-before-input.txt"
            before_focus="$RUN_DIR/android-input-focus-step-${step_label}-before-input.txt"
            after_window="$RUN_DIR/android-window-state-step-${step_label}-after-input.txt"
            after_focus="$RUN_DIR/android-input-focus-step-${step_label}-after-input.txt"
            after_tree="$RUN_DIR/x11-tree-step-${step_label}-after-input.txt"
            after_capture="$RUN_DIR/x11-capture-step-${step_label}-after-input.txt"
            after_ppm="$RUN_DIR/x11-window-step-${step_label}-after-input.ppm"
            after_pull="$RUN_DIR/x11-pull-step-${step_label}-after-input.txt"
        fi
        cp "$previous_android" "$before_android"
        if [ "$previous_x11_status" -eq 0 ]; then
            before_ppm="$RUN_DIR/x11-window-before-input.ppm"
            if [ "$INPUT_MODE" = "android-keyevent-sequence" ]; then
                before_ppm="$RUN_DIR/x11-window-step-${step_label}-before-input.ppm"
            fi
            cp "$previous_x11" "$before_ppm"
        fi

        sleep "$INPUT_DELAY_SECONDS"
        adb shell dumpsys window windows >"$before_window"
        adb shell dumpsys input >"$before_focus"
        if ! focus_contains "$before_focus" 'com\.termux\.x11'; then
            if focus_contains "$before_focus" 'com\.rp\.settings'; then
                adb shell input keyevent 4 >/dev/null 2>&1 || true
                echo "input_overlay_dismissed=pass step=$input_step" >>"$INPUT_SEQUENCE_LOG"
                sleep 1
                adb shell dumpsys window windows >"$before_window"
                adb shell dumpsys input >"$before_focus"
            fi
        fi
        if ! focus_contains "$before_focus" 'com\.termux\.x11'; then
            echo "termux_x11_input_focus=fail step=$input_step" >&2
            exit 1
        fi

        {
            echo "input_step=$input_step"
            echo "input_keycode=$input_code"
            echo "input_key_name=$INPUT_KEY_NAME"
            echo "input_focus=pass package=com.termux.x11"
            echo "input_command=adb shell input keyevent $input_code"
        } >>"$INPUT_SEQUENCE_LOG"
        input_status=0
        adb shell input keyevent "$input_code" >>"$INPUT_SEQUENCE_LOG" 2>&1 || input_status=$?
        echo "input_exit_status=$input_status step=$input_step" >>"$INPUT_SEQUENCE_LOG"
        if [ "$input_status" -ne 0 ]; then
            echo "termux_x11_input=fail step=$input_step status=$input_status" >&2
            exit 1
        fi
        if [ "$INPUT_MODE" = "android-keyevent" ]; then
            echo "termux_x11_input=pass keycode=$input_code name=$INPUT_KEY_NAME"
        else
            echo "termux_x11_input_step=pass step=$input_step keycode=$input_code name=$INPUT_KEY_NAME"
        fi
        sleep "$INPUT_AFTER_DELAY_SECONDS"

        after_tree_status=0
        adb shell su -c \
            "$REMOTE_PRIVATE_NAMESPACE_HELPER chroot $DEVICE_ROOT /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp TMPDIR=/tmp DISPLAY=$DISPLAY_VALUE XKB_CONFIG_ROOT=$XKB_CONFIG_ROOT_RELATIVE $CHROOT_CAPTURE --tree" \
            >"$after_tree" 2>&1 || after_tree_status=$?
        if [ "$after_tree_status" -ne 0 ] || ! rg -q "^nova_x11_window id=$window_id " "$after_tree"; then
            echo "termux_x11_window_after_input=fail step=$input_step" >&2
            exit 1
        fi
        if [ "$INPUT_MODE" = "android-keyevent" ]; then
            echo "termux_x11_window_after_input=pass id=$window_id"
        else
            echo "termux_x11_window_step_after_input=pass step=$input_step id=$window_id"
        fi

        after_capture_status=0
        adb shell su -c \
            "$REMOTE_PRIVATE_NAMESPACE_HELPER chroot $DEVICE_ROOT /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp TMPDIR=/tmp DISPLAY=$DISPLAY_VALUE XKB_CONFIG_ROOT=$XKB_CONFIG_ROOT_RELATIVE $CHROOT_CAPTURE --window-ppm $window_id $CHROOT_X11_PPM" \
            >"$after_capture" 2>&1 || after_capture_status=$?
        echo "termux_x11_capture_status=$after_capture_status" >>"$after_capture"
        if [ "$after_capture_status" -ne 0 ]; then
            if [ "$ALLOW_X11_CAPTURE_FAILURE" -ne 1 ]; then
                exit 1
            fi
            echo "termux_x11_x11_capture_after_input=observational_failure step=$input_step status=$after_capture_status"
        else
            adb pull "$REMOTE_X11_PPM" "$after_ppm" >"$after_pull" 2>&1
            [ -s "$after_ppm" ]
            after_x11_sha=$(sha256sum "$after_ppm" | awk '{print $1}')
            if [ "$INPUT_MODE" = "android-keyevent" ]; then
                echo "termux_x11_x11_capture_after_input=pass sha256=$after_x11_sha"
            else
                echo "termux_x11_x11_capture_step_after_input=pass step=$input_step sha256=$after_x11_sha"
            fi
        fi

        adb exec-out screencap -p >"$after_android"
        [ -s "$after_android" ]
        adb shell dumpsys window windows >"$after_window"
        adb shell dumpsys input >"$after_focus"
        if ! focus_contains "$after_focus" 'com\.termux\.x11'; then
            if [ "$INPUT_MODE" = "android-keyevent" ]; then
                echo "termux_x11_input_focus_after=unknown_or_missing" >&2
            else
                echo "termux_x11_input_focus_after=fail step=$input_step" >&2
                exit 1
            fi
        else
            if [ "$INPUT_MODE" = "android-keyevent" ]; then
                echo "termux_x11_input_focus_after=pass"
            else
                echo "termux_x11_input_focus_after=pass step=$input_step"
            fi
        fi
        before_android_sha=$(sha256sum "$before_android" | awk '{print $1}')
        after_android_sha=$(sha256sum "$after_android" | awk '{print $1}')
        if [ "$INPUT_MODE" = "android-keyevent" ]; then
            echo "termux_x11_android_capture_after_input=pass sha256=$after_android_sha"
        else
            echo "termux_x11_android_capture_step_after_input=pass step=$input_step sha256=$after_android_sha"
        fi
        if [ "$before_android_sha" = "$after_android_sha" ]; then
            if [ "$INPUT_MODE" = "android-keyevent" ]; then
                echo "termux_x11_input_android_screen_changed=none"
            else
                echo "termux_x11_input_android_screen_changed=none step=$input_step"
            fi
        else
            if [ "$INPUT_MODE" = "android-keyevent" ]; then
                echo "termux_x11_input_android_screen_changed=pass"
            else
                echo "termux_x11_input_android_screen_changed=pass step=$input_step"
            fi
        fi
        if [ "$previous_x11_status" -eq 0 ] && [ "$after_capture_status" -eq 0 ]; then
            before_x11_sha=$(sha256sum "$before_ppm" | awk '{print $1}')
            after_x11_sha=$(sha256sum "$after_ppm" | awk '{print $1}')
            if [ "$before_x11_sha" = "$after_x11_sha" ]; then
                if [ "$INPUT_MODE" = "android-keyevent" ]; then
                    echo "termux_x11_input_x11_screen_changed=none"
                else
                    echo "termux_x11_input_x11_screen_changed=none step=$input_step"
                fi
            else
                if [ "$INPUT_MODE" = "android-keyevent" ]; then
                    echo "termux_x11_input_x11_screen_changed=pass"
                else
                    echo "termux_x11_input_x11_screen_changed=pass step=$input_step"
                fi
            fi
        fi
        previous_android="$after_android"
        previous_x11="$after_ppm"
        previous_x11_status=$after_capture_status
    done
    if [ "$INPUT_MODE" = "android-keyevent-sequence" ]; then
        echo "termux_x11_input_sequence=pass events=${#INPUT_SEQUENCE_CODES[@]}"
    fi
fi

sleep 1
