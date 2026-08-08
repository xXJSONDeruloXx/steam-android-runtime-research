#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
SDK_ROOT=${ANDROID_SDK_ROOT:-/opt/homebrew/share/android-commandlinetools}
NDK_ROOT=${ANDROID_NDK_ROOT:-$SDK_ROOT/ndk/27.3.13750724}
NDK_TOOLCHAIN="$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64"
NATIVE_COMPILER="$NDK_TOOLCHAIN/bin/aarch64-linux-android29-clang"
OUTPUT=${NOVA_MOUNT_PRIVATE_OUTPUT:-$SCRIPT_DIR/build/nova-mount-private}

if [ ! -x "$NATIVE_COMPILER" ]; then
    echo "missing Android NDK compiler: $NATIVE_COMPILER" >&2
    exit 1
fi

mkdir -p "${OUTPUT%/*}"
"$NATIVE_COMPILER" \
    -O2 -std=c11 -Wall -Wextra -Werror \
    -o "$OUTPUT" \
    "$SCRIPT_DIR/device/nova-mount-private.c"

file "$OUTPUT"
echo "$OUTPUT"
