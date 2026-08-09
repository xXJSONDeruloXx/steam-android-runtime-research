#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
PACKAGE=com.xjsonderulo.steamandroid.novalab
SOCKET_NAME=nova-lab-ahb-double-buffer.sock
FRAME_COUNT=${NOVA_AHB_FRAME_COUNT:-60}
BUFFER_WIDTH=${NOVA_AHB_WIDTH:-64}
BUFFER_HEIGHT=${NOVA_AHB_HEIGHT:-64}
AHB_TRACE=${NOVA_AHB_TRACE:-0}
AHB_SOCKET_TRACE=${NOVA_AHB_SOCKET_TRACE:-0}
AHB_SCHEDULER_TRACE=${NOVA_AHB_SCHEDULER_TRACE:-0}
AHB_FRAME_IDENTITY=${NOVA_AHB_FRAME_IDENTITY:-0}
AHB_FRAME_MARKER=${NOVA_AHB_FRAME_MARKER:-0}
AHB_CONTENT_PROBE=${NOVA_AHB_CONTENT_PROBE:-0}
ANDROID_VULKAN_LAYOUT_PROBE=${NOVA_ANDROID_VULKAN_LAYOUT_PROBE:-0}
ANDROID_VULKAN_LAYOUT_WIDTH=${NOVA_ANDROID_VULKAN_LAYOUT_WIDTH:-$BUFFER_WIDTH}
ANDROID_VULKAN_LAYOUT_HEIGHT=${NOVA_ANDROID_VULKAN_LAYOUT_HEIGHT:-$BUFFER_HEIGHT}
ANDROID_VULKAN_LAYOUT_USAGE=${NOVA_ANDROID_VULKAN_LAYOUT_USAGE:-0x333}
OUTPUT_TILING=${NOVA_AHB_OUTPUT_TILING:-linear}
ACK_POLL_TIMEOUT_MS=${NOVA_AHB_ACK_POLL_TIMEOUT_MS:-0}
BINARY=${NOVA_GAMESCOPE_HEADLESS:-$BUILD_DIR/gamescope-headless-build/src/gamescope}
APK="$BUILD_DIR/nova-lab-debug.apk"
CLIENT=${NOVA_WAYLAND_SHM_CONTROL:-$BUILD_DIR/wayland-shm-control}
CONTROL=${NOVA_GAMESCOPE_AHB_CONTROL:-$SCRIPT_DIR/device/gamescope-headless-ahb-control.sh}
NETWORK_COMPAT=${NOVA_STEAM_NETWORK_API_COMPAT_HELPER:-$SCRIPT_DIR/device/nova-steam-network-api-compat.sh}
STEAMOS_UPDATE_COMPAT=${NOVA_STEAMOS_UPDATE_COMPAT_HELPER:-$SCRIPT_DIR/device/nova-steamos-update-compat.sh}
RUNTIME_CLEANUP="$SCRIPT_DIR/device/nova-runtime-cleanup.sh"
X11_CLIENT=${NOVA_GAMESCOPE_X11_CLIENT:-}
TOUCH_HELPER=${NOVA_EIS_TOUCH_HELPER:-}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
DEVICE_STAGE=/data/local/tmp/nova-gamescope-stage
DEVICE_RUNTIME_CLEANUP=/data/local/tmp/nova-runtime-cleanup.sh
DEVICE_DRIVER_DIR="$DEVICE_ROOT/opt/nova-kgsl-driver"
DEVICE_BINARY="$DEVICE_DRIVER_DIR/gamescope-headless"
DEVICE_CLIENT="$DEVICE_DRIVER_DIR/wayland-shm-control"
DEVICE_CONTROL="$DEVICE_DRIVER_DIR/gamescope-headless-ahb-control.sh"
DEVICE_NETWORK_COMPAT="$DEVICE_DRIVER_DIR/nova-steam-network-api-compat.sh"
DEVICE_STEAMOS_UPDATE_COMPAT="$DEVICE_ROOT/usr/bin/steamos-polkit-helpers/steamos-update"
DEVICE_TOUCH_HELPER="$DEVICE_DRIVER_DIR/nova-libei-input-bridge"
FRAME_MARKER_DECODER="$SCRIPT_DIR/decode-nova-ahb-frame-marker.py"
REPORT="$BUILD_DIR/device-gamescope-headless-ahb-report.txt"
LOGCAT="$BUILD_DIR/device-gamescope-headless-ahb-logcat.txt"
APP_REPORT="$BUILD_DIR/device-gamescope-headless-ahb-app-report.txt"
ANDROID_INPUT_REPORT="$BUILD_DIR/android-input-bridge-report.txt"
ANDROID_TOUCH_REPORT="$BUILD_DIR/android-touch-bridge-report.txt"
ANDROID_VULKAN_REPORT="$BUILD_DIR/android-vulkan-layout-report.txt"
SCREENSHOT="$BUILD_DIR/device-gamescope-headless-ahb-screenshot.png"
METADATA="$BUILD_DIR/device-gamescope-headless-ahb-metadata.txt"
PREFLIGHT="$BUILD_DIR/device-gamescope-headless-ahb-preflight.txt"
FRAME_MARKER_CAPTURE="$BUILD_DIR/ahb-frame-marker-screenshot.txt"
CLIENT_LOG="$BUILD_DIR/nova-steam-client.log"
CLIENT_STDOUT="$BUILD_DIR/nova-steam-client.stdout"
CLIENT_STDERR="$BUILD_DIR/nova-steam-client.stderr"
STEAM_LOG_DIAGNOSTICS="$BUILD_DIR/nova-steam-logs.txt"
SURFACEFLINGER_DIAGNOSTICS="$BUILD_DIR/device-surfaceflinger.txt"
REQUIRE_TARGET=${NOVA_GAMESCOPE_AHB_REQUIRE_TARGET:-1}
REQUIRE_RUN_MANIFEST=${NOVA_REQUIRE_RUN_MANIFEST:-0}
PRESENTATION_DIAGNOSTICS=${NOVA_CAPTURE_PRESENTATION_DIAGNOSTICS:-0}
RUN_PROFILE=${NOVA_RUN_PROFILE:-unclassified}
RUN_ID=${NOVA_RUN_ID:-legacy-$(date -u +%Y%m%dT%H%M%SZ)-$$}
RUN_DIR=${NOVA_RUN_DIR:-}
RUN_STARTED_UTC=${NOVA_RUN_STARTED_UTC:-$(date -u +%Y-%m-%dT%H:%M:%SZ)}

case "$AHB_TRACE" in
    0|1)
        ;;
    *)
        echo "NOVA_AHB_TRACE must be 0 or 1" >&2
        exit 2
        ;;
esac

case "$AHB_SOCKET_TRACE" in
    0|1)
        ;;
    *)
        echo "NOVA_AHB_SOCKET_TRACE must be 0 or 1" >&2
        exit 2
        ;;
esac

case "$AHB_SCHEDULER_TRACE" in
    0|1)
        ;;
    *)
        echo "NOVA_AHB_SCHEDULER_TRACE must be 0 or 1" >&2
        exit 2
        ;;
esac

case "$AHB_FRAME_IDENTITY" in
    0|1)
        ;;
    *)
        echo "NOVA_AHB_FRAME_IDENTITY must be 0 or 1" >&2
        exit 2
        ;;
esac

case "$AHB_FRAME_MARKER" in
    0|1)
        ;;
    *)
        echo "NOVA_AHB_FRAME_MARKER must be 0 or 1" >&2
        exit 2
        ;;
esac

case "$AHB_CONTENT_PROBE" in
    0|1)
        ;;
    *)
        echo "NOVA_AHB_CONTENT_PROBE must be 0 or 1" >&2
        exit 2
        ;;
esac

case "$ANDROID_VULKAN_LAYOUT_PROBE" in
    0|1)
        ;;
    *)
        echo "NOVA_ANDROID_VULKAN_LAYOUT_PROBE must be 0 or 1" >&2
        exit 2
        ;;
esac

case "$ANDROID_VULKAN_LAYOUT_WIDTH" in
    ''|*[!0-9]*)
        echo "NOVA_ANDROID_VULKAN_LAYOUT_WIDTH must be a positive integer" >&2
        exit 2
        ;;
