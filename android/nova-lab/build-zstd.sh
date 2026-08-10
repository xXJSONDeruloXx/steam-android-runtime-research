#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
SDK_ROOT=${ANDROID_SDK_ROOT:-/opt/homebrew/share/android-commandlinetools}
NDK_ROOT=${ANDROID_NDK_ROOT:-$SDK_ROOT/ndk/27.3.13750724}
TOOLCHAIN="$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64"
COMPILER="$TOOLCHAIN/bin/aarch64-linux-android29-clang"
VERSION=1.5.7
ARCHIVE="$BUILD_DIR/zstd-v$VERSION.tar.gz"
ARCHIVE_URL="https://github.com/facebook/zstd/archive/refs/tags/v$VERSION.tar.gz"
ARCHIVE_SHA256=37d7284556b20954e56e1ca85b80226768902e2edabd3b649e9e72c0c9012ee3
SOURCE_DIR="$BUILD_DIR/zstd-v$VERSION"

if [ ! -x "$COMPILER" ]; then
    echo "missing Android ARM64 compiler: $COMPILER" >&2
    exit 1
fi

mkdir -p "$BUILD_DIR"
if [ ! -f "$ARCHIVE" ]; then
    curl --fail --location --retry 3 --output "$ARCHIVE.part" "$ARCHIVE_URL"
    mv "$ARCHIVE.part" "$ARCHIVE"
fi
actual_sha256=$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')
if [ "$actual_sha256" != "$ARCHIVE_SHA256" ]; then
    echo "zstd source SHA-256 mismatch: $actual_sha256 != $ARCHIVE_SHA256" >&2
    exit 1
fi

rm -rf "$SOURCE_DIR"
mkdir -p "$SOURCE_DIR"
tar -xzf "$ARCHIVE" -C "$SOURCE_DIR" --strip-components=1
make -C "$SOURCE_DIR/programs" clean >/dev/null
make -C "$SOURCE_DIR/programs" -j2 \
    CC="$COMPILER" \
    CFLAGS='-O2 -static' \
    LDFLAGS='-static' \
    zstd >/dev/null
cp "$SOURCE_DIR/programs/zstd" "$BUILD_DIR/nova-zstd"
"$TOOLCHAIN/bin/llvm-strip" "$BUILD_DIR/nova-zstd" 2>/dev/null || true
chmod 755 "$BUILD_DIR/nova-zstd"

echo "$BUILD_DIR/nova-zstd"
