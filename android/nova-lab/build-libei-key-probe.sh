#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ROOTFS=${NOVA_HOLO_ROOTFS:-$BUILD_DIR/holo-rootfs/rootfs}
PACKAGE_DIR=${NOVA_HOLO_PACKAGE_DIR:-$BUILD_DIR/holo-rootfs/packages}
SYSROOT="$BUILD_DIR/libei-key-probe-sysroot"
OUTPUT=${NOVA_LIBEI_KEY_PROBE_OUTPUT:-$BUILD_DIR/nova-libei-key-probe}
OUTPUT_NAME=$(basename "$OUTPUT")
DOCKER_IMAGE=${NOVA_LIBEI_BUILD_IMAGE:-debian:trixie-slim}

LIBEI_PACKAGE=$(printf '%s\n' "$PACKAGE_DIR"/libei-*.pkg.tar.zst | head -n 1)
if [ ! -f "$LIBEI_PACKAGE" ]; then
    echo "missing Holo libei package: $PACKAGE_DIR/libei-*.pkg.tar.zst" >&2
    echo "install the Holo gamescope package closure first" >&2
    exit 1
fi
if [ ! -f "$ROOTFS/usr/include/stdio.h" ] || [ ! -f "$ROOTFS/usr/lib/Scrt1.o" ]; then
    echo "missing glibc rootfs sysroot: $ROOTFS" >&2
    exit 1
fi

mkdir -p "$SYSROOT"
docker run --rm --platform linux/arm64 \
    -v "$SCRIPT_DIR:/src" \
    -v "$BUILD_DIR:/out" \
    -e "NOVA_LIBEI_OUTPUT_NAME=$OUTPUT_NAME" \
    "$DOCKER_IMAGE" \
    sh -lc '
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update >/dev/null
apt-get install -y --no-install-recommends build-essential file zstd >/dev/null
ROOTFS=/src/build/holo-rootfs/rootfs
SYSROOT=/out/libei-key-probe-sysroot
mkdir -p "$SYSROOT"
tar --zstd -xf /src/build/holo-rootfs/packages/libei-*.pkg.tar.zst -C "$SYSROOT"
cc \
    --sysroot="$ROOTFS" \
    -I"$SYSROOT/usr/include" \
    -I"$SYSROOT/usr/include/libei-1.0" \
    -L"$SYSROOT/usr/lib" \
    -Wl,-rpath-link,"$SYSROOT/usr/lib" \
    -Wl,--dynamic-linker=/usr/lib/ld-linux-aarch64.so.1 \
    -Wl,-rpath,/usr/lib \
    -O2 -std=c11 -Wall -Wextra -Werror \
    /src/device/nova-libei-key-probe.c \
    -lei \
    -o "/out/$NOVA_LIBEI_OUTPUT_NAME"
file "/out/$NOVA_LIBEI_OUTPUT_NAME"
'

echo "$OUTPUT"