esac
case "$ANDROID_VULKAN_LAYOUT_HEIGHT" in
    ''|*[!0-9]*)
        echo "NOVA_ANDROID_VULKAN_LAYOUT_HEIGHT must be a positive integer" >&2
        exit 2
        ;;
esac
if [ "$ANDROID_VULKAN_LAYOUT_WIDTH" -lt 1 ] || [ "$ANDROID_VULKAN_LAYOUT_WIDTH" -gt 4096 ] || \
    [ "$ANDROID_VULKAN_LAYOUT_HEIGHT" -lt 1 ] || [ "$ANDROID_VULKAN_LAYOUT_HEIGHT" -gt 4096 ]; then
    echo "Android Vulkan layout probe dimensions must be between 1 and 4096" >&2
    exit 2
fi
case "$ANDROID_VULKAN_LAYOUT_USAGE" in
    0x[0-9a-fA-F]*|0X[0-9a-fA-F]*|[0-9]*)
        ;;
    *)
        echo "NOVA_ANDROID_VULKAN_LAYOUT_USAGE must be decimal or hexadecimal" >&2
        exit 2
        ;;
esac

case "$OUTPUT_TILING" in
    linear|optimal)
        ;;
    *)
        echo "NOVA_AHB_OUTPUT_TILING must be linear or optimal" >&2
        exit 2
        ;;
esac

case "$ACK_POLL_TIMEOUT_MS" in
    ''|*[!0-9]*)
        echo "NOVA_AHB_ACK_POLL_TIMEOUT_MS must be a non-negative integer" >&2
        exit 2
        ;;
esac
if [ "$ACK_POLL_TIMEOUT_MS" -gt 600000 ]; then
    echo "NOVA_AHB_ACK_POLL_TIMEOUT_MS must be <= 600000" >&2
    exit 2
fi

case "$PRESENTATION_DIAGNOSTICS" in
    0|1)
        ;;
    *)
        echo "NOVA_CAPTURE_PRESENTATION_DIAGNOSTICS must be 0 or 1" >&2
        exit 2
        ;;
esac

case "$REQUIRE_RUN_MANIFEST" in
    0|1)
        ;;
    *)
        echo "NOVA_REQUIRE_RUN_MANIFEST must be 0 or 1" >&2
        exit 2
        ;;
esac

if [[ ! "$RUN_ID" =~ ^[A-Za-z0-9_.-]+$ ]]; then
    echo "invalid Nova run id: $RUN_ID" >&2
    exit 2
fi
if [ "$REQUIRE_RUN_MANIFEST" = "1" ] && [ -z "$RUN_DIR" ]; then
    echo "NOVA_REQUIRE_RUN_MANIFEST=1 requires NOVA_RUN_DIR" >&2
    exit 2
fi

if [ -n "$RUN_DIR" ]; then
    mkdir -p "$RUN_DIR"
    REPORT="$RUN_DIR/device-gamescope-headless-ahb-report.txt"
    LOGCAT="$RUN_DIR/device-gamescope-headless-ahb-logcat.txt"
    APP_REPORT="$RUN_DIR/device-gamescope-headless-ahb-app-report.txt"
    ANDROID_INPUT_REPORT="$RUN_DIR/android-input-bridge-report.txt"
    ANDROID_TOUCH_REPORT="$RUN_DIR/android-touch-bridge-report.txt"
    ANDROID_VULKAN_REPORT="$RUN_DIR/android-vulkan-layout-report.txt"
    SCREENSHOT="$RUN_DIR/device-gamescope-headless-ahb-screenshot.png"
    METADATA="$RUN_DIR/device-gamescope-headless-ahb-metadata.txt"
    PREFLIGHT="$RUN_DIR/device-gamescope-headless-ahb-preflight.txt"
    FRAME_MARKER_CAPTURE="$RUN_DIR/ahb-frame-marker-screenshot.txt"
    CLIENT_LOG="$RUN_DIR/nova-steam-client.log"
    CLIENT_STDOUT="$RUN_DIR/nova-steam-client.stdout"
    CLIENT_STDERR="$RUN_DIR/nova-steam-client.stderr"
    STEAM_LOG_DIAGNOSTICS="$RUN_DIR/nova-steam-logs.txt"
    SURFACEFLINGER_DIAGNOSTICS="$RUN_DIR/device-surfaceflinger.txt"
    if [ "$REQUIRE_RUN_MANIFEST" = "1" ]; then
        for run_artifact in "$REPORT" "$LOGCAT" "$APP_REPORT" "$SCREENSHOT" "$METADATA" "$PREFLIGHT"; do
            if [ -e "$run_artifact" ]; then
                echo "Nova run artifact already exists; use a fresh run id: $run_artifact" >&2
                exit 2
            fi
        done
        if [ "${NOVA_ANDROID_INPUT_BRIDGE:-0}" = "1" ] && [ -e "$ANDROID_INPUT_REPORT" ]; then
            echo "Nova run artifact already exists; use a fresh run id: $ANDROID_INPUT_REPORT" >&2
            exit 2
        fi
        if [ "${NOVA_ANDROID_TOUCH_BRIDGE:-0}" = "1" ] && [ -e "$ANDROID_TOUCH_REPORT" ]; then
            echo "Nova run artifact already exists; use a fresh run id: $ANDROID_TOUCH_REPORT" >&2
            exit 2
        fi
        if [ "$ANDROID_VULKAN_LAYOUT_PROBE" = "1" ] && [ -e "$ANDROID_VULKAN_REPORT" ]; then
            echo "Nova run artifact already exists; use a fresh run id: $ANDROID_VULKAN_REPORT" >&2
            exit 2
        fi
        if [ "$AHB_FRAME_MARKER" = "1" ] && [ -e "$FRAME_MARKER_CAPTURE" ]; then
            echo "Nova run artifact already exists; use a fresh run id: $FRAME_MARKER_CAPTURE" >&2
            exit 2
        fi
        if [ "$PRESENTATION_DIAGNOSTICS" = "1" ]; then
            for run_artifact in "$CLIENT_LOG" "$CLIENT_STDOUT" "$CLIENT_STDERR" "$STEAM_LOG_DIAGNOSTICS" "$SURFACEFLINGER_DIAGNOSTICS"; do
                if [ -e "$run_artifact" ]; then
                    echo "Nova run artifact already exists; use a fresh run id: $run_artifact" >&2
                    exit 2
                fi
            done
        fi
    fi
fi

for required in "$BINARY" "$CLIENT" "$CONTROL" "$RUNTIME_CLEANUP" "$STEAMOS_UPDATE_COMPAT"; do
    if [ ! -f "$required" ]; then
        echo "missing test input: $required" >&2
        echo "build gamescope and wayland-shm-control first" >&2
        exit 1
    fi
done
if [ -n "$X11_CLIENT" ] && [ ! -f "$X11_CLIENT" ]; then
    echo "missing X11 client: $X11_CLIENT" >&2
    exit 1
fi
if [ "$AHB_FRAME_MARKER" = "1" ]; then
    if [ ! -f "$FRAME_MARKER_DECODER" ]; then
        echo "missing frame-marker decoder: $FRAME_MARKER_DECODER" >&2
        exit 1
    fi
    if ! command -v python3 >/dev/null 2>&1; then
        echo "frame-marker capture requires python3" >&2
        exit 1
    fi
    if ! command -v ffmpeg >/dev/null 2>&1; then
        echo "frame-marker capture requires ffmpeg" >&2
        exit 1
    fi
fi

"$SCRIPT_DIR/build.sh" >/dev/null
"$ADB" wait-for-device
if [ ! -f "$APK" ]; then
    echo "missing built APK: $APK" >&2
    exit 1
fi
"$ADB" install -r -d "$APK" >/dev/null

if [ "${INSTALL_HOLO_GAMESCOPE:-1}" = "1" ]; then
    "$SCRIPT_DIR/install-holo-gamescope.sh" >/dev/null
fi
"$SCRIPT_DIR/deploy-kgsl-turnip.sh" >/dev/null

