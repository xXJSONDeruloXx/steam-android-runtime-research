#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ROOTFS_HOST="$BUILD_DIR/holo-rootfs/rootfs"

if [ ! -f "$ROOTFS_HOST/usr/include/semaphore.h" ] || [ ! -f "$ROOTFS_HOST/usr/lib/Scrt1.o" ]; then
    echo "missing glibc rootfs sysroot: $ROOTFS_HOST" >&2
    echo "run fetch-holo-rootfs.sh first" >&2
    exit 1
fi

docker run --rm --platform linux/arm64 --name nova-sysv-sem-shim-build \
    -v "$REPO_DIR:/src:ro" \
    -v "$ROOTFS_HOST:/sysroot:ro" \
    -v "$BUILD_DIR:/out" \
    debian:trixie-slim bash -lc '
        set -eux
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq
        apt-get install -y -qq --no-install-recommends gcc file
        gcc --sysroot=/sysroot -I/usr/include -L/usr/lib \
            -O2 -std=c11 -Wall -Wextra -Werror -fPIC -shared \
            /src/android/nova-lab/device/sysv-sem-shim.c \
            -pthread -lrt \
            -Wl,--version-script=/src/android/nova-lab/device/posix-sync-trace.map \
            -o /out/libsysv-sem-shim.so
        file /out/libsysv-sem-shim.so
    '

echo "$BUILD_DIR/libsysv-sem-shim.so"
