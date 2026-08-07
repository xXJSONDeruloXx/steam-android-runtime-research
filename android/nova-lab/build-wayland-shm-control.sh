#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
DOCKER_IMAGE="${GAMESCOPE_BUILD_IMAGE:-debian:trixie-slim}"

mkdir -p "$BUILD_DIR"
docker run --rm --platform linux/arm64 -v "$SCRIPT_DIR/../..:/src:ro" -v "$BUILD_DIR:/out" "$DOCKER_IMAGE" sh -lc '
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update >/dev/null
apt-get install -y --no-install-recommends build-essential libwayland-dev wayland-protocols >/dev/null
wayland-scanner private-code /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml /tmp/xdg-shell-protocol.c
wayland-scanner client-header /usr/share/wayland-protocols/stable/xdg-shell/xdg-shell.xml /tmp/xdg-shell-client-protocol.h
gcc -O2 -std=c11 -I/tmp /src/android/nova-lab/device/wayland-shm-control.c /tmp/xdg-shell-protocol.c -lwayland-client -lrt -o /out/wayland-shm-control
'

echo "$BUILD_DIR/wayland-shm-control"
