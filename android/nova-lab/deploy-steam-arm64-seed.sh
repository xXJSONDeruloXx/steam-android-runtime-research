#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
STEAM_OUTPUT_DIR="${NOVA_STEAM_OUTPUT_DIR:-$BUILD_DIR/steam-arm64}"
ROOTFS_HOST="$BUILD_DIR/holo-rootfs/rootfs"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
DEVICE_STAGE=${DEVICE_STAGE:-/data/local/tmp/nova-steam-stage}
DEVICE_PREFIX=/opt/nova-steam
DEVICE_HOME="$DEVICE_PREFIX/home"
DEVICE_STEAM="$DEVICE_HOME/.local/share/Steam"
STEAM_UID=${NOVA_STEAM_UID:-0}
STEAM_GID=${NOVA_STEAM_GID:-$STEAM_UID}

case "$STEAM_UID:$STEAM_GID" in
    ''|*[!0-9:]*|*:*:*)
        echo "NOVA_STEAM_UID and NOVA_STEAM_GID must be numeric" >&2
        exit 1
        ;;
esac

if [ ! -d "$ROOTFS_HOST" ]; then
    echo "missing extracted Holo rootfs: $ROOTFS_HOST" >&2
    echo "run fetch-holo-rootfs.sh first" >&2
    exit 1
fi

"$SCRIPT_DIR/fetch-steam-arm64-seed.sh" --all >/dev/null

METADATA="$STEAM_OUTPUT_DIR/metadata.tsv"
PACKAGE_DIR="$STEAM_OUTPUT_DIR/package"
metadata_value() {
    awk -F '\t' -v key="$1" '$1 == key { print $2; exit }' "$METADATA"
}

SEED_PACKAGE=$(metadata_value seed_package)
SEED="$PACKAGE_DIR/$SEED_PACKAGE"
RUNTIME="$STEAM_OUTPUT_DIR/steam-runtime-steamrt-arm64.tar.xz"
for required in "$SEED" "$RUNTIME"; do
    if [ ! -f "$required" ]; then
        echo "missing Steam ARM64 input: $required" >&2
        exit 1
    fi
done

# Valve's seed has a short self-extracting prefix before the ZIP central
# directory. Desktop unzip accepts it, but Android toybox unzip rejects it as
# invalid. Extract the seed on the host, then push the resulting ARM64 tree.
HOST_SEED_DIR=$(mktemp -d "${TMPDIR:-/tmp}/nova-steam-seed.XXXXXX")
HOST_RUNTIME_DIR=$(mktemp -d "${TMPDIR:-/tmp}/nova-steam-runtime.XXXXXX")
HOST_RUNTIME_TAR=$(mktemp "${TMPDIR:-/tmp}/nova-steam-runtime.XXXXXX")
trap 'rm -rf "$HOST_SEED_DIR" "$HOST_RUNTIME_DIR" "$HOST_RUNTIME_TAR"' EXIT
unzip -q -o "$SEED" -d "$HOST_SEED_DIR"
if [ ! -d "$HOST_SEED_DIR/steamrtarm64" ]; then
    echo "seed extraction did not produce steamrtarm64" >&2
    exit 1
fi
tar -xJf "$RUNTIME" -C "$HOST_RUNTIME_DIR"
tar -cf "$HOST_RUNTIME_TAR" -C "$HOST_RUNTIME_DIR" steam-runtime-steamrt-arm64
if [ ! -f "$HOST_RUNTIME_DIR/steam-runtime-steamrt-arm64/VERSIONS.txt" ]; then
    echo "runtime extraction did not produce steam-runtime-steamrt-arm64" >&2
    exit 1
fi

"$ADB" wait-for-device
"$ADB" shell "su -c 'mkdir -p $DEVICE_STAGE; chmod 777 $DEVICE_STAGE'"
"$ADB" shell "su -c 'rm -rf $DEVICE_STAGE/steamrtarm64; rm -f $DEVICE_STAGE/steam-runtime-steamrt-arm64.tar'"
"$ADB" push "$HOST_SEED_DIR/steamrtarm64" "$DEVICE_STAGE/" >/dev/null
"$ADB" push "$HOST_RUNTIME_TAR" "$DEVICE_STAGE/steam-runtime-steamrt-arm64.tar" >/dev/null

