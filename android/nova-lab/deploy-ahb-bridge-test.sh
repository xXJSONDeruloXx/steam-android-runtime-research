#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
PACKAGE=com.xjsonderulo.steamandroid.novalab
SOCKET_NAME=nova-lab-ahb-bridge.sock

"$SCRIPT_DIR/build.sh" >/dev/null
"$ADB" wait-for-device
"$ADB" install -r -d "$BUILD_DIR/nova-lab-debug.apk" >/dev/null

"$SCRIPT_DIR/deploy-kgsl-turnip.sh" >/dev/null
"$SCRIPT_DIR/deploy-vulkan-offscreen-probe.sh" >/dev/null

APP_DATA_DIR=$("$ADB" shell run-as "$PACKAGE" pwd | tr -d '\r')
SOCKET_HOST_DIR="$APP_DATA_DIR/files"

"$ADB" logcat -c
"$ADB" shell am force-stop "$PACKAGE"
"$ADB" shell am start -W -n "$PACKAGE/.MainActivity" \
    --ez run_dmabuf_bridge true >/dev/null

set +e
VULKAN_ICD_FILE=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json \
VULKAN_NODEVICE_SELECT=1 \
VULKAN_OFFSCREEN_PROBE=/opt/nova-kgsl-driver/vulkan-offscreen-probe \
VULKAN_AHB_SOCKET_HOST_DIR="$SOCKET_HOST_DIR" \
VULKAN_AHB_SOCKET_NAME="$SOCKET_NAME" \
    "$SCRIPT_DIR/deploy-holo-probe.sh"
probe_status=$?
set -e

"$ADB" shell sleep 1

"$ADB" logcat -d -v threadtime NovaLab:I '*:S' > "$BUILD_DIR/device-ahb-bridge-logcat.txt"
"$ADB" exec-out screencap -p > "$BUILD_DIR/device-ahb-bridge-screenshot.png"

echo "holo report: $BUILD_DIR/holo-glibc-report.txt"
echo "app logcat:  $BUILD_DIR/device-ahb-bridge-logcat.txt"
echo "screenshot:  $BUILD_DIR/device-ahb-bridge-screenshot.png"
if [ "$probe_status" -ne 0 ]; then
    exit "$probe_status"
fi
if ! rg -q 'ahb_bridge=pass' "$BUILD_DIR/device-ahb-bridge-logcat.txt" ||
   ! rg -q 'ahb_surface=pass' "$BUILD_DIR/device-ahb-bridge-logcat.txt"; then
    echo "Android bridge/surface acceptance failed; inspect $BUILD_DIR/device-ahb-bridge-logcat.txt" >&2
    exit 1
fi
exit 0
