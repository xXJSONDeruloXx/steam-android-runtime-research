#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
PATCH_FILE="$SCRIPT_DIR/patches/gamescope-headless-no-drm-identity.patch"
SOURCE_DIR="${GAMESCOPE_SOURCE:-}"
WORKTREE="${GAMESCOPE_HEADLESS_SOURCE:-$BUILD_DIR/gamescope-headless-source}"
OUT_DIR="${GAMESCOPE_HEADLESS_BUILD:-$BUILD_DIR/gamescope-headless-build}"
DOCKER_IMAGE="${GAMESCOPE_BUILD_IMAGE:-debian:trixie-slim}"

if [ ! -d "$WORKTREE/.git" ]; then
    if [ -z "$SOURCE_DIR" ]; then
        echo "set GAMESCOPE_SOURCE to a local gamescope checkout" >&2
        exit 1
    fi
    mkdir -p "$BUILD_DIR"
    git clone --recursive "$SOURCE_DIR" "$WORKTREE"
fi

git -C "$WORKTREE" submodule update --init --recursive
if git -C "$WORKTREE" apply --unidiff-zero --check "$PATCH_FILE" 2>/dev/null; then
    git -C "$WORKTREE" apply --unidiff-zero "$PATCH_FILE"
elif ! git -C "$WORKTREE" apply --unidiff-zero --reverse --check "$PATCH_FILE" 2>/dev/null; then
    echo "gamescope source is not compatible with $PATCH_FILE" >&2
    exit 1
fi

mkdir -p "$OUT_DIR"
docker run --rm --platform linux/arm64 \
    -v "$WORKTREE:/src" \
    -v "$OUT_DIR:/out" \
    "$DOCKER_IMAGE" \
    sh -lc '
set -e
apt-get update >/dev/null
apt-get install -y --no-install-recommends \
    ca-certificates build-essential git meson ninja-build pkg-config clang glslang-tools hwdata \
    libcap-dev libx11-dev libxmu-dev libxcomposite-dev libxrender-dev libxres-dev libxtst-dev \
    libxkbcommon-dev libdrm-dev libinput-dev libwayland-dev wayland-protocols xwayland cmake \
    libdecor-0-dev libxdamage-dev libxfixes-dev libxxf86vm-dev libxi-dev libxcursor-dev libxext-dev \
    libxrandr-dev libpixman-1-dev libudev-dev libluajit-5.1-dev libepoxy-dev libseat-dev \
    libdisplay-info-dev libvulkan-dev libegl-dev libgbm-dev libxcb1-dev libxcb-ewmh-dev \
    libxcb-dri3-dev libxcb-present-dev libxcb-render-util0-dev libxcb-xfixes0-dev libxcb-xinput-dev \
    libxcb-xkb-dev libxkbcommon-x11-dev liblcms2-dev libxcb-composite0-dev libxcb-icccm4-dev \
    libxcb-res0-dev >/dev/null
MESON_OPTIONS="\
-Dauto_features=enabled \
-Davif_screenshots=disabled \
-Dbenchmark=disabled \
-Ddrm_backend=enabled \
-Denable_gamescope_wsi_layer=false \
-Denable_openvr_support=false \
-Dforce_fallback_for=wlroots,libliftoff,vkroots,libdisplay-info \
-Dinput_emulation=disabled \
-Dpipewire=disabled \
-Dprefix=/usr \
-Drt_cap=disabled \
-Dsdl2_backend=disabled \
-Dwarning_level=1 \
-Dwlroots:xcb-errors=disabled"
if [ -f /out/build.ninja ]; then
    meson configure /out $MESON_OPTIONS
else
    meson setup /out /src $MESON_OPTIONS
fi
ninja -C /out src/gamescope
'

echo "$OUT_DIR/src/gamescope"
