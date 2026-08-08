#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
PACKAGE=com.xjsonderulo.steamandroid.novalab
PID_FILE="$BUILD_DIR/native-steam-manual-session.pid"
LOG_FILE="$BUILD_DIR/native-steam-manual-session.log"

stop_remote_lab() {
    for remote_name in gamescope-headless nova-libei-input-bridge nova-uinput-gamepad-relay; do
        remote_pids=$("$ADB" shell pidof "$remote_name" 2>/dev/null | tr -d '\r' || true)
        if [ -n "$remote_pids" ]; then
            "$ADB" shell su -c "kill $remote_pids" >/dev/null 2>&1 || true
        fi
    done
    "$ADB" shell am force-stop "$PACKAGE" >/dev/null 2>&1 || true
}

if [ "${1:-}" = "stop" ]; then
    if [ ! -f "$PID_FILE" ]; then
        echo "native_steam_manual_session=not_running"
        exit 0
    fi
    session_pid=$(cat "$PID_FILE")
    if kill -0 "$session_pid" 2>/dev/null; then
        kill "$session_pid"
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