"$ADB" shell "su -c 'mkdir -p $DEVICE_STAGE $DEVICE_DRIVER_DIR; chmod 777 $DEVICE_STAGE'"
"$ADB" push "$BINARY" "$DEVICE_STAGE/gamescope-headless" >/dev/null
"$ADB" push "$CLIENT" "$DEVICE_STAGE/wayland-shm-control" >/dev/null
"$ADB" push "$CONTROL" "$DEVICE_STAGE/gamescope-headless-ahb-control.sh" >/dev/null
"$ADB" push "$RUNTIME_CLEANUP" "$DEVICE_STAGE/nova-runtime-cleanup.sh" >/dev/null
"$ADB" push "$STEAMOS_UPDATE_COMPAT" "$DEVICE_STAGE/nova-steamos-update-compat.sh" >/dev/null
if [ -f "$NETWORK_COMPAT" ]; then
    "$ADB" push "$NETWORK_COMPAT" "$DEVICE_STAGE/nova-steam-network-api-compat.sh" >/dev/null
fi
if [ -n "$X11_CLIENT" ]; then
    "$ADB" push "$X11_CLIENT" "$DEVICE_STAGE/nova-x11-animate" >/dev/null
fi
if [ -n "$TOUCH_HELPER" ]; then
    if [ ! -f "$TOUCH_HELPER" ]; then
        echo "missing EIS touch helper: $TOUCH_HELPER" >&2
        exit 1
    fi
    "$ADB" push "$TOUCH_HELPER" "$DEVICE_STAGE/nova-libei-input-bridge" >/dev/null
fi
"$ADB" shell "su -c 'cp $DEVICE_STAGE/gamescope-headless $DEVICE_BINARY; cp $DEVICE_STAGE/wayland-shm-control $DEVICE_CLIENT; cp $DEVICE_STAGE/gamescope-headless-ahb-control.sh $DEVICE_CONTROL; cp $DEVICE_STAGE/nova-runtime-cleanup.sh $DEVICE_RUNTIME_CLEANUP; mkdir -p $DEVICE_ROOT/usr/bin/steamos-polkit-helpers; cp $DEVICE_STAGE/nova-steamos-update-compat.sh $DEVICE_STEAMOS_UPDATE_COMPAT; chmod 755 $DEVICE_BINARY $DEVICE_CLIENT $DEVICE_CONTROL $DEVICE_RUNTIME_CLEANUP $DEVICE_STEAMOS_UPDATE_COMPAT'"
if [ -f "$NETWORK_COMPAT" ]; then
    "$ADB" shell "su -c 'cp $DEVICE_STAGE/nova-steam-network-api-compat.sh $DEVICE_NETWORK_COMPAT; chmod 755 $DEVICE_NETWORK_COMPAT'"
fi
if [ -n "$TOUCH_HELPER" ]; then
    "$ADB" shell "su -c 'cp $DEVICE_STAGE/nova-libei-input-bridge $DEVICE_TOUCH_HELPER; chmod 755 $DEVICE_TOUCH_HELPER'"
fi
if [ -n "$X11_CLIENT" ]; then
    "$ADB" shell "su -c 'cp $DEVICE_STAGE/nova-x11-animate $DEVICE_DRIVER_DIR/nova-x11-animate; chmod 755 $DEVICE_DRIVER_DIR/nova-x11-animate'"
fi

APP_DATA_DIR=$("$ADB" shell run-as "$PACKAGE" pwd | tr -d '\r')
SOCKET_HOST_DIR="$APP_DATA_DIR/files"

