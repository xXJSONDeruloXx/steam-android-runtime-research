#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ROOTFS_HOST="$BUILD_DIR/holo-rootfs/rootfs"
PACKAGE_DIR="$BUILD_DIR/holo-rootfs/packages"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
DEVICE_PACKAGES=/data/local/tmp/nova-holo-pkgs
DEVICE_SCRIPT=/data/local/tmp/nova-holo-package-install.sh
DEVICE_REPORT=/data/local/tmp/nova-holo-package-install-report.txt
DEVICE_WORK=/data/local/tmp/nova-holo-package-install-work

if [ ! -d "$ROOTFS_HOST" ]; then
    echo "missing extracted rootfs: $ROOTFS_HOST" >&2
    exit 1
fi

python3 "$SCRIPT_DIR/fetch-holo-packages.py" \
    --rootfs "$ROOTFS_HOST" \
    --output "$PACKAGE_DIR" \
    vulkan-tools vulkan-freedreno

"$ADB" shell "su -c 'mkdir -p $DEVICE_PACKAGES; chmod 777 $DEVICE_PACKAGES'"
for package_file in "$PACKAGE_DIR"/*.pkg.tar.zst; do
    "$ADB" push "$package_file" "$DEVICE_PACKAGES/" >/dev/null
done
"$ADB" push "$SCRIPT_DIR/device/holo-package-install.sh" "$DEVICE_SCRIPT" >/dev/null
"$ADB" shell "su -c '/system/bin/sh $DEVICE_SCRIPT $DEVICE_ROOT $DEVICE_PACKAGES $DEVICE_REPORT $DEVICE_WORK'"
"$ADB" pull "$DEVICE_REPORT" "$BUILD_DIR/holo-package-install-report.txt" >/dev/null

echo "$BUILD_DIR/holo-package-install-report.txt"
