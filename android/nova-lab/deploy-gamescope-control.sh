#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
CONTROL_REPORT="$BUILD_DIR/device-gamescope-control-report.txt"

if [ "${INSTALL_HOLO_GAMESCOPE:-1}" = "1" ]; then
    "$SCRIPT_DIR/install-holo-gamescope.sh" >/dev/null
fi

"$SCRIPT_DIR/deploy-kgsl-turnip.sh" >/dev/null

set +e
VULKAN_ICD_FILE=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json \
VULKAN_NODEVICE_SELECT=1 \
VULKAN_OFFSCREEN_PROBE=/usr/bin/gamescope \
    "$SCRIPT_DIR/deploy-holo-probe.sh"
probe_status=$?
set -e

cp "$BUILD_DIR/holo-glibc-report.txt" "$CONTROL_REPORT"

if [ "$probe_status" -eq 0 ]; then
    echo "stock gamescope unexpectedly started; inspect $CONTROL_REPORT" >&2
    exit 1
fi
if ! rg -q 'vulkaninfo_status=0' "$CONTROL_REPORT" ||
   ! rg -q "physical device doesn't support VK_EXT_physical_device_drm" "$CONTROL_REPORT" ||
   ! rg -q 'offscreen_probe_status=1' "$CONTROL_REPORT"; then
    echo "stock gamescope control did not reproduce the expected DRM-extension boundary; inspect $CONTROL_REPORT" >&2
    exit 1
fi

echo "stock_gamescope=blocked_on_VK_EXT_physical_device_drm"
echo "report=$CONTROL_REPORT"
