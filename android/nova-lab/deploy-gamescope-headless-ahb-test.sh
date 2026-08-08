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
BINARY=${NOVA_GAMESCOPE_HEADLESS:-$BUILD_DIR/gamescope-headless-build/src/gamescope}
CLIENT=${NOVA_WAYLAND_SHM_CONTROL:-$BUILD_DIR/wayland-shm-control}
CONTROL=${NOVA_GAMESCOPE_AHB_CONTROL:-$SCRIPT_DIR/device/gamescope-headless-ahb-control.sh}
X11_CLIENT=${NOVA_GAMESCOPE_X11_CLIENT:-}
TOUCH_HELPER=${NOVA_EIS_TOUCH_HELPER:-}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
DEVICE_STAGE=/data/local/tmp/nova-gamescope-stage
DEVICE_DRIVER_DIR="$DEVICE_ROOT/opt/nova-kgsl-driver"
DEVICE_BINARY="$DEVICE_DRIVER_DIR/gamescope-headless"
DEVICE_CLIENT="$DEVICE_DRIVER_DIR/wayland-shm-control"
DEVICE_CONTROL="$DEVICE_DRIVER_DIR/gamescope-headless-ahb-control.sh"
DEVICE_TOUCH_HELPER="$DEVICE_DRIVER_DIR/nova-libei-input-bridge"
REPORT="$BUILD_DIR/device-gamescope-headless-ahb-report.txt"
LOGCAT="$BUILD_DIR/device-gamescope-headless-ahb-logcat.txt"
APP_REPORT="$BUILD_DIR/device-gamescope-headless-ahb-app-report.txt"
SCREENSHOT="$BUILD_DIR/device-gamescope-headless-ahb-screenshot.png"
REQUIRE_TARGET=${NOVA_GAMESCOPE_AHB_REQUIRE_TARGET:-1}

for required in "$BINARY" "$CLIENT" "$CONTROL"; do
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
"$ADB" install -r -d "$BUILD_DIR/nova-lab-debug.apk" >/dev/null

if [ "${INSTALL_HOLO_GAMESCOPE:-1}" = "1" ]; then
    "$SCRIPT_DIR/install-holo-gamescope.sh" >/dev/null
fi
"$SCRIPT_DIR/deploy-kgsl-turnip.sh" >/dev/null

"$ADB" shell "su -c 'mkdir -p $DEVICE_STAGE $DEVICE_DRIVER_DIR; chmod 777 $DEVICE_STAGE'"
"$ADB" push "$BINARY" "$DEVICE_STAGE/gamescope-headless" >/dev/null
"$ADB" push "$CLIENT" "$DEVICE_STAGE/wayland-shm-control" >/dev/null
"$ADB" push "$CONTROL" "$DEVICE_STAGE/gamescope-headless-ahb-control.sh" >/dev/null
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
"$ADB" shell "su -c 'cp $DEVICE_STAGE/gamescope-headless $DEVICE_BINARY; cp $DEVICE_STAGE/wayland-shm-control $DEVICE_CLIENT; cp $DEVICE_STAGE/gamescope-headless-ahb-control.sh $DEVICE_CONTROL; chmod 755 $DEVICE_BINARY $DEVICE_CLIENT $DEVICE_CONTROL'"
if [ -n "$TOUCH_HELPER" ]; then
    "$ADB" shell "su -c 'cp $DEVICE_STAGE/nova-libei-input-bridge $DEVICE_TOUCH_HELPER; chmod 755 $DEVICE_TOUCH_HELPER'"
fi
if [ -n "$X11_CLIENT" ]; then
    "$ADB" shell "su -c 'cp $DEVICE_STAGE/nova-x11-animate $DEVICE_DRIVER_DIR/nova-x11-animate; chmod 755 $DEVICE_DRIVER_DIR/nova-x11-animate'"
fi

APP_DATA_DIR=$("$ADB" shell run-as "$PACKAGE" pwd | tr -d '\r')
SOCKET_HOST_DIR="$APP_DATA_DIR/files"

rm -f "$REPORT" "$LOGCAT" "$APP_REPORT" "$SCREENSHOT"

"$ADB" logcat -c
"$ADB" shell am force-stop "$PACKAGE"
activity_args=(
    --ez run_dmabuf_double_buffer true
    --ei dmabuf_double_buffer_frames "$FRAME_COUNT"
    --ei dmabuf_double_buffer_width "$BUFFER_WIDTH"
    --ei dmabuf_double_buffer_height "$BUFFER_HEIGHT"
)
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
    "Android AHardwareBuffer output imported: 2 x ${BUFFER_WIDTH}x${BUFFER_HEIGHT} RGBA"
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
