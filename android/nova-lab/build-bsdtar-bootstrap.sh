#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
SOURCE_ROOTFS=${NOVA_HOLO_ROOTFS:-$BUILD_DIR/holo-rootfs/rootfs}
OUTPUT_DIR=${NOVA_BSDTAR_BOOTSTRAP_DIR:-$BUILD_DIR/bsdtar-bootstrap}
STAGE_DIR="$BUILD_DIR/.bsdtar-bootstrap-staging.$$"
STAGE_ROOTFS="$STAGE_DIR/rootfs"

die() {
    echo "build-bsdtar-bootstrap: $*" >&2
    exit 1
}

[[ -d "$SOURCE_ROOTFS" ]] || die "missing Holo rootfs: $SOURCE_ROOTFS"
[[ -x "$SOURCE_ROOTFS/usr/bin/bsdtar" ]] ||
    die "missing Holo bsdtar: $SOURCE_ROOTFS/usr/bin/bsdtar"
[[ ! -e "$STAGE_DIR" ]] || die "stale staging directory: $STAGE_DIR"

cleanup() {
    local status=$?
    if [[ "$status" -ne 0 ]]; then
        rm -rf "$STAGE_DIR"
    fi
}
trap cleanup EXIT

[[ -x "$SOURCE_ROOTFS/usr/bin/env" ]] ||
    die "missing Holo env: $SOURCE_ROOTFS/usr/bin/env"

mkdir -p "$STAGE_ROOTFS/usr/bin" "$STAGE_ROOTFS/lib"
cp -L "$SOURCE_ROOTFS/usr/bin/bsdtar" "$STAGE_ROOTFS/usr/bin/bsdtar"
chmod 755 "$STAGE_ROOTFS/usr/bin/bsdtar"
cp -L "$SOURCE_ROOTFS/usr/bin/env" "$STAGE_ROOTFS/usr/bin/env"
chmod 755 "$STAGE_ROOTFS/usr/bin/env"

# Keep this list explicit and reviewable. These are the recursive DT_NEEDED
# closure of the pinned Holo bsdtar/libarchive pair. Copies are placed directly
# in /lib so the bootstrap has no dependency on a generated ld.so.cache or on
# the layout of the larger Holo image that it is about to extract.
bootstrap_libraries=(
    ld-linux-aarch64.so.1
    libc.so.6
    libacl.so.1
    libarchive.so.13
    libbz2.so.1.0
    libcrypto.so.3
    libgcc_s.so.1
    libicuuc.so.78
    libicudata.so.78
    liblz4.so.1
    liblzma.so.5
    libm.so.6
    libstdc++.so.6
    libxml2.so.16
    libz.so.1
    libzstd.so.1
)

find_library() {
    local name=$1
    local candidate
    for candidate in \
        "$SOURCE_ROOTFS/lib/$name" \
        "$SOURCE_ROOTFS/usr/lib/$name"; do
        if [[ -e "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    find "$SOURCE_ROOTFS/lib" "$SOURCE_ROOTFS/usr/lib" \
        -name "$name" -print -quit
}

for library in "${bootstrap_libraries[@]}"; do
    source_path=$(find_library "$library")
    [[ -n "$source_path" ]] || die "missing bootstrap library: $library"
    cp -L "$source_path" "$STAGE_ROOTFS/lib/$library"
done

manifest="$STAGE_DIR/manifest.tsv"
{
    printf 'bootstrap_version\t1\n'
    printf 'source_policy\tpinned-holo-bsdtar-recursive-dt-needed\n'
    printf 'source_rootfs_policy\tlocal-pinned-holo-build-rootfs\n'
    printf 'file\tusr/bin/bsdtar\t%s\t%s\n' \
        "$(shasum -a 256 "$STAGE_ROOTFS/usr/bin/bsdtar" | awk '{print $1}')" \
        "$(wc -c <"$STAGE_ROOTFS/usr/bin/bsdtar" | tr -d '[:space:]')"
    printf 'file\tusr/bin/env\t%s\t%s\n' \
        "$(shasum -a 256 "$STAGE_ROOTFS/usr/bin/env" | awk '{print $1}')" \
        "$(wc -c <"$STAGE_ROOTFS/usr/bin/env" | tr -d '[:space:]')"
    for library in "${bootstrap_libraries[@]}"; do
        printf 'file\tlib/%s\t%s\t%s\n' "$library" \
            "$(shasum -a 256 "$STAGE_ROOTFS/lib/$library" | awk '{print $1}')" \
            "$(wc -c <"$STAGE_ROOTFS/lib/$library" | tr -d '[:space:]')"
    done
} >"$manifest"

rm -rf "$OUTPUT_DIR"
mv "$STAGE_DIR" "$OUTPUT_DIR"
trap - EXIT

echo "bsdtar_bootstrap=$OUTPUT_DIR/rootfs"
echo "bsdtar_bootstrap_manifest=$OUTPUT_DIR/manifest.tsv"
echo "bsdtar_bootstrap_files=$((2 + ${#bootstrap_libraries[@]}))"
