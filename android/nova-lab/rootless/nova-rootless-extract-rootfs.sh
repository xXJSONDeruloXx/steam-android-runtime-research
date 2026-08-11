#!/system/bin/sh

# Extract a verified Holo system.rootfs archive into an app-owned candidate.
# This is the genuinely rootless source path: the app never reads a root-owned
# extracted image and never uses su, chroot, or mount.

set -eu

ACTION="${1:-}"
ROOTFS_ARCHIVE="${NOVA_ROOTLESS_ROOTFS_ARCHIVE:-}"
DEST_ROOTFS="${NOVA_ROOTLESS_GUEST_ROOTFS:-}"
ZSTD="${NOVA_ROOTLESS_ZSTD:-}"
STATE="${NOVA_ROOTLESS_STATE:-}"
BOOTSTRAP_ROOTFS="${NOVA_ROOTLESS_BOOTSTRAP_ROOTFS:-}"
PROOT_BIN="${NOVA_ROOTLESS_PROOT_BIN:-${NOVA_ROOTLESS_PROOT:-}}"
PROOT_LOADER_PATH="${NOVA_ROOTLESS_PROOT_LOADER:-}"
PROOT_LIB_DIR="${NOVA_ROOTLESS_PROOT_LIB_DIR:-}"
EXPECTED_SIZE="${NOVA_ROOTLESS_ROOTFS_ARCHIVE_SIZE:-}"
EXPECTED_SHA256="${NOVA_ROOTLESS_ROOTFS_ARCHIVE_SHA256:-}"
MINIMUM_FREE_BYTES="${NOVA_ROOTLESS_MINIMUM_FREE_BYTES:-8589934592}"

system_id=/system/bin/id
system_df=/system/bin/df
system_awk=/system/bin/awk
system_grep=/system/bin/grep
system_sed=/system/bin/sed
system_mkdir=/system/bin/mkdir
system_mv=/system/bin/mv
system_rm=/system/bin/rm
system_chmod=/system/bin/chmod
system_sha256sum=/system/bin/sha256sum
system_tar=/system/bin/tar
system_test=/system/bin/test
system_wc=/system/bin/wc

fail() {
    echo "nova_rootless_rootfs_archive=fail reason=$1" >&2
    exit 1
}

require_file() {
    "$system_test" -f "$1" || fail "missing_file:$1"
}

require_directory() {
    "$system_test" -d "$1" || fail "missing_directory:$1"
}

numeric() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

if [ "$ACTION" != prepare ]; then
    echo "usage: $0 prepare" >&2
    exit 2
fi
if [ "$($system_id -u)" -eq 0 ]; then
    fail root_uid_detected
fi
for value in ROOTFS_ARCHIVE DEST_ROOTFS ZSTD STATE EXPECTED_SIZE EXPECTED_SHA256; do
    eval "value_text=\${$value:-}"
    [ -n "$value_text" ] || fail "missing_$value"
done
require_file "$ROOTFS_ARCHIVE"
require_file "$ZSTD"
require_directory "$STATE"
if [ -n "$BOOTSTRAP_ROOTFS" ]; then
    require_directory "$BOOTSTRAP_ROOTFS"
    require_file "$PROOT_BIN"
    require_file "$PROOT_LOADER_PATH"
    require_directory "$PROOT_LIB_DIR"
fi
numeric "$EXPECTED_SIZE" || fail invalid_expected_size
numeric "$MINIMUM_FREE_BYTES" || fail invalid_minimum_free_bytes

