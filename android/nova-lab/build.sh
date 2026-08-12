#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SDK_ROOT=${ANDROID_SDK_ROOT:-/opt/homebrew/share/android-commandlinetools}
BUILD_TOOLS=${ANDROID_BUILD_TOOLS:-35.0.1}
PLATFORM=${ANDROID_PLATFORM:-android-35}
BUILD_DIR="$SCRIPT_DIR/build"
APK_ASSET_DIR="$BUILD_DIR/apk-assets"
TOOLS_DIR="$SDK_ROOT/build-tools/$BUILD_TOOLS"
ANDROID_JAR="$SDK_ROOT/platforms/$PLATFORM/android.jar"
NDK_ROOT=${ANDROID_NDK_ROOT:-$SDK_ROOT/ndk/27.3.13750724}
NDK_TOOLCHAIN="$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64"
NATIVE_COMPILER="$NDK_TOOLCHAIN/bin/aarch64-linux-android29-clang"

for tool in aapt2 d8 apksigner zipalign; do
    if [ ! -x "$TOOLS_DIR/$tool" ]; then
        echo "missing Android tool: $TOOLS_DIR/$tool" >&2
        exit 1
    fi
done
if [ ! -f "$ANDROID_JAR" ]; then
    echo "missing Android platform: $ANDROID_JAR" >&2
    exit 1
fi
if [ ! -x "$NATIVE_COMPILER" ]; then
    echo "missing Android NDK compiler: $NATIVE_COMPILER" >&2
    exit 1
fi

rm -rf "$BUILD_DIR/classes" "$BUILD_DIR/dex" "$BUILD_DIR/compiled" \
    "$BUILD_DIR/gen" "$BUILD_DIR/native" "$APK_ASSET_DIR"
mkdir -p "$BUILD_DIR/classes" "$BUILD_DIR/dex" "$BUILD_DIR/compiled" "$BUILD_DIR/gen"
mkdir -p "$BUILD_DIR/native/lib/arm64-v8a"
mkdir -p "$APK_ASSET_DIR"

cp -R "$SCRIPT_DIR/src/main/assets/." "$APK_ASSET_DIR/"
for helper in \
    nova-x11-private-namespace.sh \
    nova-termux-x11-cleanup.sh \
    nova-termux-x11-steam-client.sh \
    nova-uinput-gamepad-relay-launcher.sh \
    nova-runtime-cleanup.sh \
    nova-steam-network-api-compat.sh \
    nova-steamos-update-compat.sh \
    holo-package-install.sh \
    nova-rooted-prepare-runtime4.sh \
    nova-steam-arm64-official-compatibilitytools.vdf.in \
    nova-proton-glibc-geometry-wars.sh \
    nova-proton-11-arm64-wrapper-setup.sh \
    nova-proton-11-arm64-compatibilitytool.vdf \
    nova-proton-11-arm64-wrapper-compatibilitytool.vdf; do
    cp "$SCRIPT_DIR/device/$helper" "$APK_ASSET_DIR/$helper"
done

for provisioning_asset in \
    nova-runtime-manifest.tsv \
    holo-direct-termux-x11.packages.tsv; do
    cp "$SCRIPT_DIR/provisioning/$provisioning_asset" "$APK_ASSET_DIR/$provisioning_asset"
done

for rootless_asset in \
    nova-rootless-termux-x11.sh \
    nova-rootless-proc-net-shadow.sh \
    nova-rootless-pulseaudio-tcp.sh \
    nova-rootless-session-guard.py \
    nova-rootless-prepare-runtime4.sh \
    nova-rootless-steam-arm64-compatibilitytools.vdf.in \
    nova-rootless-transport-probe.sh \
    nova-rootless-proot-supervisor.sh \
    nova-rootless-extract-rootfs.sh \
    nova-rootless-prepare-guest-rootfs.sh \
    nova-rootless-profile.tsv \
    nova-rootless-steamui-holo-packages.tsv \
    nova-rootless-steamui-external-assets.tsv \
    termux.properties; do
    cp "$SCRIPT_DIR/rootless/$rootless_asset" "$APK_ASSET_DIR/$rootless_asset"
done

BOOTSTRAP_DIR="$BUILD_DIR/bsdtar-bootstrap"
if [ ! -x "$BOOTSTRAP_DIR/rootfs/usr/bin/bsdtar" ] ||
    [ ! -f "$BOOTSTRAP_DIR/manifest.tsv" ]; then
    echo "missing rootless archive bootstrap: $BOOTSTRAP_DIR" >&2
    echo "run android/nova-lab/build-bsdtar-bootstrap.sh first" >&2
    exit 1
fi
mkdir -p "$APK_ASSET_DIR/nova-bsdtar-bootstrap"
cp -R "$BOOTSTRAP_DIR/rootfs/." "$APK_ASSET_DIR/nova-bsdtar-bootstrap/"
cp "$BOOTSTRAP_DIR/manifest.tsv" "$APK_ASSET_DIR/nova-bsdtar-bootstrap/manifest.tsv"

