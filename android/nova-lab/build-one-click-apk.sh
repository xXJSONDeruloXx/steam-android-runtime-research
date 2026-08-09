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

"$SCRIPT_DIR/build.sh"