"$ADB" shell "su -c 'rm -rf $DEVICE_ROOT$DEVICE_PREFIX; mkdir -p $DEVICE_ROOT$DEVICE_STEAM'"
"$ADB" shell "su -c 'cp -R $DEVICE_STAGE/steamrtarm64 $DEVICE_ROOT$DEVICE_STEAM/'"
"$ADB" shell "su -c '/system/bin/tar -xf $DEVICE_STAGE/steam-runtime-steamrt-arm64.tar -C $DEVICE_ROOT$DEVICE_STEAM'"
"$ADB" shell "su -c 'mkdir -p $DEVICE_ROOT$DEVICE_STEAM/package $DEVICE_ROOT$DEVICE_HOME/.steam; printf %s\\n steamdeck_publicbeta > $DEVICE_ROOT$DEVICE_STEAM/package/beta; cd $DEVICE_ROOT$DEVICE_HOME/.steam; ln -sfn ../.local/share/Steam steam; ln -sfn ../.local/share/Steam root; ln -sfn ../.local/share/Steam/linux32 sdk32; ln -sfn ../.local/share/Steam/linux64 sdk64; ln -sfn ../.local/share/Steam/linuxarm64 sdkarm64; ln -sfn ../.local/share/Steam/ubuntu12_32 bin32; ln -sfn ../.local/share/Steam/ubuntu12_64 bin64'"

"$ADB" shell "su -c '
    set -eu
    steam=$DEVICE_ROOT$DEVICE_STEAM
    test -d \"\$steam/steam-runtime-steamrt-arm64\"
    find \"\$steam/steam-runtime-steamrt-arm64\" -type d -path \"*/files/lib/aarch64-linux-gnu\" | while IFS= read -r libdir; do
        find \"\$libdir\" -maxdepth 1 -type f -name \"*.so.*.*\" | while IFS= read -r library; do
            filename=\${library##*/}
            stem=\${filename%%.so.*}
            version=\${filename#*.so.}
            soname=\"\$libdir/\$stem.so.\${version%%.*}\"
            [ -e \"\$soname\" ] || ln -s \"\$filename\" \"\$soname\"
        done
    done
    ibus=\$(find \"\$steam/steam-runtime-steamrt-arm64\" -path \"*/files/lib/aarch64-linux-gnu/libibus-1.0.so.5.*\" -type f | sort | tail -n 1)
    test -n \"\$ibus\"
    mkdir -p \"\$steam/lib/aarch64-linux-gnu\"
    relative=\${ibus#\"\$steam/\"}
    ln -sfn \"../../\$relative\" \"\$steam/lib/aarch64-linux-gnu/libibus-1.0.so.5\"
    chmod +x \"\$steam/steamrtarm64/steam\" \"\$steam/steamrtarm64/steamwebhelper\" || true
    test -x \"\$steam/steamrtarm64/steam\"
    test -f \"\$steam/steamrtarm64/steamui.so\"
    test -f \"\$steam/package/beta\"
    test -L \"\$steam/lib/aarch64-linux-gnu/libibus-1.0.so.5\"
    printf \"steam_root=%s\\nseed=%s\\nruntime=%s\\nsteam=%s\\nsteamui=%s\\nlibibus=%s\\n\" \"\$steam\" \"$SEED_PACKAGE\" \"$(metadata_value runtime_snapshot)\" \"\$steam/steamrtarm64/steam\" \"\$steam/steamrtarm64/steamui.so\" \"\$steam/lib/aarch64-linux-gnu/libibus-1.0.so.5\" > $DEVICE_ROOT$DEVICE_PREFIX/deploy-report.txt
'"

if [ "$STEAM_UID" -eq 0 ]; then
    "$ADB" shell "su -c 'rm -f $DEVICE_ROOT$DEVICE_PREFIX/run-as-user'"
else
    # The Holo image is intentionally minimal and does not ship a desktop
    # account database. setpriv can still create the real/effective uid
    # contract Steam expects; this marker makes that choice reproducible.
    "$ADB" shell "su -c 'chown -R $STEAM_UID:$STEAM_GID $DEVICE_ROOT$DEVICE_HOME; printf %s:%s\\\\n $STEAM_UID $STEAM_GID > $DEVICE_ROOT$DEVICE_PREFIX/run-as-user; chmod 644 $DEVICE_ROOT$DEVICE_PREFIX/run-as-user'"
fi

"$ADB" shell "su -c 'rm -rf $DEVICE_STAGE/steamrtarm64; rm -f $DEVICE_STAGE/steam-runtime-steamrt-arm64.tar'"
"$ADB" shell "su -c 'cat $DEVICE_ROOT$DEVICE_PREFIX/deploy-report.txt'"
echo "steam_seed_deploy=pass"
