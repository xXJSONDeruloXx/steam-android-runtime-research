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
    vulkan-tools vulkan-headers vulkan-freedreno

for package_file in \
    "$PACKAGE_DIR"/vulkan-headers-*.pkg.tar.zst \
    "$PACKAGE_DIR"/vulkan-icd-loader-*.pkg.tar.zst; do
    if [ ! -f "$package_file" ]; then
        echo "missing host build package: $package_file" >&2
        exit 1
    fi
    bsdtar --no-same-owner --zstd -xpf "$package_file" -C "$ROOTFS_HOST"
    echo "host_extract=$package_file"
done

"$ADB" shell "su -c 'mkdir -p $DEVICE_PACKAGES; chmod 777 $DEVICE_PACKAGES'"
for package_file in "$PACKAGE_DIR"/*.pkg.tar.zst; do
    "$ADB" push "$package_file" "$DEVICE_PACKAGES/" >/dev/null
done
"$ADB" push "$SCRIPT_DIR/device/holo-package-install.sh" "$DEVICE_SCRIPT" >/dev/null
"$ADB" shell "su -c '/system/bin/sh $DEVICE_SCRIPT $DEVICE_ROOT $DEVICE_PACKAGES $DEVICE_REPORT $DEVICE_WORK'"
"$ADB" pull "$DEVICE_REPORT" "$BUILD_DIR/holo-package-install-report.txt" >/dev/null

echo "$BUILD_DIR/holo-package-install-report.txt"
