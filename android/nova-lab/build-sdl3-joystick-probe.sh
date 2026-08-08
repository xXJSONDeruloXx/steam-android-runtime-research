#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ROOTFS=${NOVA_HOLO_ROOTFS:-$BUILD_DIR/holo-rootfs/rootfs}
OUTPUT=${NOVA_SDL3_JOYSTICK_PROBE_OUTPUT:-$BUILD_DIR/nova-sdl3-joystick-probe}
OUTPUT_NAME=$(basename "$OUTPUT")
DOCKER_IMAGE=${NOVA_SDL3_BUILD_IMAGE:-debian:trixie-slim}

if [ ! -f "$ROOTFS/usr/include/stdio.h" ] || [ ! -f "$ROOTFS/usr/lib/Scrt1.o" ]; then
    echo "missing glibc rootfs sysroot: $ROOTFS" >&2
    exit 1
fi

docker run --rm --platform linux/arm64 \
    -v "$SCRIPT_DIR:/src" \
    -v "$BUILD_DIR:/out" \
    -e "NOVA_SDL3_OUTPUT_NAME=$OUTPUT_NAME" \
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
    /src/device/nova-sdl3-joystick-probe.c \
    -ldl \
    -o "/out/$NOVA_SDL3_OUTPUT_NAME"
file "/out/$NOVA_SDL3_OUTPUT_NAME"
'

echo "$OUTPUT"