cleanup_runtime() {
    local cleanup_status=0 cleanup_output
    if cleanup_output=$("$ADB" shell su -c \
        "/system/bin/sh $DEVICE_RUNTIME_CLEANUP $DEVICE_ROOT" 2>&1); then
        cleanup_status=0
    else
        cleanup_status=$?
    fi
    cleanup_output=$(printf '%s\n' "$cleanup_output" | tr -d '\r')
    printf '%s\n' "$cleanup_output"
    if [ "$cleanup_status" -ne 0 ] || \
        ! printf '%s\n' "$cleanup_output" | rg -q '^nova_runtime_cleanup=pass '; then
        echo "nova_runtime_cleanup=fail command=$cleanup_status" >&2
        return 1
    fi
    echo "headless_ahb_runtime_cleanup=pass"
}
residual_runtime_check() {
    local process_list residual
    process_list=$("$ADB" shell su -c "/system/bin/ps -A -o PID,PPID,ARGS" 2>/dev/null | tr -d '\r')
    residual=$(printf '%s\n' "$process_list" | \
        rg -e "$DEVICE_ROOT/opt/nova-steam" \
           -e '/opt/nova-kgsl-driver/gamescope-headless' \
           -e '/opt/nova-kgsl-driver/nova-libei-input-bridge' \
           -e '/opt/nova-kgsl-driver/nova-uinput-gamepad-relay' | \
        rg -v 'nova-runtime-cleanup|ps -A -o PID,PPID,ARGS' || true)
    if [ -n "$residual" ]; then
        echo "headless_ahb_residual_processes=fail" >&2
        printf '%s\n' "$residual" >&2
        return 1
    fi
    echo "headless_ahb_residual_processes=pass"
}
cleanup_on_exit() {
    local original_status=$? cleanup_status residual_status app_files_status trace_status socket_trace_status scheduler_trace_status frame_identity_status frame_marker_status content_probe_status android_vulkan_layout_status ack_poll_status
    trap - EXIT
    set +e
    cleanup_runtime
    cleanup_status=$?
    residual_runtime_check
    residual_status=$?
    clear_app_runtime_files
    app_files_status=$?
    set_ahb_trace_state 0
    trace_status=$?
    set_ahb_socket_trace_state 0
    socket_trace_status=$?
    set_ahb_scheduler_trace_state 0
    scheduler_trace_status=$?
    set_ahb_frame_identity_state 0
    frame_identity_status=$?
    set_ahb_frame_marker_state 0
    frame_marker_status=$?
    set_ahb_content_probe_state 0
    content_probe_status=$?
    set_android_vulkan_layout_state 0
    android_vulkan_layout_status=$?
    set_ahb_ack_poll_timeout_state 0
    ack_poll_status=$?
    if [ "$original_status" -ne 0 ]; then
        exit "$original_status"
    fi
    if [ "$cleanup_status" -ne 0 ] || [ "$residual_status" -ne 0 ] || \
        [ "$app_files_status" -ne 0 ] || [ "$trace_status" -ne 0 ] || \
        [ "$socket_trace_status" -ne 0 ] || [ "$scheduler_trace_status" -ne 0 ] || \
        [ "$frame_identity_status" -ne 0 ] || \
        [ "$frame_marker_status" -ne 0 ] || [ "$content_probe_status" -ne 0 ] || \
        [ "$android_vulkan_layout_status" -ne 0 ] || [ "$ack_poll_status" -ne 0 ]; then
        exit 1
    fi
    exit 0
}
clear_app_runtime_files() {
    if "$ADB" shell "run-as $PACKAGE sh -c 'rm -f files/nova-input.sock files/nova-touch.sock files/nova-lab-ahb-double-buffer.sock.* files/dmabuf-double-buffer-report.txt files/android-vulkan-layout-report.txt files/android-input-bridge-report.txt files/android-touch-bridge-report.txt'" \
        >/dev/null 2>&1; then
        echo "nova_app_runtime_files_cleanup=pass"
    else
        echo "nova_app_runtime_files_cleanup=fail" >&2
        return 1
    fi
}
set_ahb_trace_state() {
    local value=$1 status=0
    "$ADB" shell setprop debug.nova.ahb_trace "$value" >/dev/null 2>&1 || status=$?
    if ! "$ADB" shell \
        "su -c 'mkdir -p $DEVICE_ROOT/opt/nova-steam; printf \"%s\\n\" \"$value\" > $DEVICE_ROOT/opt/nova-steam/ahb-trace'" \
        >/dev/null 2>&1; then
        status=1
    fi
    return "$status"
}
set_ahb_socket_trace_state() {
    local value=$1 status=0
    "$ADB" shell setprop debug.nova.ahb_socket_trace "$value" >/dev/null 2>&1 || status=$?
    if ! "$ADB" shell \
        "su -c 'mkdir -p $DEVICE_ROOT/opt/nova-steam; printf \"%s\\n\" \"$value\" > $DEVICE_ROOT/opt/nova-steam/ahb-socket-trace'" \
        >/dev/null 2>&1; then
        status=1
    fi
    return "$status"
}
set_ahb_scheduler_trace_state() {
    local value=$1 status=0
    "$ADB" shell setprop debug.nova.ahb_scheduler_trace "$value" \
        >/dev/null 2>&1 || status=$?
    if ! "$ADB" shell \
        "su -c 'mkdir -p $DEVICE_ROOT/opt/nova-steam; printf \"%s\\n\" \"$value\" > $DEVICE_ROOT/opt/nova-steam/ahb-scheduler-trace'" \
        >/dev/null 2>&1; then
        status=1
    fi
    return "$status"
}
set_ahb_frame_identity_state() {
    local value=$1 status=0
    "$ADB" shell setprop debug.nova.ahb_frame_identity "$value" \
        >/dev/null 2>&1 || status=$?
    return "$status"
}
set_ahb_frame_marker_state() {
    local value=$1 status=0
    "$ADB" shell setprop debug.nova.ahb_frame_marker "$value" \
        >/dev/null 2>&1 || status=$?
    return "$status"
}
set_ahb_content_probe_state() {
    local value=$1 status=0
    "$ADB" shell setprop debug.nova.ahb_content_probe "$value" \
        >/dev/null 2>&1 || status=$?
    return "$status"
}
set_android_vulkan_layout_state() {
    local value=$1 status=0
    if [ "$value" = "1" ]; then
        "$ADB" shell setprop debug.nova.ahb_layout_width "$ANDROID_VULKAN_LAYOUT_WIDTH" \
            >/dev/null 2>&1 || status=$?
        "$ADB" shell setprop debug.nova.ahb_layout_height "$ANDROID_VULKAN_LAYOUT_HEIGHT" \
            >/dev/null 2>&1 || status=$?
        "$ADB" shell setprop debug.nova.ahb_layout_usage "$ANDROID_VULKAN_LAYOUT_USAGE" \
            >/dev/null 2>&1 || status=$?
    else
        "$ADB" shell setprop debug.nova.ahb_layout_width 0 >/dev/null 2>&1 || status=$?
        "$ADB" shell setprop debug.nova.ahb_layout_height 0 >/dev/null 2>&1 || status=$?
        "$ADB" shell setprop debug.nova.ahb_layout_usage 0 >/dev/null 2>&1 || status=$?
    fi
    return "$status"
}
set_ahb_ack_poll_timeout_state() {
    local value=$1 status=0
    "$ADB" shell setprop debug.nova.ahb_ack_poll_timeout_ms "$value" \
        >/dev/null 2>&1 || status=$?
    return "$status"
}
capture_remote_diagnostic() {
    local remote_path=$1 output_path=$2 diagnostic_name=$3
    local temporary_path="${output_path}.tmp"
    local header_path="${output_path}.header"
    local capture_status=0

    if "$ADB" shell \
        "su -c 'if [ -f \"$remote_path\" ]; then cat \"$remote_path\"; else exit 1; fi'" \
        2>/dev/null | tr -d '\r' >"$temporary_path"; then
        capture_status=0
    else
        capture_status=$?
    fi
    {
        echo "nova_run_id=$RUN_ID"
        echo "nova_diagnostic_name=$diagnostic_name"
        echo "nova_diagnostic_remote=$remote_path"
        if [ "$capture_status" -eq 0 ]; then
            echo "nova_diagnostic_status=present"
        else
            echo "nova_diagnostic_status=missing adb_status=$capture_status"
        fi
    } >"$header_path"
    if [ "$capture_status" -eq 0 ]; then
        cat "$header_path" "$temporary_path" >"$output_path"
    else
        mv "$header_path" "$output_path"
    fi
    rm -f "$header_path" "$temporary_path"
    return "$capture_status"
}
capture_steam_log_diagnostics() {
    local temporary_path="${STEAM_LOG_DIAGNOSTICS}.tmp"
    local log_temporary_path
    local remote_path
    local log_status
    local present_count=0
    local missing_count=0
    local log_name

    {
        echo "nova_run_id=$RUN_ID"
        echo "nova_diagnostic_name=steam_logs"
        echo "nova_diagnostic_status=best_effort"
        echo "nova_steam_log_directory=$DEVICE_ROOT/opt/nova-steam/home/.local/share/Steam/logs"
    } >"$temporary_path"
    for log_name in console_log steamui_html webhelper webhelper_js webhelper_gpu connection_log cef_log; do
        remote_path="$DEVICE_ROOT/opt/nova-steam/home/.local/share/Steam/logs/$log_name.txt"
        log_temporary_path="${temporary_path}.${log_name}"
        if "$ADB" shell \
            "su -c 'if [ -f \"$remote_path\" ]; then cat \"$remote_path\"; else exit 1; fi'" \
            2>/dev/null | tr -d '\r' >"$log_temporary_path"; then
            log_status=present
            present_count=$((present_count + 1))
        else
            log_status=missing
            missing_count=$((missing_count + 1))
        fi
        {
            echo "nova_steam_log=$log_name"
            echo "nova_steam_log_status=$log_status"
            if [ "$log_status" = "present" ]; then
                cat "$log_temporary_path"
            fi
            echo "nova_steam_log_end=$log_name"
        } >>"$temporary_path"
        rm -f "$log_temporary_path"
    done
    {
        echo "nova_steam_logs_present=$present_count"
        echo "nova_steam_logs_missing=$missing_count"
    } >>"$temporary_path"
    mv "$temporary_path" "$STEAM_LOG_DIAGNOSTICS"
}
capture_surfaceflinger_diagnostics() {
    local temporary_path="${SURFACEFLINGER_DIAGNOSTICS}.tmp"
    local dump_temporary_path
    local dump_status
    local dump_name

    {
        echo "nova_run_id=$RUN_ID"
        echo "nova_diagnostic_name=surfaceflinger"
        echo "nova_diagnostic_status=best_effort"
    } >"$temporary_path"
    for dump_name in list layers; do
        dump_temporary_path="${temporary_path}.${dump_name}"
        if "$ADB" shell dumpsys SurfaceFlinger "--$dump_name" 2>&1 | \
            tr -d '\r' >"$dump_temporary_path"; then
            dump_status=pass
        else
            dump_status=fail
        fi
        {
            echo "nova_surfaceflinger_dump=$dump_name"
            echo "nova_surfaceflinger_dump_status=$dump_status"
            cat "$dump_temporary_path"
            echo "nova_surfaceflinger_dump_end=$dump_name"
        } >>"$temporary_path"
        rm -f "$dump_temporary_path"
    done
    mv "$temporary_path" "$SURFACEFLINGER_DIAGNOSTICS"
}
capture_presentation_diagnostics() {
    local client_log_status=0
    local client_stdout_status=0
    local client_stderr_status=0

    if [ "$PRESENTATION_DIAGNOSTICS" != "1" ]; then
        return 0
    fi
    capture_remote_diagnostic \
        "$DEVICE_ROOT/tmp/nova-steam-client.log" "$CLIENT_LOG" \
        nova_steam_client_log || client_log_status=$?
    capture_remote_diagnostic \
        "$DEVICE_ROOT/tmp/nova-steam-client.stdout" "$CLIENT_STDOUT" \
        nova_steam_client_stdout || client_stdout_status=$?
    capture_remote_diagnostic \
        "$DEVICE_ROOT/tmp/nova-steam-client.stderr" "$CLIENT_STDERR" \
        nova_steam_client_stderr || client_stderr_status=$?
    capture_steam_log_diagnostics
    capture_surfaceflinger_diagnostics
    echo "nova_presentation_diagnostics=pass client_log_status=$client_log_status client_stdout_status=$client_stdout_status client_stderr_status=$client_stderr_status"
    echo "steam diagnostics: $CLIENT_LOG $CLIENT_STDOUT $CLIENT_STDERR $STEAM_LOG_DIAGNOSTICS"
    echo "SurfaceFlinger diagnostics: $SURFACEFLINGER_DIAGNOSTICS"
}
run_preflight_gate() {
    local gate_status=0
    local force_stop_status=0
    local cleanup_status=0
    local residual_status=0
    local app_files_status=0
    local trace_status=0
    local socket_trace_status=0
    local scheduler_trace_status=0
    local frame_identity_status=0
    local frame_marker_status=0
    local content_probe_status=0
    local android_vulkan_layout_status=0
    local ack_poll_status=0
    local cleanup_output residual_output app_files_output
    local trace_prop trace_file socket_trace_prop socket_trace_file scheduler_trace_prop scheduler_trace_file frame_identity_prop frame_marker_prop content_probe_prop android_vulkan_layout_width_prop android_vulkan_layout_height_prop android_vulkan_layout_usage_prop ack_poll_prop
    local attempt

    {
        echo "preflight_manifest=begin"
        echo "preflight_run_id=$RUN_ID"
        echo "preflight_profile=$RUN_PROFILE"
        echo "preflight_run_dir=${RUN_DIR:-unset}"
        echo "preflight_remote_force_stop=adb shell am force-stop $PACKAGE"
        echo "preflight_remote_cleanup=adb shell su -c '/system/bin/sh $DEVICE_RUNTIME_CLEANUP $DEVICE_ROOT'"
        echo "preflight_remote_process_check=adb shell su -c '/system/bin/ps -A -o PID,PPID,ARGS'"
        echo "preflight_remote_app_file_cleanup=adb shell run-as $PACKAGE sh -c 'rm -f files/nova-input.sock files/nova-touch.sock files/nova-lab-ahb-double-buffer.sock.* files/dmabuf-double-buffer-report.txt files/android-vulkan-layout-report.txt files/android-input-bridge-report.txt files/android-touch-bridge-report.txt'"
        echo "preflight_remote_ahb_trace_reset=adb shell setprop debug.nova.ahb_trace 0; adb shell su -c 'printf 0 > $DEVICE_ROOT/opt/nova-steam/ahb-trace'"
        echo "preflight_remote_socket_trace_reset=adb shell setprop debug.nova.ahb_socket_trace 0; adb shell su -c 'printf 0 > $DEVICE_ROOT/opt/nova-steam/ahb-socket-trace'"
        echo "preflight_remote_scheduler_trace_reset=adb shell setprop debug.nova.ahb_scheduler_trace 0; adb shell su -c 'printf 0 > $DEVICE_ROOT/opt/nova-steam/ahb-scheduler-trace'"
        echo "preflight_remote_frame_identity_reset=adb shell setprop debug.nova.ahb_frame_identity 0"
        echo "preflight_remote_frame_marker_reset=adb shell setprop debug.nova.ahb_frame_marker 0"
        echo "preflight_remote_content_probe_reset=adb shell setprop debug.nova.ahb_content_probe 0"
        echo "preflight_remote_android_vulkan_layout_reset=adb shell setprop debug.nova.ahb_layout_width 0; setprop debug.nova.ahb_layout_height 0; setprop debug.nova.ahb_layout_usage 0"
        echo "preflight_ahb_output_tiling=$OUTPUT_TILING"
        echo "preflight_remote_ack_poll_timeout_reset=adb shell setprop debug.nova.ahb_ack_poll_timeout_ms 0"
        echo "preflight_expected_artifact=$BINARY"
        echo "preflight_expected_artifact=$APK"
        echo "preflight_metadata=$METADATA"
        echo "preflight_manifest_path=$PREFLIGHT"
        cat "$METADATA"
    } >"$PREFLIGHT"

    if "$ADB" shell am force-stop "$PACKAGE" >/dev/null 2>&1; then
        force_stop_status=0
        echo "preflight_force_stop=pass" >>"$PREFLIGHT"
    else
        force_stop_status=$?
        gate_status=1
        echo "preflight_force_stop=fail status=$force_stop_status" >>"$PREFLIGHT"
    fi

    for attempt in 1 2; do
        echo "preflight_cleanup_attempt=$attempt" >>"$PREFLIGHT"

        if cleanup_output=$(cleanup_runtime 2>&1); then
            cleanup_status=0
        else
            cleanup_status=$?
        fi
        cleanup_output=$(printf '%s\n' "$cleanup_output" | tr -d '\r')
        printf '%s\n' "$cleanup_output" >>"$PREFLIGHT"
        if [ "$cleanup_status" -ne 0 ] || \
            ! printf '%s\n' "$cleanup_output" | rg -q '^nova_runtime_cleanup=pass '; then
            gate_status=1
            echo "preflight_cleanup=fail attempt=$attempt status=$cleanup_status" >>"$PREFLIGHT"
        else
            echo "preflight_cleanup=pass attempt=$attempt" >>"$PREFLIGHT"
        fi

        if residual_output=$(residual_runtime_check 2>&1); then
            residual_status=0
        else
            residual_status=$?
        fi
        residual_output=$(printf '%s\n' "$residual_output" | tr -d '\r')
        printf '%s\n' "$residual_output" >>"$PREFLIGHT"
        if [ "$residual_status" -ne 0 ] || \
            ! printf '%s\n' "$residual_output" | rg -q '^headless_ahb_residual_processes=pass$'; then
            gate_status=1
            echo "preflight_residual_processes=fail attempt=$attempt status=$residual_status" >>"$PREFLIGHT"
        else
            echo "preflight_residual_processes=pass attempt=$attempt" >>"$PREFLIGHT"
        fi

        if app_files_output=$(clear_app_runtime_files 2>&1); then
            app_files_status=0
        else
            app_files_status=$?
        fi
        app_files_output=$(printf '%s\n' "$app_files_output" | tr -d '\r')
        printf '%s\n' "$app_files_output" >>"$PREFLIGHT"
        if [ "$app_files_status" -ne 0 ] || \
            ! printf '%s\n' "$app_files_output" | rg -q '^nova_app_runtime_files_cleanup=pass$'; then
            gate_status=1
            echo "preflight_app_files=fail attempt=$attempt status=$app_files_status" >>"$PREFLIGHT"
        else
            echo "preflight_app_files=pass attempt=$attempt" >>"$PREFLIGHT"
        fi

        trace_status=0
        set_ahb_trace_state 0 || trace_status=$?
        socket_trace_status=0
        set_ahb_socket_trace_state 0 || socket_trace_status=$?
        scheduler_trace_status=0
        set_ahb_scheduler_trace_state 0 || scheduler_trace_status=$?
        frame_identity_status=0
        set_ahb_frame_identity_state 0 || frame_identity_status=$?
        frame_marker_status=0
        set_ahb_frame_marker_state 0 || frame_marker_status=$?
        content_probe_status=0
        set_ahb_content_probe_state 0 || content_probe_status=$?
        android_vulkan_layout_status=0
        set_android_vulkan_layout_state 0 || android_vulkan_layout_status=$?
        ack_poll_status=0
        set_ahb_ack_poll_timeout_state 0 || ack_poll_status=$?
        trace_prop=$({ "$ADB" shell getprop debug.nova.ahb_trace || true; } | tr -d '\r' | tail -n 1)
        trace_file=$({ "$ADB" shell su -c "cat $DEVICE_ROOT/opt/nova-steam/ahb-trace" || true; } | tr -d '\r' | tail -n 1)
        socket_trace_prop=$({ "$ADB" shell getprop debug.nova.ahb_socket_trace || true; } | tr -d '\r' | tail -n 1)
        socket_trace_file=$({ "$ADB" shell su -c "cat $DEVICE_ROOT/opt/nova-steam/ahb-socket-trace" || true; } | tr -d '\r' | tail -n 1)
        scheduler_trace_prop=$({ "$ADB" shell getprop debug.nova.ahb_scheduler_trace || true; } | tr -d '\r' | tail -n 1)
        scheduler_trace_file=$({ "$ADB" shell su -c "cat $DEVICE_ROOT/opt/nova-steam/ahb-scheduler-trace" || true; } | tr -d '\r' | tail -n 1)
        frame_identity_prop=$({ "$ADB" shell getprop debug.nova.ahb_frame_identity || true; } | tr -d '\r' | tail -n 1)
        frame_marker_prop=$({ "$ADB" shell getprop debug.nova.ahb_frame_marker || true; } | tr -d '\r' | tail -n 1)
        content_probe_prop=$({ "$ADB" shell getprop debug.nova.ahb_content_probe || true; } | tr -d '\r' | tail -n 1)
        android_vulkan_layout_width_prop=$({ "$ADB" shell getprop debug.nova.ahb_layout_width || true; } | tr -d '\r' | tail -n 1)
        android_vulkan_layout_height_prop=$({ "$ADB" shell getprop debug.nova.ahb_layout_height || true; } | tr -d '\r' | tail -n 1)
        android_vulkan_layout_usage_prop=$({ "$ADB" shell getprop debug.nova.ahb_layout_usage || true; } | tr -d '\r' | tail -n 1)
        ack_poll_prop=$({ "$ADB" shell getprop debug.nova.ahb_ack_poll_timeout_ms || true; } | tr -d '\r' | tail -n 1)
        echo "preflight_ahb_trace_reset_status=$trace_status prop=$trace_prop file=$trace_file" >>"$PREFLIGHT"
        echo "preflight_socket_trace_reset_status=$socket_trace_status prop=$socket_trace_prop file=$socket_trace_file" >>"$PREFLIGHT"
        echo "preflight_scheduler_trace_reset_status=$scheduler_trace_status prop=$scheduler_trace_prop file=$scheduler_trace_file" >>"$PREFLIGHT"
        echo "preflight_frame_identity_reset_status=$frame_identity_status prop=$frame_identity_prop" >>"$PREFLIGHT"
        echo "preflight_frame_marker_reset_status=$frame_marker_status prop=$frame_marker_prop" >>"$PREFLIGHT"
        echo "preflight_content_probe_reset_status=$content_probe_status prop=$content_probe_prop" >>"$PREFLIGHT"
        echo "preflight_android_vulkan_layout_reset_status=$android_vulkan_layout_status width=$android_vulkan_layout_width_prop height=$android_vulkan_layout_height_prop usage=$android_vulkan_layout_usage_prop" >>"$PREFLIGHT"
        echo "preflight_ack_poll_timeout_reset_status=$ack_poll_status prop=$ack_poll_prop" >>"$PREFLIGHT"
        if [ "$trace_status" -ne 0 ] || [ "$trace_prop" != "0" ] || [ "$trace_file" != "0" ]; then
            gate_status=1
            echo "preflight_ahb_trace_reset=fail attempt=$attempt" >>"$PREFLIGHT"
        else
            echo "preflight_ahb_trace_reset=pass attempt=$attempt" >>"$PREFLIGHT"
        fi
        if [ "$socket_trace_status" -ne 0 ] || [ "$socket_trace_prop" != "0" ] || [ "$socket_trace_file" != "0" ]; then
            gate_status=1
            echo "preflight_socket_trace_reset=fail attempt=$attempt" >>"$PREFLIGHT"
        else
            echo "preflight_socket_trace_reset=pass attempt=$attempt" >>"$PREFLIGHT"
        fi
        if [ "$scheduler_trace_status" -ne 0 ] || [ "$scheduler_trace_prop" != "0" ] || [ "$scheduler_trace_file" != "0" ]; then
            gate_status=1
            echo "preflight_scheduler_trace_reset=fail attempt=$attempt" >>"$PREFLIGHT"
        else
            echo "preflight_scheduler_trace_reset=pass attempt=$attempt" >>"$PREFLIGHT"
        fi
        if [ "$frame_identity_status" -ne 0 ] || [ "$frame_identity_prop" != "0" ]; then
            gate_status=1
            echo "preflight_frame_identity_reset=fail attempt=$attempt" >>"$PREFLIGHT"
        else
            echo "preflight_frame_identity_reset=pass attempt=$attempt" >>"$PREFLIGHT"
        fi
        if [ "$frame_marker_status" -ne 0 ] || [ "$frame_marker_prop" != "0" ]; then
            gate_status=1
            echo "preflight_frame_marker_reset=fail attempt=$attempt" >>"$PREFLIGHT"
        else
            echo "preflight_frame_marker_reset=pass attempt=$attempt" >>"$PREFLIGHT"
        fi
        if [ "$content_probe_status" -ne 0 ] || [ "$content_probe_prop" != "0" ]; then
            gate_status=1
            echo "preflight_content_probe_reset=fail attempt=$attempt" >>"$PREFLIGHT"
        else
            echo "preflight_content_probe_reset=pass attempt=$attempt" >>"$PREFLIGHT"
        fi
        if [ "$android_vulkan_layout_status" -ne 0 ] || \
            [ "$android_vulkan_layout_width_prop" != "0" ] || \
            [ "$android_vulkan_layout_height_prop" != "0" ] || \
            [ "$android_vulkan_layout_usage_prop" != "0" ]; then
            gate_status=1
            echo "preflight_android_vulkan_layout_reset=fail attempt=$attempt" >>"$PREFLIGHT"
        else
            echo "preflight_android_vulkan_layout_reset=pass attempt=$attempt" >>"$PREFLIGHT"
        fi
        if [ "$ack_poll_status" -ne 0 ] || [ "$ack_poll_prop" != "0" ]; then
            gate_status=1
            echo "preflight_ack_poll_timeout_reset=fail attempt=$attempt" >>"$PREFLIGHT"
        else
            echo "preflight_ack_poll_timeout_reset=pass attempt=$attempt" >>"$PREFLIGHT"
        fi
    done

    if [ "$force_stop_status" -ne 0 ] || [ "$gate_status" -ne 0 ]; then
        echo "preflight_manifest=fail run_id=$RUN_ID" >>"$PREFLIGHT"
        echo "Nova preflight failed; inspect $PREFLIGHT" >&2
        return 1
    fi
    echo "preflight_manifest=pass run_id=$RUN_ID" >>"$PREFLIGHT"
    echo "nova_preflight=pass manifest=$PREFLIGHT"
}
trap cleanup_on_exit EXIT

