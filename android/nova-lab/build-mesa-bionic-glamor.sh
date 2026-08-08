#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
SOURCE_DIR="${MESA_SOURCE_DIR:-$BUILD_DIR/mesa-src}"
MESA_REF="${MESA_REF:-mesa-25.2.7}"
MESON_BUILD_DIR="$BUILD_DIR/mesa-bionic-glamor-build"
STAGE_DIR="$BUILD_DIR/mesa-bionic-glamor-stage"
OUTPUT_DIR="$BUILD_DIR/mesa-bionic-glamor"
ANDROID_API="${ANDROID_API:-34}"
MESA_JOBS="${MESA_JOBS:-2}"

find_ndk() {
    local candidate

    for candidate in "${ANDROID_NDK_ROOT:-}" "${ANDROID_NDK_HOME:-}" "${ANDROID_NDK:-}"; do
        if [ -n "$candidate" ] && [ -x "$candidate/toolchains/llvm/prebuilt/darwin-x86_64/bin/aarch64-linux-android${ANDROID_API}-clang" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
        if [ -n "$candidate" ] && [ -x "$candidate/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android${ANDROID_API}-clang" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    if [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME/ndk" ]; then
        find "$ANDROID_HOME/ndk" -mindepth 1 -maxdepth 1 -type d -print | sort | tail -n 1
        return 0
    fi

    echo "Android NDK not found; set ANDROID_NDK_ROOT" >&2
    return 1
}

NDK_DIR=$(find_ndk)
case "$(uname -s)" in
    Darwin)
        NDK_HOST_TAG=darwin-x86_64
        ;;
    Linux)
        NDK_HOST_TAG=linux-x86_64
        ;;
    *)
        echo "unsupported build host: $(uname -s)" >&2
        exit 1
        ;;
esac

TOOLCHAIN_DIR="$NDK_DIR/toolchains/llvm/prebuilt/$NDK_HOST_TAG/bin"
if [ ! -x "$TOOLCHAIN_DIR/aarch64-linux-android${ANDROID_API}-clang" ]; then
    echo "NDK toolchain is missing aarch64-linux-android${ANDROID_API}-clang: $TOOLCHAIN_DIR" >&2
    exit 1
fi

export PATH="$TOOLCHAIN_DIR:$PATH"
if [ -d /opt/homebrew/opt/bison/bin ]; then
    export PATH="/opt/homebrew/opt/bison/bin:$PATH"
fi

if [ ! -d "$SOURCE_DIR/.git" ]; then
    mkdir -p "$(dirname "$SOURCE_DIR")"
    git clone --depth 1 --branch "$MESA_REF" \
        https://gitlab.freedesktop.org/mesa/mesa.git "$SOURCE_DIR"
fi

MESA_COMMIT=$(git -C "$SOURCE_DIR" rev-parse HEAD)
rm -rf "$MESON_BUILD_DIR" "$STAGE_DIR" "$OUTPUT_DIR"
mkdir -p "$MESON_BUILD_DIR" "$STAGE_DIR" "$OUTPUT_DIR"

meson setup "$MESON_BUILD_DIR" "$SOURCE_DIR" \
    --cross-file "$SCRIPT_DIR/mesa-bionic.cross" \
    -Dprefix=/opt/nova-mesa-bionic \
    -Dlibdir=lib \
    -Dplatforms=android \
    -Dplatform-sdk-version="$ANDROID_API" \
    -Dandroid-stub=true \
    -Dandroid-libbacktrace=disabled \
    -Dgallium-drivers=freedreno,zink \
    -Dvulkan-drivers=freedreno \
    -Dfreedreno-kmds=kgsl \
    -Dglx=disabled \
    -Degl=enabled \
    -Dgbm=enabled \
    -Dgles1=disabled \
    -Dgles2=enabled \
    -Dopengl=true \
    -Dglvnd=disabled \
    -Dshader-cache=disabled \
    -Dzlib=enabled \
    -Dzstd=disabled \
    -Dxmlconfig=disabled \
    -Dllvm=disabled \
    -Dshared-llvm=disabled \
    -Dlibunwind=disabled \
    -Dvalgrind=disabled \
    -Dbuild-tests=false \
    -Dtools=[] \
    -Dallow-fallback-for=libdrm \
    -Dbuildtype=release \
    -Db_ndebug=true

