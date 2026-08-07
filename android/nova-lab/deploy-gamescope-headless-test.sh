#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
BINARY=${NOVA_GAMESCOPE_HEADLESS:-$BUILD_DIR/gamescope-headless-build/src/gamescope}
CONTROL="$SCRIPT_DIR/device/gamescope-headless-control.sh"
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
DEVICE_STAGE=/data/local/tmp/nova-gamescope-stage
DEVICE_DRIVER_DIR="$DEVICE_ROOT/opt/nova-kgsl-driver"
DEVICE_BINARY="$DEVICE_DRIVER_DIR/gamescope-headless"
DEVICE_CONTROL="$DEVICE_DRIVER_DIR/gamescope-headless-control.sh"
CONTROL_REPORT="$BUILD_DIR/device-gamescope-headless-report.txt"

if [ ! -f "$BINARY" ]; then
    echo "missing gamescope binary: $BINARY" >&2
    echo "run build-gamescope-headless.sh or set NOVA_GAMESCOPE_HEADLESS" >&2
    exit 1
fi
if [ ! -f "$CONTROL" ]; then
    echo "missing headless control: $CONTROL" >&2
    exit 1
fi

if [ "${INSTALL_HOLO_GAMESCOPE:-1}" = "1" ]; then
    "$SCRIPT_DIR/install-holo-gamescope.sh" >/dev/null
fi

"$SCRIPT_DIR/deploy-kgsl-turnip.sh" >/dev/null

"$ADB" shell "su -c 'mkdir -p $DEVICE_STAGE $DEVICE_DRIVER_DIR; chmod 777 $DEVICE_STAGE'"
"$ADB" push "$BINARY" "$DEVICE_STAGE/gamescope-headless" >/dev/null
"$ADB" push "$CONTROL" "$DEVICE_STAGE/gamescope-headless-control.sh" >/dev/null
"$ADB" shell "su -c 'cp $DEVICE_STAGE/gamescope-headless $DEVICE_BINARY; cp $DEVICE_STAGE/gamescope-headless-control.sh $DEVICE_CONTROL; chmod 755 $DEVICE_BINARY $DEVICE_CONTROL'"

set +e
VULKAN_ICD_FILE=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json \
VULKAN_NODEVICE_SELECT=1 \
VULKAN_OFFSCREEN_PROBE=/opt/nova-kgsl-driver/gamescope-headless-control.sh \
    "$SCRIPT_DIR/deploy-holo-probe.sh"
probe_status=$?
set -e

cp "$BUILD_DIR/holo-glibc-report.txt" "$CONTROL_REPORT"

if [ "$probe_status" -ne 0 ]; then
    echo "headless gamescope probe failed; inspect $CONTROL_REPORT" >&2
    exit "$probe_status"
fi

expected_markers=(
    'vulkaninfo_status=0'
    "physical device doesn't support VK_EXT_physical_device_drm; backend does not require DRM identity"
    'Creating headless backend'
    "Running compositor on wayland display 'gamescope-0'"
    'offscreen_probe_status=0'
    'probe_status=0'
)
for marker in "${expected_markers[@]}"; do
    if ! rg -q -- "$marker" "$CONTROL_REPORT"; then
        echo "missing expected marker: $marker" >&2
        echo "inspect $CONTROL_REPORT" >&2
        exit 1
    fi
done

echo "headless_gamescope=pass"
echo "report=$CONTROL_REPORT"