destination_parent=${DEST_ROOTFS%/*}
[ "$destination_parent" != "$DEST_ROOTFS" ] || destination_parent=.
require_directory "$destination_parent"

available_kib="$($system_df -Pk "$destination_parent" | "$system_awk" 'NR > 1 { print $4; exit }')"
numeric "$available_kib" || fail invalid_free_space
minimum_free_kib=$((MINIMUM_FREE_BYTES / 1024))
[ "$available_kib" -ge "$minimum_free_kib" ] ||
    fail "insufficient_free_space:${available_kib}KiB<${minimum_free_kib}KiB"

archive_size="$($system_wc -c <"$ROOTFS_ARCHIVE" | /system/bin/tr -d '[:space:]')"
[ "$archive_size" = "$EXPECTED_SIZE" ] ||
    fail "archive_size:$archive_size:$EXPECTED_SIZE"
archive_sha256="$($system_sha256sum "$ROOTFS_ARCHIVE" | "$system_awk" '{ print $1 }')"
[ "$archive_sha256" = "$EXPECTED_SHA256" ] ||
    fail "archive_sha256:$archive_sha256:$EXPECTED_SHA256"

marker="$DEST_ROOTFS/.nova-rootless-rootfs-archive"
if [ -e "$DEST_ROOTFS" ]; then
    if [ -f "$marker" ] &&
        /system/bin/grep -Fqx "archive_sha256=$EXPECTED_SHA256" "$marker" &&
        [ -e "$DEST_ROOTFS/usr/bin/sh" ] &&
        [ -e "$DEST_ROOTFS/usr/lib/ld-linux-aarch64.so.1" ]; then
        echo "nova_rootless_rootfs_archive=already-staged rootfs=$DEST_ROOTFS"
        exit 0
    fi
    fail "refusing_existing_destination:$DEST_ROOTFS"
fi

stage="$destination_parent/.$(basename "$DEST_ROOTFS").archive-staging.$$"
[ ! -e "$stage" ] || fail "stale_stage:$stage"
archive_tmp="$STATE/rootfs.tar.part.$$"
[ ! -e "$archive_tmp" ] || fail "stale_archive_tmp:$archive_tmp"
archive_entries="$STATE/rootfs.entries.$$"
file_entries="$STATE/rootfs.files.$$"
[ ! -e "$archive_entries" ] || fail "stale_archive_entries:$archive_entries"
[ ! -e "$file_entries" ] || fail "stale_file_entries:$file_entries"
stage_cleanup=1
cleanup() {
    status=$?
    if [ "$status" -ne 0 ] && [ "$stage_cleanup" -eq 1 ] && [ -e "$stage" ]; then
        "$system_rm" -rf "$stage"
    fi
    if [ -e "$archive_tmp" ]; then
        "$system_rm" -f "$archive_tmp"
    fi
    "$system_rm" -f "$archive_entries" "$file_entries"
}
trap cleanup EXIT INT TERM

"$system_mkdir" -p "$stage"
echo "nova_rootless_rootfs_archive=extract archive=$ROOTFS_ARCHIVE stage=$stage"
if [ -n "$BOOTSTRAP_ROOTFS" ]; then
    "$system_mkdir" -p "$STATE/proot-tmp"
    export LD_LIBRARY_PATH="$PROOT_LIB_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export PROOT_LOADER="$PROOT_LOADER_PATH"
    export PROOT_TMP_DIR="$STATE/proot-tmp"
    if ! "$PROOT_BIN" --kill-on-exit --sysvipc -0 -r "$BOOTSTRAP_ROOTFS" \
        -b /dev:/dev -b /proc:/proc \
        -b "$ROOTFS_ARCHIVE:/tmp/nova-rootfs-system.rootfs.zst" \
        -b "$stage:/tmp/nova-rootfs-stage" \
        -w / /usr/bin/bsdtar --no-same-owner --no-same-permissions --zstd \
        -xf /tmp/nova-rootfs-system.rootfs.zst -C /tmp/nova-rootfs-stage; then
        fail proot_bsdtar_extract
    fi
else
    if ! "$ZSTD" -q -d -c "$ROOTFS_ARCHIVE" >"$archive_tmp"; then
        fail archive_decompress
    fi
    if ! "$system_tar" -t -f "$archive_tmp" >"$archive_entries"; then
        fail archive_list
    fi
    # This pinned Holo image has no newline-containing filenames. Normalize
    # toybox's display-only " -> target" suffix before excluding directory
    # entries. Required empty directories are created below.
    if ! "$system_sed" 's/ -> .*//' "$archive_entries" |
        "$system_grep" -v '/$' >"$file_entries"; then
        fail archive_file_list
    fi
    if ! "$system_tar" -x -f "$archive_tmp" -C "$stage" -T "$file_entries"; then
        fail archive_extract
    fi
fi
if ! "$system_chmod" -R u+rwX "$stage"; then
    fail rootfs_owner_access
fi
"$system_rm" -f "$archive_tmp"

for directory in \
    "$stage/tmp" \
    "$stage/run" \
    "$stage/var/tmp" \
    "$stage/home" \
    "$stage/root" \
    "$stage/dev" \
    "$stage/proc" \
    "$stage/sys" \
    "$stage/var/lib/pacman/local"; do
    "$system_mkdir" -p "$directory"
done

for required_path in \
    "$stage/usr/bin/sh" \
    "$stage/usr/bin/pacman" \
    "$stage/usr/lib/ld-linux-aarch64.so.1" \
    "$stage/usr/lib/libc.so.6" \
    "$stage/var/lib/pacman/local"; do
    [ -e "$required_path" ] || fail "rootfs_missing:$(basename "$required_path")"
done
{
    echo "archive=$ROOTFS_ARCHIVE"
    echo "archive_size=$EXPECTED_SIZE"
    echo "archive_sha256=$EXPECTED_SHA256"
    echo "rooted_runtime_modified=0"
    echo "rootless_archive_extract=1"
} >"$stage/.nova-rootless-rootfs-archive"
"$system_mv" "$stage" "$DEST_ROOTFS"
stage_cleanup=0
echo "nova_rootless_rootfs_archive=pass rootfs=$DEST_ROOTFS"
