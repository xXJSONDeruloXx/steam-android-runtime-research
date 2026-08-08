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
REPORT="$BUILD_DIR/device-gamescope-headless-ahb-report.txt"
LOGCAT="$BUILD_DIR/device-gamescope-headless-ahb-logcat.txt"
APP_REPORT="$BUILD_DIR/device-gamescope-headless-ahb-app-report.txt"
SCREENSHOT="$BUILD_DIR/device-gamescope-headless-ahb-screenshot.png"
METADATA="$BUILD_DIR/device-gamescope-headless-ahb-metadata.txt"
REQUIRE_TARGET=${NOVA_GAMESCOPE_AHB_REQUIRE_TARGET:-1}
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

if [ -n "$RUN_DIR" ]; then
    mkdir -p "$RUN_DIR"
    REPORT="$RUN_DIR/device-gamescope-headless-ahb-report.txt"
    LOGCAT="$RUN_DIR/device-gamescope-headless-ahb-logcat.txt"
    APP_REPORT="$RUN_DIR/device-gamescope-headless-ahb-app-report.txt"
    SCREENSHOT="$RUN_DIR/device-gamescope-headless-ahb-screenshot.png"
    METADATA="$RUN_DIR/device-gamescope-headless-ahb-metadata.txt"
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
    local original_status=$? cleanup_status residual_status app_files_status trace_status
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
    if [ "$original_status" -ne 0 ]; then
        exit "$original_status"
    fi
    if [ "$cleanup_status" -ne 0 ] || [ "$residual_status" -ne 0 ] || \
        [ "$app_files_status" -ne 0 ] || [ "$trace_status" -ne 0 ]; then
        exit 1
    fi
    exit 0
}
clear_app_runtime_files() {
    if "$ADB" shell "run-as $PACKAGE sh -c 'rm -f files/nova-input.sock files/nova-touch.sock files/nova-lab-ahb-double-buffer.sock.* files/dmabuf-double-buffer-report.txt files/android-input-bridge-report.txt files/android-touch-bridge-report.txt'" \
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
trap cleanup_on_exit EXIT

{
    libei_build_marker=$(strings "$BINARY" | rg -m1 -i 'successfully initialized libei|built without libei' || true)
    echo "nova_run_id=$RUN_ID"
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
        echo "gamescope_source_commit=$(git -C "$GAMESCOPE_HEADLESS_SOURCE" rev-parse HEAD)"
    else
        echo "gamescope_source_commit=unknown"
    fi
    echo "fullscreen_presentation=${NOVA_FULLSCREEN_PRESENTATION:-0}"
    echo "force_gpu_composition=${NOVA_FORCE_GPU_COMPOSITION:-unset}"
    echo "nova_ahb_trace=$AHB_TRACE"
    echo "steamos_update_compat=installed"
} >"$METADATA"
cat "$METADATA"

if [ "${NOVA_REQUIRE_GAMESCOPE_PROVENANCE:-0}" = "1" ]; then
    if ! rg -q '^gamescope_binary_sha256=[0-9a-f]{64}$' "$METADATA" || \
        ! rg -q '^nova_apk_sha256=[0-9a-f]{64}$' "$METADATA" || \
        ! rg -q '^gamescope_source_tree=[^u].+' "$METADATA" || \
        ! rg -q '^gamescope_source_commit=[0-9a-f]{40}$' "$METADATA"; then
        echo "missing required Gamescope provenance" >&2
        exit 1
    fi
fi
if [ "${NOVA_REQUIRE_GAMESCOPE_LIBEI:-0}" = "1" ] && \
    ! rg -q '^gamescope_libei_build=enabled$' "$METADATA"; then
    echo "Gamescope binary is not libei-enabled" >&2
    exit 1
fi

rm -f "$REPORT" "$LOGCAT" "$APP_REPORT" "$SCREENSHOT"

"$ADB" logcat -c
cleanup_runtime
"$ADB" shell am force-stop "$PACKAGE"
clear_app_runtime_files
if ! set_ahb_trace_state "$AHB_TRACE"; then
    echo "failed to configure Nova AHB trace state" >&2
    exit 1
fi
activity_args=(
    --ez run_dmabuf_double_buffer true
    --ei dmabuf_double_buffer_frames "$FRAME_COUNT"
    --ei dmabuf_double_buffer_width "$BUFFER_WIDTH"
    --ei dmabuf_double_buffer_height "$BUFFER_HEIGHT"
)
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
    "$SCRIPT_DIR/deploy-holo-probe.sh"
probe_status=$?
set -e

cp "$BUILD_DIR/holo-glibc-report.txt" "$REPORT"
"$ADB" shell sleep 1
"$ADB" logcat -d -v threadtime NovaLab:I '*:S' > "$LOGCAT"
"$ADB" shell run-as "$PACKAGE" cat files/dmabuf-double-buffer-report.txt \
    > "$APP_REPORT" 2>/dev/null || true
if [ "${NOVA_ANDROID_TOUCH_BRIDGE:-0}" = "1" ]; then
    "$ADB" shell run-as "$PACKAGE" cat files/android-touch-bridge-report.txt \
        > "$BUILD_DIR/nova-android-touch-bridge-report.txt" 2>/dev/null || true
fi
"$ADB" exec-out screencap -p > "$SCREENSHOT"
for artifact in "$REPORT" "$LOGCAT" "$APP_REPORT"; do
    if [ -f "$artifact" ]; then
        artifact_tmp="$artifact.tmp"
        {
            echo "nova_run_id=$RUN_ID"
            cat "$artifact"
        } >"$artifact_tmp"
        mv "$artifact_tmp" "$artifact"
    fi
done
cleanup_runtime
residual_runtime_check
clear_app_runtime_files

echo "report:     $REPORT"
echo "app logcat: $LOGCAT"
echo "app report: $APP_REPORT"
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
for marker in "${logcat_markers[@]}"; do
    if ! rg -q -- "$marker" "$LOGCAT" "$APP_REPORT"; then
        echo "missing app marker: $marker" >&2
        exit 1
    fi
done

echo "headless_gamescope_ahb=pass"
