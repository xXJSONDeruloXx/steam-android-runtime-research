#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
DEVICE_STAGE=/data/local/tmp/nova-posix-sync-stage
DEVICE_DRIVER_DIR="$DEVICE_ROOT/opt/nova-kgsl-driver"
DEVICE_BINARY="$DEVICE_DRIVER_DIR/posix-sync-probe"
REPORT="$BUILD_DIR/holo-glibc-report.txt"

"$SCRIPT_DIR/build-posix-sync-probe.sh" >/dev/null
"$ADB" wait-for-device
"$ADB" shell "su -c 'mkdir -p $DEVICE_STAGE $DEVICE_DRIVER_DIR; chmod 777 $DEVICE_STAGE'"
"$ADB" push "$BUILD_DIR/posix-sync-probe" "$DEVICE_STAGE/posix-sync-probe" >/dev/null
"$ADB" shell "su -c 'cp $DEVICE_STAGE/posix-sync-probe $DEVICE_BINARY; chmod 755 $DEVICE_BINARY'"

set +e
VULKAN_ICD_FILE=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json \
VULKAN_NODEVICE_SELECT=1 \
VULKAN_OFFSCREEN_PROBE=/opt/nova-kgsl-driver/posix-sync-probe \
    "$SCRIPT_DIR/deploy-holo-probe.sh"
probe_status=$?
set -e

echo "report=$REPORT"
rg -n 'mount.*/dev/shm|sem_|pthread_|eventfd|shm_|posix_sync_status|offscreen_probe_status|probe_status' "$REPORT" || true
echo "posix_sync_probe_status=$probe_status"
exit "$probe_status"
