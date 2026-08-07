#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
PACKAGE=com.xjsonderulo.steamandroid.novalab
SOCKET_NAME=nova-lab-ahb-double-buffer.sock
FRAME_COUNT=${NOVA_AHB_FRAME_COUNT:-60}
BINARY=${NOVA_GAMESCOPE_HEADLESS:-$BUILD_DIR/gamescope-headless-build/src/gamescope}
CLIENT=${NOVA_WAYLAND_SHM_CONTROL:-$BUILD_DIR/wayland-shm-control}
CONTROL="$SCRIPT_DIR/device/gamescope-headless-ahb-control.sh"
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
DEVICE_STAGE=/data/local/tmp/nova-gamescope-stage
DEVICE_DRIVER_DIR="$DEVICE_ROOT/opt/nova-kgsl-driver"
DEVICE_BINARY="$DEVICE_DRIVER_DIR/gamescope-headless"
DEVICE_CLIENT="$DEVICE_DRIVER_DIR/wayland-shm-control"
DEVICE_CONTROL="$DEVICE_DRIVER_DIR/gamescope-headless-ahb-control.sh"
REPORT="$BUILD_DIR/device-gamescope-headless-ahb-report.txt"
LOGCAT="$BUILD_DIR/device-gamescope-headless-ahb-logcat.txt"
SCREENSHOT="$BUILD_DIR/device-gamescope-headless-ahb-screenshot.png"

for required in "$BINARY" "$CLIENT" "$CONTROL"; do
    if [ ! -f "$required" ]; then
        echo "missing test input: $required" >&2
        echo "build gamescope and wayland-shm-control first" >&2
        exit 1
    fi
done

"$SCRIPT_DIR/build.sh" >/dev/null
"$ADB" wait-for-device
"$ADB" install -r -d "$BUILD_DIR/nova-lab-debug.apk" >/dev/null

if [ "${INSTALL_HOLO_GAMESCOPE:-1}" = "1" ]; then
    "$SCRIPT_DIR/install-holo-gamescope.sh" >/dev/null
fi
"$SCRIPT_DIR/deploy-kgsl-turnip.sh" >/dev/null

"$ADB" shell "su -c 'mkdir -p $DEVICE_STAGE $DEVICE_DRIVER_DIR; chmod 777 $DEVICE_STAGE'"
"$ADB" push "$BINARY" "$DEVICE_STAGE/gamescope-headless" >/dev/null
"$ADB" push "$CLIENT" "$DEVICE_STAGE/wayland-shm-control" >/dev/null
"$ADB" push "$CONTROL" "$DEVICE_STAGE/gamescope-headless-ahb-control.sh" >/dev/null
"$ADB" shell "su -c 'cp $DEVICE_STAGE/gamescope-headless $DEVICE_BINARY; cp $DEVICE_STAGE/wayland-shm-control $DEVICE_CLIENT; cp $DEVICE_STAGE/gamescope-headless-ahb-control.sh $DEVICE_CONTROL; chmod 755 $DEVICE_BINARY $DEVICE_CLIENT $DEVICE_CONTROL'"

APP_DATA_DIR=$("$ADB" shell run-as "$PACKAGE" pwd | tr -d '\r')
SOCKET_HOST_DIR="$APP_DATA_DIR/files"

"$ADB" logcat -c
"$ADB" shell am force-stop "$PACKAGE"
"$ADB" shell am start -W -n "$PACKAGE/.MainActivity" \
    --ez run_dmabuf_double_buffer true \
    --ei dmabuf_double_buffer_frames "$FRAME_COUNT" >/dev/null

set +e
VULKAN_ICD_FILE=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json \
VULKAN_NODEVICE_SELECT=1 \
VULKAN_OFFSCREEN_PROBE=/opt/nova-kgsl-driver/gamescope-headless-ahb-control.sh \
VULKAN_AHB_SOCKET_HOST_DIR="$SOCKET_HOST_DIR" \
VULKAN_AHB_SOCKET_NAME="$SOCKET_NAME" \
VULKAN_AHB_DOUBLE_BUFFER=1 \
VULKAN_AHB_FRAME_COUNT="$FRAME_COUNT" \
VULKAN_AHB_OUTPUT_SOCKET="/run/nova-lab-app/$SOCKET_NAME" \
    "$SCRIPT_DIR/deploy-holo-probe.sh"
probe_status=$?
set -e

cp "$BUILD_DIR/holo-glibc-report.txt" "$REPORT"
"$ADB" shell sleep 1
"$ADB" logcat -d -v threadtime NovaLab:I '*:S' > "$LOGCAT"
"$ADB" exec-out screencap -p > "$SCREENSHOT"

echo "report:     $REPORT"
echo "app logcat: $LOGCAT"
echo "screenshot: $SCREENSHOT"
if [ "$probe_status" -ne 0 ]; then
    echo "headless gamescope AHardwareBuffer probe failed; inspect $REPORT and $LOGCAT" >&2
    exit "$probe_status"
fi

report_markers=(
    'vulkaninfo_status=0'
    'Android AHardwareBuffer output imported: 2 x 64x64 RGBA'
    "Running compositor on wayland display 'gamescope-0'"
    'wayland_connect=pass socket=gamescope-0'
    'android_ahb_composite_frame='
    "wayland_shm_frames=$FRAME_COUNT"
    'offscreen_probe_status=0'
    'probe_status=0'
)
for marker in "${report_markers[@]}"; do
    if ! rg -q -- "$marker" "$REPORT"; then
        echo "missing report marker: $marker" >&2
        exit 1
    fi
done

logcat_markers=(
    'ahb_double_buffer=pass'
    "ahb_double_buffer_frames=$FRAME_COUNT releases=$((FRAME_COUNT - 1))"
    'surface_frame_complete=pass'
    'linux_acquire_fence=pass'
)
for marker in "${logcat_markers[@]}"; do
    if ! rg -q -- "$marker" "$LOGCAT"; then
        echo "missing app marker: $marker" >&2
        exit 1
    fi
done

echo "headless_gamescope_ahb=pass"
