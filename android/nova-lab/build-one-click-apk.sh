#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"

if [ ! -x "$BUILD_DIR/nova-mount-private" ]; then
    "$SCRIPT_DIR/build-mount-private.sh" >/dev/null
fi

if [ ! -x "$BUILD_DIR/nova-uinput-gamepad-relay" ]; then
    if [ -d "${NOVA_HOLO_ROOTFS:-$BUILD_DIR/holo-rootfs/rootfs}" ]; then
        "$SCRIPT_DIR/build-uinput-gamepad-relay.sh" >/dev/null
    else
        echo "missing Holo rootfs; cannot package the controller relay" >&2
        echo "prepare the rootfs or set NOVA_HOLO_ROOTFS before building the product APK" >&2
        exit 1
    fi
fi

if [ ! -f "$BUILD_DIR/libnova-alsa-audiotrack-bridge.so" ]; then
    "$SCRIPT_DIR/build-alsa-audiotrack-bridge.sh" >/dev/null
fi

if [ ! -x "$BUILD_DIR/nova-zstd" ]; then
    "$SCRIPT_DIR/build-zstd.sh" >/dev/null
fi
if [ ! -x "$BUILD_DIR/nova-zip-rebase" ]; then
    "$SCRIPT_DIR/build-zip-rebase.sh" >/dev/null
fi

NOVA_KGSL_DRIVER=${NOVA_KGSL_DRIVER:-$BUILD_DIR/mesa-kgsl/libvulkan_freedreno.so}
if [ ! -f "$NOVA_KGSL_DRIVER" ]; then
    echo "missing known-good KGSL Turnip driver: $NOVA_KGSL_DRIVER" >&2
    echo "run build-kgsl-turnip.sh before building the first-run APK" >&2
    exit 1
fi
if [ "$NOVA_KGSL_DRIVER" != "$BUILD_DIR/mesa-kgsl/libvulkan_freedreno.so" ]; then
    mkdir -p "$BUILD_DIR/mesa-kgsl"
    cp "$NOVA_KGSL_DRIVER" "$BUILD_DIR/mesa-kgsl/libvulkan_freedreno.so"
fi

for required_helper in \
    nova-mount-private \
    nova-uinput-gamepad-relay \
    libsysv-sem-shim.so \
    libnova-cef-env-split.so \
    libffmpeg-avutil-compat.so \
    libnova-alsa-audiotrack-bridge.so; do
    if [ ! -f "$BUILD_DIR/$required_helper" ]; then
        echo "missing product helper: $BUILD_DIR/$required_helper" >&2
        exit 1
    fi
done

"$SCRIPT_DIR/build.sh"
