#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ROOTFS_HOST="$BUILD_DIR/holo-rootfs/rootfs"

if [ ! -f "$ROOTFS_HOST/usr/include/vulkan/vulkan.h" ]; then
    echo "missing Vulkan headers in Holo rootfs: $ROOTFS_HOST/usr/include/vulkan/vulkan.h" >&2
    echo "run android/nova-lab/install-holo-packages.sh first." >&2
    exit 1
fi

docker run --rm --platform linux/arm64 --name nova-vulkan-probe-build \
    -v "$REPO_DIR:/src:ro" \
    -v "$ROOTFS_HOST:/sysroot:ro" \
    -v "$BUILD_DIR:/out" \
    ubuntu:24.04 bash -lc '
        set -eux
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq --no-install-recommends gcc
        gcc --sysroot=/sysroot -I/usr/include -L/usr/lib \
            -O2 -std=c11 /src/android/nova-lab/device/vulkan-offscreen-probe.c \
            -lvulkan -o /out/vulkan-offscreen-probe
    '

echo "probe=$BUILD_DIR/vulkan-offscreen-probe"
