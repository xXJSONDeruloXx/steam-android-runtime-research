#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ROOTFS_HOST="$BUILD_DIR/holo-rootfs/rootfs"
SOURCE_DIR="${MESA_SOURCE_DIR:-$BUILD_DIR/mesa-src}"
MESA_REF="${MESA_REF:-mesa-25.2.7}"
MESA_PLATFORMS="${NOVA_MESA_PLATFORMS:-x11}"
X11_SYSROOT_HOST="${NOVA_MESA_X11_SYSROOT:-$BUILD_DIR/x11-capture-sysroot}"
X11_PACKAGE_DIR="${NOVA_MESA_X11_PACKAGE_DIR:-$BUILD_DIR/holo-rootfs/packages}"
SYSROOT_HOST="${NOVA_MESA_SYSROOT:-$ROOTFS_HOST}"
MERGED_SYSROOT_HOST="$BUILD_DIR/mesa-kgsl-sysroot"
MESON_BUILD_DIR="$BUILD_DIR/mesa-kgsl-build"
STAGE_DIR="$BUILD_DIR/mesa-kgsl-stage"
OUTPUT_DIR="$BUILD_DIR/mesa-kgsl"

if [ ! -d "$ROOTFS_HOST" ]; then
    echo "missing Holo rootfs: $ROOTFS_HOST" >&2
    exit 1
fi

case ",$MESA_PLATFORMS," in
    *,x11,*)
        if [ -z "${NOVA_MESA_SYSROOT:-}" ]; then
            if [ ! -d "$X11_SYSROOT_HOST/usr/include/X11" ] || \
                [ ! -d "$X11_SYSROOT_HOST/usr/lib/pkgconfig" ]; then
                echo "missing aarch64 X11 sysroot: $X11_SYSROOT_HOST" >&2
                exit 1
            fi
            if [ -e "$MERGED_SYSROOT_HOST" ]; then
                find "$MERGED_SYSROOT_HOST" -type d -exec chmod u+rwx {} +
                rm -rf "$MERGED_SYSROOT_HOST"
            fi
            mkdir -p "$MERGED_SYSROOT_HOST"
            cp -al "$ROOTFS_HOST"/. "$MERGED_SYSROOT_HOST"/
            cp -a "$X11_SYSROOT_HOST"/. "$MERGED_SYSROOT_HOST"/
            if [ ! -f "$MERGED_SYSROOT_HOST/usr/lib/pkgconfig/xshmfence.pc" ]; then
                xshmfence_package=$(printf '%s\n' \
                    "$X11_PACKAGE_DIR"/libxshmfence-*.pkg.tar.zst | head -n 1)
                if [ ! -f "$xshmfence_package" ]; then
                    echo "missing target xshmfence package in: $X11_PACKAGE_DIR" >&2
                    exit 1
                fi
                if ! command -v zstd >/dev/null 2>&1; then
                    echo "zstd is required to extend the merged Mesa sysroot" >&2
                    exit 1
                fi
                zstd -dc "$xshmfence_package" | \
                    tar -xf - -C "$MERGED_SYSROOT_HOST"
            fi
            SYSROOT_HOST="$MERGED_SYSROOT_HOST"
        fi
        ;;
esac

if [ ! -d "$SOURCE_DIR/.git" ]; then
    git clone --depth 1 --branch "$MESA_REF" \
        https://gitlab.freedesktop.org/mesa/mesa.git "$SOURCE_DIR"
fi

mkdir -p "$MESON_BUILD_DIR" "$STAGE_DIR" "$OUTPUT_DIR"

docker run --rm --platform linux/arm64 --name nova-mesa-kgsl-build \
    -e NOVA_MESA_PLATFORMS="$MESA_PLATFORMS" \
    -v "$SOURCE_DIR:/src:ro" \
    -v "$SYSROOT_HOST:/sysroot:ro" \
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
            libunwind-dev zlib1g-dev libzstd-dev libx11-dev libx11-xcb-dev \
            libxcb1-dev libxcb-dri2-0-dev libxcb-dri3-dev libxcb-present-dev \
            libxcb-sync-dev libxcb-xfixes0-dev libxshmfence-dev \
            ca-certificates
        python3 -m pip install --break-system-packages --no-cache-dir meson==1.4.2
        rm -rf /out/mesa-kgsl-build /out/mesa-kgsl-stage
        export PKG_CONFIG_SYSROOT_DIR=/sysroot
        export PKG_CONFIG_LIBDIR=/sysroot/usr/lib/pkgconfig:/sysroot/usr/share/pkgconfig
        meson setup /out/mesa-kgsl-build /src \
            --cross-file /cross/mesa-kgsl.cross \
            -Dprefix=/usr -Dlibdir=lib \
            -Dplatforms="$NOVA_MESA_PLATFORMS" -Dgallium-drivers=[] \
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
echo "platforms=$MESA_PLATFORMS"
