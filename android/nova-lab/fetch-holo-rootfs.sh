#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
OUTPUT_DIR="${HOLO_OUTPUT_DIR:-$BUILD_DIR/holo-rootfs}"
BASE_URL="${HOLO_BASE_URL:-https://holo-packages.steamos.cloud/holo-core-aarch64-preview/mash-20251118.3}"
EXPECTED_SHA256="${HOLO_ROOTFS_SHA256:-7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf}"
ARCHIVE="$OUTPUT_DIR/system.rootfs.zst"
ROOTFS="$OUTPUT_DIR/rootfs"

mkdir -p "$OUTPUT_DIR"

if [ ! -f "$ARCHIVE" ]; then
    temporary="$ARCHIVE.part"
    curl --fail --location --retry 3 --output "$temporary" "$BASE_URL/system.rootfs.zst"
    mv "$temporary" "$ARCHIVE"
fi

if command -v sha256sum >/dev/null 2>&1; then
    actual_sha256=$(sha256sum "$ARCHIVE" | awk '{print $1}')
else
    actual_sha256=$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')
fi

if [ "$actual_sha256" != "$EXPECTED_SHA256" ]; then
    echo "rootfs SHA-256 mismatch: $actual_sha256 != $EXPECTED_SHA256" >&2
    echo "Set HOLO_ROOTFS_SHA256 deliberately when selecting a different snapshot." >&2
    exit 1
fi

if [ -e "$ROOTFS/usr/lib/ld-linux-aarch64.so.1" ]; then
    echo "rootfs already extracted: $ROOTFS"
    echo "archive_sha256=$actual_sha256"
    exit 0
fi

if [ -n "$(find "$ROOTFS" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    echo "refusing to extract into a non-empty incomplete rootfs: $ROOTFS" >&2
    echo "choose a fresh HOLO_OUTPUT_DIR or remove that disposable build directory." >&2
    exit 1
fi

mkdir -p "$ROOTFS"
bsdtar --zstd -xpf "$ARCHIVE" -C "$ROOTFS" || true

for required_path in \
    "$ROOTFS/usr/bin/sh" \
    "$ROOTFS/usr/bin/env" \
    "$ROOTFS/usr/lib/ld-linux-aarch64.so.1" \
    "$ROOTFS/usr/lib/libc.so.6"; do
    if [ ! -e "$required_path" ]; then
        echo "rootfs extraction is missing required path: $required_path" >&2
        exit 1
    fi
done

echo "rootfs=$ROOTFS"
echo "archive_sha256=$actual_sha256"