{
    libei_build_marker=$(strings "$BINARY" | rg -m1 -i 'successfully initialized libei|built without libei' || true)
    echo "nova_run_id=$RUN_ID"
    echo "nova_run_profile=$RUN_PROFILE"
    echo "run_started_utc=$RUN_STARTED_UTC"
    echo "gamescope_binary=$BINARY"
    echo "gamescope_binary_sha256=$(shasum -a 256 "$BINARY" | awk '{print $1}')"
    if printf '%s\n' "$libei_build_marker" | rg -qi 'successfully initialized libei'; then
        echo "gamescope_libei_build=enabled"
    elif printf '%s\n' "$libei_build_marker" | rg -qi 'built without libei'; then
        echo "gamescope_libei_build=disabled"
    else
        echo "gamescope_libei_build=unknown"
    fi
    echo "gamescope_input_emulation=${NOVA_GAMESCOPE_INPUT_EMULATION:-unset}"
    echo "nova_apk=$APK"
    echo "nova_apk_sha256=$(shasum -a 256 "$APK" | awk '{print $1}')"
    echo "gamescope_source_tree=${GAMESCOPE_HEADLESS_SOURCE:-unset}"
    if [ -n "${GAMESCOPE_HEADLESS_SOURCE:-}" ] && \
        git -C "$GAMESCOPE_HEADLESS_SOURCE" rev-parse --git-dir >/dev/null 2>&1; then
        source_status=$(git -C "$GAMESCOPE_HEADLESS_SOURCE" \
            status --porcelain=v1 --untracked-files=all)
        source_submodules=$(git -C "$GAMESCOPE_HEADLESS_SOURCE" \
            submodule status --recursive 2>/dev/null || true)
        echo "gamescope_source_commit=$(git -C "$GAMESCOPE_HEADLESS_SOURCE" rev-parse HEAD)"
        echo "gamescope_source_dirty=$([ -n "$source_status" ] && echo 1 || echo 0)"
        echo "gamescope_source_status_sha256=$(printf '%s' "$source_status" | shasum -a 256 | awk '{print $1}')"
        echo "gamescope_source_diff_sha256=$(git -C "$GAMESCOPE_HEADLESS_SOURCE" diff --binary HEAD | shasum -a 256 | awk '{print $1}')"
        echo "gamescope_source_submodules_sha256=$(printf '%s' "$source_submodules" | shasum -a 256 | awk '{print $1}')"
    else
        echo "gamescope_source_commit=unknown"
        echo "gamescope_source_dirty=unknown"
        echo "gamescope_source_status_sha256=unknown"
        echo "gamescope_source_diff_sha256=unknown"
        echo "gamescope_source_submodules_sha256=unknown"
    fi
    echo "fullscreen_presentation=${NOVA_FULLSCREEN_PRESENTATION:-0}"
    echo "force_gpu_composition=${NOVA_FORCE_GPU_COMPOSITION:-unset}"
    echo "nova_ahb_trace=$AHB_TRACE"
    echo "nova_ahb_socket_trace=$AHB_SOCKET_TRACE"
    echo "nova_ahb_scheduler_trace=$AHB_SCHEDULER_TRACE"
    echo "nova_ahb_frame_identity=$AHB_FRAME_IDENTITY"
    echo "nova_ahb_frame_marker=$AHB_FRAME_MARKER"
    echo "nova_ahb_content_probe=$AHB_CONTENT_PROBE"
    echo "android_vulkan_layout_probe=$ANDROID_VULKAN_LAYOUT_PROBE"
    echo "android_vulkan_layout_profile=${ANDROID_VULKAN_LAYOUT_WIDTH}x${ANDROID_VULKAN_LAYOUT_HEIGHT} usage=$ANDROID_VULKAN_LAYOUT_USAGE"
    echo "nova_ahb_output_tiling=$OUTPUT_TILING"
    echo "nova_ahb_ack_poll_timeout_ms=$ACK_POLL_TIMEOUT_MS"
    echo "presentation_diagnostics=$PRESENTATION_DIAGNOSTICS"
    echo "steam_client_timeout=${NOVA_STEAM_CLIENT_TIMEOUT:-unset}"
    echo "steam_gamescope_timeout=${NOVA_STEAM_GAMESCOPE_TIMEOUT:-unset}"
    echo "steamos_update_compat=installed"
} >"$METADATA"
cat "$METADATA"

