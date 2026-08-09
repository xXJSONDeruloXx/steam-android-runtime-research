#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
PACKAGE=com.xjsonderulo.steamandroid.novalab
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
RUN_PROFILE=${NOVA_RUN_PROFILE:-manual-bounded}
RUNTIME_CLEANUP="$SCRIPT_DIR/device/nova-runtime-cleanup.sh"
DEVICE_RUNTIME_CLEANUP=/data/local/tmp/nova-runtime-cleanup.sh
PID_FILE="$BUILD_DIR/native-steam-manual-session.pid"
LOG_FILE="$BUILD_DIR/native-steam-manual-session.log"

validate_timeout_value() {
    local name="$1"
    local value="$2"
    case "$value" in
        ''|*[!0-9]*)
            echo "$name must be a non-negative integer: $value" >&2
            return 1
            ;;
    esac
}

validate_manual_timeout_profile() {
    local client_timeout="$1"
    local gamescope_timeout="$2"
    local touch_timeout="$3"
    local relay_timeout="$4"

    validate_timeout_value NOVA_STEAM_CLIENT_TIMEOUT "$client_timeout"
    validate_timeout_value NOVA_STEAM_GAMESCOPE_TIMEOUT "$gamescope_timeout"
    validate_timeout_value NOVA_EIS_TOUCH_TIMEOUT "$touch_timeout"
    validate_timeout_value NOVA_CONTROLLER_UI_RELAY_TIMEOUT "$relay_timeout"

    if [ "$RUN_PROFILE" = "manual-long-lived" ]; then
        : "${NOVA_MANUAL_WATCHDOG_SECONDS:?manual-long-lived requires NOVA_MANUAL_WATCHDOG_SECONDS}"
        validate_timeout_value NOVA_MANUAL_WATCHDOG_SECONDS "$NOVA_MANUAL_WATCHDOG_SECONDS"
        if [ "$NOVA_MANUAL_WATCHDOG_SECONDS" -eq 0 ]; then
            echo "NOVA_MANUAL_WATCHDOG_SECONDS must be greater than zero" >&2
            return 1
        fi
        if ! command -v timeout >/dev/null 2>&1; then
            echo "manual-long-lived requires the host timeout command" >&2
            return 1
        fi
        echo "native_steam_timeout_profile=manual-long-lived watchdog_seconds=$NOVA_MANUAL_WATCHDOG_SECONDS"
        return 0
    fi

    if [ "$client_timeout" -gt 900 ] || [ "$gamescope_timeout" -gt 900 ] || \
        [ "$touch_timeout" -gt 900000 ] || [ "$relay_timeout" -gt 900000 ]; then
        echo "manual profile $RUN_PROFILE requires bounded timeouts (client/gamescope <= 900s, touch <= 900000ms, relay <= 900000ms)" >&2
        echo "use manual-long-lived with NOVA_MANUAL_WATCHDOG_SECONDS for an explicit long-lived session" >&2
        return 1
    fi
    echo "native_steam_timeout_profile=bounded max_client_seconds=900 max_gamescope_seconds=900 max_touch_ms=900000 max_relay_ms=900000"
}

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

clear_app_runtime_files() {
    if "$ADB" shell "run-as $PACKAGE sh -c 'rm -f files/nova-input.sock files/nova-touch.sock files/nova-lab-ahb-double-buffer.sock.* files/dmabuf-double-buffer-report.txt files/android-input-bridge-report.txt files/android-touch-bridge-report.txt'" \
        >/dev/null 2>&1; then
        echo "native_steam_app_files_cleanup=pass"
    else
        echo "native_steam_app_files_cleanup=fail" >&2
        return 1
    fi
}

clear_ahb_trace_state() {
    local status=0
    "$ADB" shell setprop debug.nova.ahb_trace 0 >/dev/null 2>&1 || status=$?
    "$ADB" shell setprop debug.nova.ahb_socket_trace 0 >/dev/null 2>&1 || status=$?
    "$ADB" shell setprop debug.nova.ahb_ack_poll_timeout_ms 0 >/dev/null 2>&1 || status=$?
    if ! "$ADB" shell \
        "su -c 'mkdir -p $DEVICE_ROOT/opt/nova-steam; printf \"0\\n\" > $DEVICE_ROOT/opt/nova-steam/ahb-trace; printf \"0\\n\" > $DEVICE_ROOT/opt/nova-steam/ahb-socket-trace'" \
        >/dev/null 2>&1; then
        status=1
    fi
    if [ "$status" -eq 0 ]; then
        echo "native_steam_ahb_trace_reset=pass"
        echo "native_steam_ahb_ack_poll_timeout_reset=pass"
    else
        echo "native_steam_ahb_trace_reset=fail" >&2
        echo "native_steam_ahb_ack_poll_timeout_reset=fail" >&2
    fi
    return "$status"
}

stop_remote_lab() {
    local cleanup_status=0
    local app_files_status=0
    local trace_status=0
    cleanup_remote_runtime || cleanup_status=$?
    "$ADB" shell am force-stop "$PACKAGE" >/dev/null 2>&1 || true
    clear_app_runtime_files || app_files_status=$?
    clear_ahb_trace_state || trace_status=$?
    if [ "$cleanup_status" -ne 0 ]; then
        return "$cleanup_status"
    fi
    if [ "$app_files_status" -ne 0 ]; then
        return "$app_files_status"
    fi
    return "$trace_status"
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
export NOVA_CONTROLLER_UI_RELAY_TIMEOUT=${NOVA_CONTROLLER_UI_RELAY_TIMEOUT:-900000}
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
export NOVA_EIS_TOUCH_TIMEOUT=${NOVA_EIS_TOUCH_TIMEOUT:-900000}
export NOVA_EIS_TOUCH_CONTINUOUS=1
export NOVA_STEAM_CLIENT_TIMEOUT=${NOVA_STEAM_CLIENT_TIMEOUT:-900}
export NOVA_STEAM_GAMESCOPE_TIMEOUT=${NOVA_STEAM_GAMESCOPE_TIMEOUT:-900}

validate_manual_timeout_profile \
    "$NOVA_STEAM_CLIENT_TIMEOUT" \
    "$NOVA_STEAM_GAMESCOPE_TIMEOUT" \
    "$NOVA_EIS_TOUCH_TIMEOUT" \
    "$NOVA_CONTROLLER_UI_RELAY_TIMEOUT"

session_pid=$$
echo "$session_pid" >"$PID_FILE"
echo "native_steam_manual_session=starting pid=$session_pid"
echo "native_steam_manual_session_log=$LOG_FILE"
exec > >(tee "$LOG_FILE") 2>&1
if [ "$RUN_PROFILE" = "manual-long-lived" ]; then
    exec timeout "$NOVA_MANUAL_WATCHDOG_SECONDS" \
        "$SCRIPT_DIR/deploy-native-steam-controller-ui-input-smoke-test.sh"
fi
exec "$SCRIPT_DIR/deploy-native-steam-controller-ui-input-smoke-test.sh"
