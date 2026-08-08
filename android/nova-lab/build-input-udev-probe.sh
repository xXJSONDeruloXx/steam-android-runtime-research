#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ROOTFS=${NOVA_HOLO_ROOTFS:-$BUILD_DIR/holo-rootfs/rootfs}
OUTPUT=${NOVA_INPUT_UDEV_PROBE_OUTPUT:-$BUILD_DIR/nova-input-udev-probe}
OUTPUT_NAME=$(basename "$OUTPUT")
DOCKER_IMAGE=${NOVA_INPUT_UDEV_BUILD_IMAGE:-debian:trixie-slim}

if [ ! -f "$ROOTFS/usr/include/libudev.h" ] || [ ! -f "$ROOTFS/usr/lib/libudev.so" ]; then
    echo "missing Holo libudev sysroot: $ROOTFS" >&2
    echo "install the Holo gamescope package closure first" >&2
    exit 1
fi
if [ ! -f "$ROOTFS/usr/include/stdio.h" ] || [ ! -f "$ROOTFS/usr/lib/Scrt1.o" ]; then
    echo "missing glibc rootfs sysroot: $ROOTFS" >&2
    exit 1
fi

docker run --rm --platform linux/arm64 \
    -v "$SCRIPT_DIR:/src" \
    -v "$BUILD_DIR:/out" \
    -e "NOVA_INPUT_UDEV_OUTPUT_NAME=$OUTPUT_NAME" \
    "$DOCKER_IMAGE" \
    sh -lc '
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update >/dev/null
apt-get install -y --no-install-recommends build-essential file >/dev/null
ROOTFS=/src/build/holo-rootfs/rootfs
cc \
    --sysroot="$ROOTFS" \
    -I"$ROOTFS/usr/include" \
    -L"$ROOTFS/usr/lib" \
    -Wl,-rpath-link,"$ROOTFS/usr/lib" \
    -Wl,--dynamic-linker=/usr/lib/ld-linux-aarch64.so.1 \
    -Wl,-rpath,/usr/lib \
    -O2 -std=c11 -Wall -Wextra -Werror \
    /src/device/nova-input-udev-probe.c \
    -ludev \
    -o "/out/$NOVA_INPUT_UDEV_OUTPUT_NAME"
file "/out/$NOVA_INPUT_UDEV_OUTPUT_NAME"
'

echo "$OUTPUT"
