#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
PACKAGE=com.xjsonderulo.steamandroid.novalab
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
RUNTIME_CLEANUP="$SCRIPT_DIR/device/nova-runtime-cleanup.sh"
DEVICE_RUNTIME_CLEANUP=/data/local/tmp/nova-runtime-cleanup.sh
PID_FILE="$BUILD_DIR/native-steam-manual-session.pid"
LOG_FILE="$BUILD_DIR/native-steam-manual-session.log"

cleanup_remote_runtime() {
    local push_status cleanup_status cleanup_output
    if "$ADB" push "$RUNTIME_CLEANUP" "$DEVICE_RUNTIME_CLEANUP" \
        >/dev/null 2>&1; then
        push_status=0
    else
        push_status=$?
    fi
    if [ "$push_status" -eq 0 ]; then
        if cleanup_output=$("$ADB" shell su -c \
            "/system/bin/sh $DEVICE_RUNTIME_CLEANUP $DEVICE_ROOT" 2>&1); then
            cleanup_status=0
        else
            cleanup_status=$?
        fi
    else
        cleanup_status=1
        cleanup_output=
    fi
    cleanup_output=$(printf '%s\n' "$cleanup_output" | tr -d '\r')
    printf '%s\n' "$cleanup_output"
    if [ "$push_status" -ne 0 ] || [ "$cleanup_status" -ne 0 ] || \
        ! printf '%s\n' "$cleanup_output" | rg -q '^nova_runtime_cleanup=pass '; then
        echo "native_steam_runtime_cleanup=fail push=$push_status command=$cleanup_status" >&2
        return 1
    fi
    echo "native_steam_runtime_cleanup=pass"
}

stop_remote_lab() {
    local cleanup_status=0
    cleanup_remote_runtime || cleanup_status=$?
    "$ADB" shell am force-stop "$PACKAGE" >/dev/null 2>&1 || true
    return "$cleanup_status"
}

if [ "${1:-}" = "stop" ]; then
    if [ ! -f "$PID_FILE" ]; then
        echo "native_steam_manual_session=not_running"
        stop_remote_lab
        exit 0
    fi
    session_pid=$(cat "$PID_FILE")
    if kill -0 "$session_pid" 2>/dev/null; then
        kill "$session_pid" 2>/dev/null || true
        echo "native_steam_manual_session=stopping pid=$session_pid"
    else
        echo "native_steam_manual_session=stale_pid pid=$session_pid"
    fi
    rm -f "$PID_FILE"
    stop_remote_lab
    exit 0
fi

if [ -f "$PID_FILE" ]; then
    session_pid=$(cat "$PID_FILE")
    if kill -0 "$session_pid" 2>/dev/null; then
        echo "native_steam_manual_session=already_running pid=$session_pid"
        exit 0
    fi
    rm -f "$PID_FILE"
fi

mkdir -p "$BUILD_DIR"
if [ ! -x "$BUILD_DIR/nova-uinput-gamepad-relay" ]; then
    "$SCRIPT_DIR/build-uinput-gamepad-relay.sh"
fi
if [ ! -x "$BUILD_DIR/nova-libei-input-bridge" ]; then
    "$SCRIPT_DIR/build-libei-input-bridge.sh"
fi

export INSTALL_HOLO_GAMESCOPE=${INSTALL_HOLO_GAMESCOPE:-0}
export NOVA_CONTROLLER_UI_INPUT_MODE=${NOVA_CONTROLLER_UI_INPUT_MODE:-physical}
export NOVA_CONTROLLER_UI_MANUAL_SESSION=1
export NOVA_CONTROLLER_UI_WAIT_TIMEOUT=${NOVA_CONTROLLER_UI_WAIT_TIMEOUT:-300}
export NOVA_CONTROLLER_UI_RELAY_TIMEOUT=${NOVA_CONTROLLER_UI_RELAY_TIMEOUT:-3600000}
export NOVA_AHB_FRAME_COUNT=${NOVA_AHB_FRAME_COUNT:--1}
export NOVA_AHB_WIDTH=${NOVA_AHB_WIDTH:-1280}
export NOVA_AHB_HEIGHT=${NOVA_AHB_HEIGHT:-960}
export NOVA_FULLSCREEN_PRESENTATION=${NOVA_FULLSCREEN_PRESENTATION:-1}
export NOVA_FULLSCREEN_WIDTH=${NOVA_FULLSCREEN_WIDTH:-1280}
export NOVA_FULLSCREEN_HEIGHT=${NOVA_FULLSCREEN_HEIGHT:-960}
export NOVA_GAMESCOPE_AHB_REQUIRE_TARGET=0
export NOVA_ANDROID_TOUCH_BRIDGE=1
export NOVA_EIS_TOUCH_BRIDGE=1
export NOVA_EIS_TOUCH_HELPER="$BUILD_DIR/nova-libei-input-bridge"
export NOVA_EIS_TOUCH_APP_SOCKET="@/data/user/0/com.xjsonderulo.steamandroid.novalab/files/nova-touch.sock"
export NOVA_EIS_TOUCH_TIMEOUT=${NOVA_EIS_TOUCH_TIMEOUT:-86400000}
export NOVA_EIS_TOUCH_CONTINUOUS=1
export NOVA_STEAM_CLIENT_TIMEOUT=${NOVA_STEAM_CLIENT_TIMEOUT:-86400}
export NOVA_STEAM_GAMESCOPE_TIMEOUT=${NOVA_STEAM_GAMESCOPE_TIMEOUT:-86400}

session_pid=$$
echo "$session_pid" >"$PID_FILE"
echo "native_steam_manual_session=starting pid=$session_pid"
echo "native_steam_manual_session_log=$LOG_FILE"
exec > >(tee "$LOG_FILE") 2>&1
exec "$SCRIPT_DIR/deploy-native-steam-controller-ui-input-smoke-test.sh"
