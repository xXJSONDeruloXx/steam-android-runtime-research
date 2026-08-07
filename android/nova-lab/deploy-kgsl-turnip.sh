#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
DRIVER=${NOVA_KGSL_DRIVER:-$BUILD_DIR/mesa-kgsl/libvulkan_freedreno.so}
MANIFEST="$SCRIPT_DIR/device/freedreno-kgsl.icd.json"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
DEVICE_STAGE=/data/local/tmp/nova-kgsl-driver-stage
DEVICE_DRIVER_DIR="$DEVICE_ROOT/opt/nova-kgsl-driver"

if [ ! -f "$DRIVER" ]; then
    echo "missing KGSL Turnip library: $DRIVER" >&2
    echo "Build or copy it into android/nova-lab/build/mesa-kgsl first." >&2
    exit 1
fi

if [ ! -f "$MANIFEST" ]; then
    echo "missing ICD manifest: $MANIFEST" >&2
    exit 1
fi

"$ADB" shell "su -c 'mkdir -p $DEVICE_STAGE; chmod 777 $DEVICE_STAGE'"
"$ADB" push "$DRIVER" "$DEVICE_STAGE/libvulkan_freedreno.so" >/dev/null
"$ADB" push "$MANIFEST" "$DEVICE_STAGE/freedreno-kgsl.icd.json" >/dev/null
"$ADB" shell "su -c 'mkdir -p $DEVICE_DRIVER_DIR; cp $DEVICE_STAGE/libvulkan_freedreno.so $DEVICE_DRIVER_DIR/libvulkan_freedreno.so; cp $DEVICE_STAGE/freedreno-kgsl.icd.json $DEVICE_DRIVER_DIR/freedreno-kgsl.icd.json; chmod 755 $DEVICE_DRIVER_DIR/libvulkan_freedreno.so; chmod 644 $DEVICE_DRIVER_DIR/freedreno-kgsl.icd.json'"

if command -v sha256sum >/dev/null 2>&1; then
    host_sha256=$(sha256sum "$DRIVER" | awk '{print $1}')
else
    host_sha256=$(shasum -a 256 "$DRIVER" | awk '{print $1}')
fi

echo "driver=$DEVICE_DRIVER_DIR/libvulkan_freedreno.so"
echo "manifest=$DEVICE_DRIVER_DIR/freedreno-kgsl.icd.json"
echo "driver_sha256=$host_sha256"