if [ "${NOVA_REQUIRE_GAMESCOPE_PROVENANCE:-0}" = "1" ]; then
    if ! rg -q '^gamescope_binary_sha256=[0-9a-f]{64}$' "$METADATA" || \
        ! rg -q '^nova_apk_sha256=[0-9a-f]{64}$' "$METADATA" || \
        ! rg -q '^gamescope_source_tree=[^u].+' "$METADATA" || \
        ! rg -q '^gamescope_source_commit=[0-9a-f]{40}$' "$METADATA" || \
        ! rg -q '^gamescope_source_status_sha256=[0-9a-f]{64}$' "$METADATA" || \
        ! rg -q '^gamescope_source_diff_sha256=[0-9a-f]{64}$' "$METADATA" || \
        ! rg -q '^gamescope_source_submodules_sha256=[0-9a-f]{64}$' "$METADATA"; then
        echo "missing required Gamescope provenance" >&2
        exit 1
    fi
fi
if [ "${NOVA_REQUIRE_GAMESCOPE_LIBEI:-0}" = "1" ] && \
    ! rg -q '^gamescope_libei_build=enabled$' "$METADATA"; then
    echo "Gamescope binary is not libei-enabled" >&2
    exit 1
fi

run_preflight_gate

rm -f "$REPORT" "$LOGCAT" "$APP_REPORT" "$ANDROID_INPUT_REPORT" "$ANDROID_TOUCH_REPORT" "$ANDROID_VULKAN_REPORT" "$SCREENSHOT" "$FRAME_MARKER_CAPTURE"
if [ "$PRESENTATION_DIAGNOSTICS" = "1" ]; then
    rm -f "$CLIENT_LOG" "$CLIENT_STDOUT" "$CLIENT_STDERR" "$STEAM_LOG_DIAGNOSTICS" "$SURFACEFLINGER_DIAGNOSTICS"
