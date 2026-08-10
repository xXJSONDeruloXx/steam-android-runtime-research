#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
SDK_ROOT=${ANDROID_SDK_ROOT:-/opt/homebrew/share/android-commandlinetools}
NDK_ROOT=${ANDROID_NDK_ROOT:-$SDK_ROOT/ndk/27.3.13750724}
TOOLCHAIN="$NDK_ROOT/toolchains/llvm/prebuilt/darwin-x86_64"
COMPILER="$TOOLCHAIN/bin/aarch64-linux-android29-clang"

if [ ! -x "$COMPILER" ]; then
    echo "missing Android ARM64 compiler: $COMPILER" >&2
    exit 1
fi

mkdir -p "$BUILD_DIR"
"$COMPILER" -O2 -std=c11 -Wall -Wextra -Werror \
    -o "$BUILD_DIR/nova-zip-rebase" \
    "$SCRIPT_DIR/src/main/cpp/nova_zip_rebase.c"

echo "$BUILD_DIR/nova-zip-rebase"