for required_artifact in \
    "$BUILD_DIR/nova-zstd" \
    "$BUILD_DIR/nova-zip-rebase" \
    "$BUILD_DIR/mesa-kgsl/libvulkan_freedreno.so"; do
    if [ ! -f "$required_artifact" ]; then
        echo "missing first-run provisioning artifact: $required_artifact" >&2
        echo "run build-zstd.sh, build-zip-rebase.sh, and build-kgsl-turnip.sh first" >&2
        exit 1
    fi
done
cp "$BUILD_DIR/nova-zstd" "$APK_ASSET_DIR/nova-zstd"
cp "$BUILD_DIR/nova-zip-rebase" "$APK_ASSET_DIR/nova-zip-rebase"
cp "$BUILD_DIR/mesa-kgsl/libvulkan_freedreno.so" "$APK_ASSET_DIR/libvulkan_freedreno.so"
cp "$SCRIPT_DIR/device/freedreno-kgsl.icd.json" "$APK_ASSET_DIR/freedreno-kgsl.icd.json"
chmod 755 "$APK_ASSET_DIR/nova-zstd" "$APK_ASSET_DIR/nova-zip-rebase" \
    "$APK_ASSET_DIR/libvulkan_freedreno.so"

# These are device-side helpers, not Android JNI libraries. Package them only
# when the corresponding local build artifact exists; the launcher reports a
# missing optional helper instead of confusing a diagnostic APK build with a
# complete device installation.
for optional_helper in \
    nova-mount-private \
    nova-uinput-gamepad-relay \
    libsysv-sem-shim.so \
    libnova-cef-env-split.so \
    libffmpeg-avutil-compat.so \
    libsdl3-compat.so \
    libposix-sync-trace.so \
    libnova-alsa-audiotrack-bridge.so; do
    if [ -f "$BUILD_DIR/$optional_helper" ]; then
        cp "$BUILD_DIR/$optional_helper" "$APK_ASSET_DIR/$optional_helper"
    fi
done

"$NATIVE_COMPILER" \
    -shared -fPIC -O2 -std=c11 \
    -I"$NDK_TOOLCHAIN/sysroot/usr/include" \
    -o "$BUILD_DIR/native/lib/arm64-v8a/libnovabridge.so" \
    "$SCRIPT_DIR/src/main/cpp/novabridge.c" \
    "$SCRIPT_DIR/src/main/cpp/androidvulkan.c" \
    "$SCRIPT_DIR/src/main/cpp/ahbbridge.c" \
    -landroid -llog -lvulkan

"$TOOLS_DIR/aapt2" compile --dir "$SCRIPT_DIR/src/main/res" -o "$BUILD_DIR/compiled"

"$TOOLS_DIR/aapt2" link \
    -o "$BUILD_DIR/resources.apk" \
    -I "$ANDROID_JAR" \
    --manifest "$SCRIPT_DIR/AndroidManifest.xml" \
    --java "$BUILD_DIR/gen" \
    --auto-add-overlay \
    --min-sdk-version 29 \
    --target-sdk-version 35 \
    --version-code 3 \
    --version-name 0.3 \
    -A "$APK_ASSET_DIR" \
    "$BUILD_DIR/compiled"/*.flat

find "$SCRIPT_DIR/src/main/java" -type f -name '*.java' -print > "$BUILD_DIR/java-sources.txt"
javac -source 8 -target 8 -encoding UTF-8 \
    -classpath "$ANDROID_JAR" \
    -d "$BUILD_DIR/classes" \
    @"$BUILD_DIR/java-sources.txt"

jar cf "$BUILD_DIR/classes.jar" -C "$BUILD_DIR/classes" .
"$TOOLS_DIR/d8" \
    --lib "$ANDROID_JAR" \
    --min-api 29 \
    --output "$BUILD_DIR/dex" \
    "$BUILD_DIR/classes.jar"

cp "$BUILD_DIR/resources.apk" "$BUILD_DIR/unsigned.apk"
(
    cd "$BUILD_DIR/dex"
    zip -q -u "$BUILD_DIR/unsigned.apk" classes.dex
)
(
    cd "$BUILD_DIR/native"
    zip -q -u "$BUILD_DIR/unsigned.apk" lib/arm64-v8a/libnovabridge.so
)

DEBUG_KEYSTORE="$BUILD_DIR/debug.keystore"
if [ ! -f "$DEBUG_KEYSTORE" ]; then
    keytool -genkeypair \
        -keystore "$DEBUG_KEYSTORE" \
        -storepass android \
        -keypass android \
        -alias androiddebugkey \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -dname 'CN=Android Debug,O=Android,C=US' >/dev/null 2>&1
fi

"$TOOLS_DIR/zipalign" -f 4 "$BUILD_DIR/unsigned.apk" "$BUILD_DIR/aligned.apk"
"$TOOLS_DIR/apksigner" sign \
    --ks "$DEBUG_KEYSTORE" \
    --ks-pass pass:android \
    --key-pass pass:android \
    --out "$BUILD_DIR/nova-lab-debug.apk" \
    "$BUILD_DIR/aligned.apk"
"$TOOLS_DIR/apksigner" verify --verbose "$BUILD_DIR/nova-lab-debug.apk" >/dev/null

echo "$BUILD_DIR/nova-lab-debug.apk"