fi

"$ADB" logcat -c
cleanup_runtime
"$ADB" shell am force-stop "$PACKAGE"
clear_app_runtime_files
if ! set_ahb_trace_state "$AHB_TRACE"; then
    echo "failed to configure Nova AHB trace state" >&2
    exit 1
fi
if ! set_ahb_socket_trace_state "$AHB_SOCKET_TRACE"; then
    echo "failed to configure Nova AHB socket trace state" >&2
    exit 1
fi
if ! set_ahb_scheduler_trace_state "$AHB_SCHEDULER_TRACE"; then
    echo "failed to configure Nova AHB scheduler trace state" >&2
    exit 1
fi
if ! set_ahb_frame_identity_state "$AHB_FRAME_IDENTITY"; then
    echo "failed to configure Nova AHB frame identity state" >&2
    exit 1
fi
if ! set_ahb_frame_marker_state "$AHB_FRAME_MARKER"; then
    echo "failed to configure Nova AHB frame marker state" >&2
    exit 1
fi
if ! set_ahb_content_probe_state "$AHB_CONTENT_PROBE"; then
    echo "failed to configure Nova AHB content probe state" >&2
    exit 1
fi
if ! set_android_vulkan_layout_state "$ANDROID_VULKAN_LAYOUT_PROBE"; then
    echo "failed to configure Android Vulkan layout probe state" >&2
    exit 1
fi
if ! set_ahb_ack_poll_timeout_state "$ACK_POLL_TIMEOUT_MS"; then
    echo "failed to configure Nova AHB ACK poll timeout" >&2
    exit 1
fi
activity_args=(
    --ez run_dmabuf_double_buffer true
    --ei dmabuf_double_buffer_frames "$FRAME_COUNT"
    --ei dmabuf_double_buffer_width "$BUFFER_WIDTH"
    --ei dmabuf_double_buffer_height "$BUFFER_HEIGHT"
)
if [ "$ANDROID_VULKAN_LAYOUT_PROBE" = "1" ]; then
    activity_args+=(--ez run_android_vulkan true)
fi
if [ -n "${NOVA_FORCE_GPU_COMPOSITION:-}" ]; then
    case "$NOVA_FORCE_GPU_COMPOSITION" in
        1|true|TRUE|yes|YES)
            activity_args+=(--ez force_gpu_composition true)
            ;;
        0|false|FALSE|no|NO)
            activity_args+=(--ez force_gpu_composition false)
            ;;
        *)
            echo "invalid NOVA_FORCE_GPU_COMPOSITION: $NOVA_FORCE_GPU_COMPOSITION" >&2
            exit 2
            ;;
    esac
fi
if [ "${NOVA_ANDROID_INPUT_BRIDGE:-0}" = "1" ]; then
    activity_args+=(--ez run_android_input_bridge true)
    if [ "${NOVA_ANDROID_INPUT_KEY_ONLY:-0}" = "1" ]; then
        activity_args+=(--ez android_input_key_only true)
    fi
fi
if [ "${NOVA_ANDROID_TOUCH_BRIDGE:-0}" = "1" ]; then
    activity_args+=(--ez run_android_touch_bridge true)
fi
if [ "${NOVA_FULLSCREEN_PRESENTATION:-0}" = "1" ]; then
    activity_args+=(--ez fullscreen_presentation true)
    if [ -n "${NOVA_FULLSCREEN_WIDTH:-}" ]; then
        activity_args+=(--ei fullscreen_width "$NOVA_FULLSCREEN_WIDTH")
    fi
    if [ -n "${NOVA_FULLSCREEN_HEIGHT:-}" ]; then
        activity_args+=(--ei fullscreen_height "$NOVA_FULLSCREEN_HEIGHT")
    fi
fi
"$ADB" shell am start -W -n "$PACKAGE/.MainActivity" \
    "${activity_args[@]}" >/dev/null

set +e
VULKAN_ICD_FILE=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json \
VULKAN_NODEVICE_SELECT=1 \
VULKAN_OFFSCREEN_PROBE=/opt/nova-kgsl-driver/gamescope-headless-ahb-control.sh \
VULKAN_AHB_SOCKET_HOST_DIR="$SOCKET_HOST_DIR" \
VULKAN_AHB_SOCKET_NAME="$SOCKET_NAME" \
VULKAN_AHB_DOUBLE_BUFFER=1 \
VULKAN_AHB_FRAME_COUNT="$FRAME_COUNT" \
VULKAN_AHB_WIDTH="$BUFFER_WIDTH" \
VULKAN_AHB_HEIGHT="$BUFFER_HEIGHT" \
VULKAN_AHB_OUTPUT_SOCKET="/run/nova-lab-app/$SOCKET_NAME" \
NOVA_AHB_OUTPUT_TILING="$OUTPUT_TILING" \
    "$SCRIPT_DIR/deploy-holo-probe.sh"
probe_status=$?
set -e

