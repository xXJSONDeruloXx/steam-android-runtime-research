#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
BINARY=${NOVA_VULKAN_PROBE:-$BUILD_DIR/vulkan-offscreen-probe}
ADB=${ADB:-/Users/kurt/.local/bin/adb}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
DEVICE_STAGE=/data/local/tmp/nova-vulkan-probe-stage
DEVICE_PATH="$DEVICE_ROOT/opt/nova-kgsl-driver/vulkan-offscreen-probe"

if [ ! -f "$BINARY" ]; then
    echo "missing offscreen probe: $BINARY" >&2
    echo "run android/nova-lab/build-vulkan-offscreen-probe.sh first." >&2
    exit 1
fi

"$ADB" shell "su -c 'mkdir -p $DEVICE_STAGE; chmod 777 $DEVICE_STAGE'"
"$ADB" push "$BINARY" "$DEVICE_STAGE/vulkan-offscreen-probe" >/dev/null
"$ADB" shell "su -c 'mkdir -p $DEVICE_ROOT/opt/nova-kgsl-driver; cp $DEVICE_STAGE/vulkan-offscreen-probe $DEVICE_PATH; chmod 755 $DEVICE_PATH'"

echo "probe=$DEVICE_PATH"
