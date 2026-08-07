#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
DEVICE_SCRIPT=/data/local/tmp/nova-holo-glibc-probe.sh
DEVICE_REPORT=/data/local/tmp/nova-holo-glibc-report.txt
DEVICE_WORK=/data/local/tmp/nova-holo-glibc-work
VULKAN_LOADER_DEBUG=${VULKAN_LOADER_DEBUG:-error}

"$ADB" push "$SCRIPT_DIR/device/holo-glibc-probe.sh" "$DEVICE_SCRIPT" >/dev/null
set +e
"$ADB" shell "su -c 'VULKAN_LOADER_DEBUG=$VULKAN_LOADER_DEBUG /system/bin/sh $DEVICE_SCRIPT $DEVICE_ROOT $DEVICE_REPORT $DEVICE_WORK'"
probe_status=$?
set -e
"$ADB" pull "$DEVICE_REPORT" "$BUILD_DIR/holo-glibc-report.txt" >/dev/null

echo "$BUILD_DIR/holo-glibc-report.txt"
exit "$probe_status"