meson compile -C "$MESON_BUILD_DIR" -j "$MESA_JOBS"
DESTDIR="$STAGE_DIR" meson install -C "$MESON_BUILD_DIR"

INSTALL_ROOT="$STAGE_DIR/opt/nova-mesa-bionic"

# Android builds intentionally use the unversioned Android SONAMEs and do not
# enter the desktop DRI symlink-install path when X11 is not selected. Provide
# the conventional names a Bionic Xwayland/GBM probe will look for, all pointing
# at the exact libraries built above.
ln -s libEGL.so "$INSTALL_ROOT/lib/libEGL.so.1"
ln -s libGLESv2.so "$INSTALL_ROOT/lib/libGLESv2.so.2"
ln -s libgbm_mesa.so "$INSTALL_ROOT/lib/libgbm.so"
ln -s libgbm_mesa.so "$INSTALL_ROOT/lib/libgbm.so.1"
ln -s libdrm.so "$INSTALL_ROOT/lib/libdrm.so.2"
mkdir -p "$INSTALL_ROOT/lib/dri"
for driver in msm_dri.so kgsl_dri.so zink_dri.so; do
    ln -s ../libgallium_dri.so "$INSTALL_ROOT/lib/dri/$driver"
done

# Meson installs the fallback subprojects' development payload as well. Keep
# the release artifact to the runtime DSOs and ICD; headers, pkg-config files,
# and decode-tool libraries are not part of the sidecar's runtime contract.
rm -rf "$INSTALL_ROOT/bin" "$INSTALL_ROOT/include" "$INSTALL_ROOT/lib/pkgconfig"
rm -f "$INSTALL_ROOT/lib/libarchive.so" "$INSTALL_ROOT/lib/libxml2.so"
rm -f "$INSTALL_ROOT/lib/libdrm_amdgpu.so" "$INSTALL_ROOT/lib/libdrm_etnaviv.so"
rm -f "$INSTALL_ROOT/lib/libdrm_nouveau.so" "$INSTALL_ROOT/lib/libdrm_radeon.so"

required_files=(
    "$INSTALL_ROOT/lib/libEGL.so"
    "$INSTALL_ROOT/lib/libEGL.so.1"
    "$INSTALL_ROOT/lib/libGLESv2.so"
    "$INSTALL_ROOT/lib/libGLESv2.so.2"
    "$INSTALL_ROOT/lib/libgbm_mesa.so"
    "$INSTALL_ROOT/lib/libgbm.so.1"
    "$INSTALL_ROOT/lib/libdrm.so"
    "$INSTALL_ROOT/lib/libdrm.so.2"
    "$INSTALL_ROOT/lib/libvulkan_freedreno.so"
    "$INSTALL_ROOT/lib/libgallium_dri.so"
    "$INSTALL_ROOT/lib/dri/msm_dri.so"
    "$INSTALL_ROOT/lib/dri/kgsl_dri.so"
    "$INSTALL_ROOT/lib/dri/zink_dri.so"
    "$INSTALL_ROOT/lib/gbm/dri_gbm.so"
)

for required_file in "${required_files[@]}"; do
    if [ ! -e "$required_file" ]; then
        echo "Bionic Mesa output is missing: $required_file" >&2
        find "$INSTALL_ROOT" -maxdepth 4 \( -type f -o -type l \) -print | sort >&2 || true
        exit 1
    fi
done

cp "$SCRIPT_DIR/mesa-bionic.cross" "$OUTPUT_DIR/mesa-bionic.cross"
cp "$SOURCE_DIR/docs/license.rst" "$OUTPUT_DIR/Mesa-LICENSE.rst"

tar -C "$STAGE_DIR" -czf \
    "$OUTPUT_DIR/nova-mesa-bionic-glamor-arm64.tar.gz" \
    opt/nova-mesa-bionic

sha256sum "$OUTPUT_DIR/nova-mesa-bionic-glamor-arm64.tar.gz" \
    | tee "$OUTPUT_DIR/nova-mesa-bionic-glamor-arm64.tar.gz.sha256"

echo "mesa_ref=$MESA_REF"
echo "mesa_commit=$MESA_COMMIT"
echo "ndk=$NDK_DIR"
echo "android_api=$ANDROID_API"
echo "artifact=$OUTPUT_DIR/nova-mesa-bionic-glamor-arm64.tar.gz"
