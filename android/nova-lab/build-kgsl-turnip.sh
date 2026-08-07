#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ROOTFS_HOST="$BUILD_DIR/holo-rootfs/rootfs"
SOURCE_DIR="${MESA_SOURCE_DIR:-$BUILD_DIR/mesa-src}"
MESA_REF="${MESA_REF:-mesa-25.2.7}"
MESON_BUILD_DIR="$BUILD_DIR/mesa-kgsl-build"
STAGE_DIR="$BUILD_DIR/mesa-kgsl-stage"
OUTPUT_DIR="$BUILD_DIR/mesa-kgsl"

if [ ! -d "$ROOTFS_HOST" ]; then
    echo "missing Holo rootfs: $ROOTFS_HOST" >&2
    exit 1
fi

if [ ! -d "$SOURCE_DIR/.git" ]; then
    git clone --depth 1 --branch "$MESA_REF" \
        https://gitlab.freedesktop.org/mesa/mesa.git "$SOURCE_DIR"
fi

mkdir -p "$MESON_BUILD_DIR" "$STAGE_DIR" "$OUTPUT_DIR"

docker run --rm --platform linux/arm64 --name nova-mesa-kgsl-build \
    -v "$SOURCE_DIR:/src:ro" \
    -v "$ROOTFS_HOST:/sysroot:ro" \
    -v "$BUILD_DIR:/out" \
    -v "$SCRIPT_DIR/mesa-kgsl.cross:/cross/mesa-kgsl.cross:ro" \
    ubuntu:24.04 bash -lc '
        set -eux
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq --no-install-recommends \
            gcc g++ meson ninja-build pkg-config python3 python3-pip \
            python3-mako python3-ply python3-yaml python3-packaging \
            bison flex glslang-tools libelf-dev libexpat1-dev libdrm-dev \
            libunwind-dev zlib1g-dev libzstd-dev ca-certificates
        python3 -m pip install --break-system-packages --no-cache-dir meson==1.4.2
        rm -rf /out/mesa-kgsl-build /out/mesa-kgsl-stage
        export PKG_CONFIG_SYSROOT_DIR=/sysroot
        export PKG_CONFIG_LIBDIR=/sysroot/usr/lib/pkgconfig:/sysroot/usr/share/pkgconfig
        meson setup /out/mesa-kgsl-build /src \
            --cross-file /cross/mesa-kgsl.cross \
            -Dprefix=/usr -Dlibdir=lib \
            -Dplatforms=[] -Dgallium-drivers=[] \
            -Dvulkan-drivers=freedreno -Dfreedreno-kmds=kgsl \
            -Dbuildtype=release -Dllvm=disabled -Dshared-llvm=disabled \
            -Dglx=disabled -Degl=disabled -Dgbm=disabled \
            -Dgles1=disabled -Dgles2=disabled -Dopengl=false \
            -Dshader-cache=disabled -Dvalgrind=disabled \
            -Dlibunwind=disabled -Dxmlconfig=disabled -Dtools=[]
        meson compile -C /out/mesa-kgsl-build -j2
        DESTDIR=/out/mesa-kgsl-stage meson install -C /out/mesa-kgsl-build
    '

cp "$STAGE_DIR/usr/lib/libvulkan_freedreno.so" "$OUTPUT_DIR/libvulkan_freedreno.so"
cp "$STAGE_DIR/usr/share/vulkan/icd.d/freedreno_icd.armv8-a.json" "$OUTPUT_DIR/freedreno_icd.armv8-a.json"

echo "driver=$OUTPUT_DIR/libvulkan_freedreno.so"
echo "manifest=$OUTPUT_DIR/freedreno_icd.armv8-a.json"
