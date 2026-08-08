#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ROOTFS=${NOVA_HOLO_ROOTFS:-$BUILD_DIR/holo-rootfs/rootfs}
PACKAGE_DIR=${NOVA_HOLO_PACKAGE_DIR:-$BUILD_DIR/holo-rootfs/packages}
SYSROOT="$BUILD_DIR/x11-capture-sysroot"
OUTPUT=${NOVA_X11_CAPTURE_OUTPUT:-$BUILD_DIR/nova-x11-capture}
OUTPUT_NAME=$(basename "$OUTPUT")
DOCKER_IMAGE=${NOVA_X11_BUILD_IMAGE:-debian:trixie-slim}

LIBX11_PACKAGE=$(printf '%s\n' "$PACKAGE_DIR"/libx11-*.pkg.tar.zst | head -n 1)
LIBXCB_PACKAGE=$(printf '%s\n' "$PACKAGE_DIR"/libxcb-*.pkg.tar.zst | head -n 1)
LIBXAU_PACKAGE=$(printf '%s\n' "$PACKAGE_DIR"/libxau-*.pkg.tar.zst | head -n 1)
LIBXDMCP_PACKAGE=$(printf '%s\n' "$PACKAGE_DIR"/libxdmcp-*.pkg.tar.zst | head -n 1)
XORGPROTO_PACKAGE=$(printf '%s\n' "$PACKAGE_DIR"/xorgproto-*.pkg.tar.zst | head -n 1)
for package_file in "$LIBX11_PACKAGE" "$LIBXCB_PACKAGE" "$LIBXAU_PACKAGE" \
    "$LIBXDMCP_PACKAGE" "$XORGPROTO_PACKAGE"; do
    if [ ! -f "$package_file" ]; then
        echo "missing X11 build package: $package_file" >&2
        echo "install xorg-xwayland or xorg-xmessage packages first" >&2
        exit 1
    fi
done
if [ ! -f "$ROOTFS/usr/include/stdio.h" ] || [ ! -f "$ROOTFS/usr/lib/Scrt1.o" ]; then
    echo "missing glibc rootfs sysroot: $ROOTFS" >&2
    exit 1
fi

mkdir -p "$SYSROOT"
docker run --rm --platform linux/arm64 \
    -v "$SCRIPT_DIR:/src" \
    -v "$BUILD_DIR:/out" \
    -e "NOVA_X11_OUTPUT_NAME=$OUTPUT_NAME" \
    "$DOCKER_IMAGE" \
    sh -lc '
set -e
apt-get update >/dev/null
apt-get install -y --no-install-recommends build-essential file zstd >/dev/null
ROOTFS=/src/build/holo-rootfs/rootfs
SYSROOT=/out/x11-capture-sysroot
mkdir -p "$SYSROOT"
tar --zstd -xf /src/build/holo-rootfs/packages/libx11-*.pkg.tar.zst -C "$SYSROOT"
tar --zstd -xf /src/build/holo-rootfs/packages/libxcb-*.pkg.tar.zst -C "$SYSROOT"
tar --zstd -xf /src/build/holo-rootfs/packages/libxau-*.pkg.tar.zst -C "$SYSROOT"
tar --zstd -xf /src/build/holo-rootfs/packages/libxdmcp-*.pkg.tar.zst -C "$SYSROOT"
tar --zstd -xf /src/build/holo-rootfs/packages/xorgproto-*.pkg.tar.zst -C "$SYSROOT"
cc \
    --sysroot="$ROOTFS" \
    -I"$SYSROOT/usr/include" \
    -L"$SYSROOT/usr/lib" \
    -Wl,-rpath-link,"$SYSROOT/usr/lib" \
    -Wl,--dynamic-linker=/usr/lib/ld-linux-aarch64.so.1 \
    -Wl,-rpath,/usr/lib \
    -O2 -std=c11 -Wall -Wextra -Werror \
    /src/device/nova-x11-capture.c \
    -lX11 \
    -lxcb -lXau -lXdmcp \
    -o "/out/$NOVA_X11_OUTPUT_NAME"
file "/out/$NOVA_X11_OUTPUT_NAME"
'

echo "$OUTPUT"