cp "$BUILD_DIR/holo-glibc-report.txt" "$REPORT"
capture_presentation_diagnostics
"$ADB" shell sleep 1
"$ADB" logcat -d -v threadtime -s NovaLab:I > "$LOGCAT"
"$ADB" shell run-as "$PACKAGE" cat files/dmabuf-double-buffer-report.txt \
    > "$APP_REPORT" 2>/dev/null || true
if [ "$ANDROID_VULKAN_LAYOUT_PROBE" = "1" ]; then
    : > "$ANDROID_VULKAN_REPORT"
    "$ADB" shell run-as "$PACKAGE" cat files/android-vulkan-layout-report.txt \
        > "$ANDROID_VULKAN_REPORT" 2>/dev/null || :
fi
if [ "${NOVA_ANDROID_INPUT_BRIDGE:-0}" = "1" ]; then
    if ! "$ADB" shell run-as "$PACKAGE" cat files/android-input-bridge-report.txt \
        > "$ANDROID_INPUT_REPORT" 2>/dev/null; then
        : > "$ANDROID_INPUT_REPORT"
    fi
fi
if [ "${NOVA_ANDROID_TOUCH_BRIDGE:-0}" = "1" ]; then
    if ! "$ADB" shell run-as "$PACKAGE" cat files/android-touch-bridge-report.txt \
        > "$ANDROID_TOUCH_REPORT" 2>/dev/null; then
        : > "$ANDROID_TOUCH_REPORT"
    fi
fi
"$ADB" exec-out screencap -p > "$SCREENSHOT"
if [ "$ANDROID_VULKAN_LAYOUT_PROBE" = "1" ] && \
    ! rg -q '^android_vulkan_probe_version=1$' "$ANDROID_VULKAN_REPORT"; then
    rg 'android_vulkan_hardware_buffer_probe|android_vulkan_probe_version=|ahardwarebuffer\.(profile|supported|allocate_status|describe)|vk(CreateImage|GetAndroidHardwareBufferProperties|AllocateMemory|BindImageMemory)_status=|android_vulkan_image_modifier_status=|vulkan_clear_pixel=|android_vulkan_ahardwarebuffer=|android_vulkan_probe=' \
        "$LOGCAT" >"$ANDROID_VULKAN_REPORT" || :
fi
for artifact in "$REPORT" "$LOGCAT" "$APP_REPORT" "$ANDROID_INPUT_REPORT" "$ANDROID_TOUCH_REPORT" "$ANDROID_VULKAN_REPORT"; do
    if [ -f "$artifact" ]; then
        artifact_tmp="$artifact.tmp"
        {
            echo "nova_run_id=$RUN_ID"
            cat "$artifact"
        } >"$artifact_tmp"
        mv "$artifact_tmp" "$artifact"
    fi
done
if [ "$AHB_FRAME_MARKER" = "1" ]; then
    if ! python3 "$FRAME_MARKER_DECODER" "$SCREENSHOT" >"$FRAME_MARKER_CAPTURE"; then
        echo "frame-marker screenshot decode failed; inspect $FRAME_MARKER_CAPTURE" >&2
        exit 1
    fi
    marker_frame=$(sed -n 's/^nova_frame_marker_frame=//p' "$FRAME_MARKER_CAPTURE")
    marker_checksum_low16=$(sed -n 's/^nova_frame_marker_checksum_low16=//p' "$FRAME_MARKER_CAPTURE")
    if [ -z "$marker_frame" ] || [ -z "$marker_checksum_low16" ] || \
        ! rg -q "^ahb_double_buffer_frame_marker_${marker_frame}=pass .*producer_frame=${marker_frame} checksum_low16=${marker_checksum_low16} marker_status=0 checksum_status=0$" "$APP_REPORT"; then
        echo "frame-marker screenshot did not correlate with the app report" >&2
        cat "$FRAME_MARKER_CAPTURE" >&2
        exit 1
    fi
    echo "ahb_frame_marker_capture=pass frame=$marker_frame checksum_low16=$marker_checksum_low16"
fi
cleanup_runtime
residual_runtime_check
clear_app_runtime_files

echo "report:     $REPORT"
echo "app logcat: $LOGCAT"
echo "app report: $APP_REPORT"
if [ "$ANDROID_VULKAN_LAYOUT_PROBE" = "1" ]; then
    echo "android Vulkan report: $ANDROID_VULKAN_REPORT"
fi
echo "screenshot: $SCREENSHOT"
if [ "$probe_status" -ne 0 ]; then
    echo "headless gamescope AHardwareBuffer probe failed; inspect $REPORT and $LOGCAT" >&2
    exit "$probe_status"
fi

report_markers=(
    'vulkaninfo_status=0'
    "Android AHardwareBuffer output imported: 3 x ${BUFFER_WIDTH}x${BUFFER_HEIGHT} RGBA"
    "Running compositor on wayland display 'gamescope-0'"
    'android_ahb_composite_frame='
    'offscreen_probe_status=0'
    'probe_status=0'
)
if [ "${NOVA_GAMESCOPE_AHB_SKIP_WAYLAND:-0}" = "1" ]; then
    if [ "${NOVA_GAMESCOPE_AHB_XWAYLAND:-0}" = "1" ]; then
        report_markers+=('Starting Xwayland on :0')
        if [ "$REQUIRE_TARGET" = "1" ]; then
            report_markers+=("android_ahb_target_reached=$FRAME_COUNT")
        fi
    fi
else
    report_markers+=('wayland_connect=pass socket=gamescope-0')
fi
if [ "${NOVA_GAMESCOPE_AHB_SKIP_WAYLAND_SHM:-0}" != "1" ]; then
    report_markers+=("wayland_shm_frames=$FRAME_COUNT")
fi
report_markers+=("Android AHardwareBuffer output import begin tiling=$OUTPUT_TILING")
for marker in "${report_markers[@]}"; do
    if ! rg -q -- "$marker" "$REPORT"; then
        echo "missing report marker: $marker" >&2
        exit 1
    fi
done

if [ "${NOVA_GAMESCOPE_AHB_XWAYLAND:-0}" = "1" ] && \
    rg -q -- 'Android output acquire fence handoff failed' "$REPORT"; then
    echo "Xwayland output reported an Android acquire-fence handoff failure" >&2
    exit 1
fi

logcat_markers=(
    'ahb_double_buffer=pass'
    "ahb_double_buffer_size=${BUFFER_WIDTH}x${BUFFER_HEIGHT}"
    "ahb_double_buffer_frames=$FRAME_COUNT releases=$((FRAME_COUNT - 1))"
    'surface_frame_complete=pass'
    'linux_acquire_fence=pass'
)
if [ "$AHB_FRAME_IDENTITY" = "1" ]; then
    logcat_markers+=(
        'ahb_double_buffer_frame_identity=enabled'
        'ahb_double_buffer_frame_identity_0=pass'
    )
fi
if [ "$AHB_FRAME_MARKER" = "1" ]; then
    logcat_markers+=(
        'ahb_double_buffer_frame_marker=enabled'
        'ahb_double_buffer_frame_marker_0=pass'
    )
fi
if [ "$AHB_CONTENT_PROBE" = "1" ]; then
    logcat_markers+=(
        'ahb_double_buffer_content_probe=enabled'
        'ahb_double_buffer_frame_content_0=pass'
    )
    if [ "$FRAME_COUNT" -gt 0 ]; then
        logcat_markers+=(
            "ahb_double_buffer_frame_content_$((FRAME_COUNT - 1))=pass"
        )
    fi
fi
if [ "$ANDROID_VULKAN_LAYOUT_PROBE" = "1" ]; then
    logcat_markers+=(
        'android_vulkan_probe_version=1'
        "ahardwarebuffer.profile=${ANDROID_VULKAN_LAYOUT_WIDTH}x${ANDROID_VULKAN_LAYOUT_HEIGHT}"
        'android_vulkan_image_modifier_status='
        'android_vulkan_ahardwarebuffer=pass'
    )
fi
for marker in "${logcat_markers[@]}"; do
    if ! rg -q -- "$marker" "$LOGCAT" "$APP_REPORT" "$ANDROID_VULKAN_REPORT"; then
        echo "missing app marker: $marker" >&2
        exit 1
    fi
done

echo "headless_gamescope_ahb=pass"
