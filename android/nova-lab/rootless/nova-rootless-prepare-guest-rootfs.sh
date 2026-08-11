#!/system/bin/sh

# Build an app-owned rootless guest candidate without su, chroot, or mount.
# The source Holo rootfs is a read-only input. PRoot installs the verified
# incremental Holo UI/audio closure into a staged copy, then extracts the
# narrowly scoped Debian GTK2 compatibility artifacts and activates the copy
# atomically. The rooted runtime is never modified.

set -eu

ACTION="${1:-}"
SOURCE_ROOTFS="${NOVA_ROOTLESS_SOURCE_ROOTFS:-}"
DEST_ROOTFS="${NOVA_ROOTLESS_GUEST_ROOTFS:-}"
PROOT_BIN="${NOVA_ROOTLESS_PROOT_BIN:-${NOVA_ROOTLESS_PROOT:-}}"
PROOT_LOADER_PATH="${NOVA_ROOTLESS_PROOT_LOADER:-}"
PROOT_LIB_DIR="${NOVA_ROOTLESS_PROOT_LIB_DIR:-}"
STATE="${NOVA_ROOTLESS_STATE:-}"
PACKAGE_DIR="${NOVA_ROOTLESS_STEAMUI_PACKAGE_DIR:-}"
HOLO_MANIFEST="${NOVA_ROOTLESS_STEAMUI_HOLO_MANIFEST:-}"
EXTERNAL_MANIFEST="${NOVA_ROOTLESS_STEAMUI_EXTERNAL_MANIFEST:-}"
STEAM_CLIENT="${NOVA_ROOTLESS_STEAM_CLIENT:-}"
MINIMUM_FREE_BYTES="${NOVA_ROOTLESS_MINIMUM_FREE_BYTES:-8589934592}"

system_id=/system/bin/id
system_df=/system/bin/df
system_awk=/system/bin/awk
system_cp=/system/bin/cp
system_find=/system/bin/find
system_mkdir=/system/bin/mkdir
system_mv=/system/bin/mv
system_rm=/system/bin/rm
system_sha256sum=/system/bin/sha256sum
system_test=/system/bin/test
system_wc=/system/bin/wc

fail() {
    echo "nova_rootless_guest_rootfs=fail reason=$1" >&2
    exit 1
}

require_file() {
    "$system_test" -f "$1" || fail "missing_file:$1"
}

require_directory() {
    "$system_test" -d "$1" || fail "missing_directory:$1"
}

require_guest_path() {
    if ! "$system_test" -e "$1" && ! "$system_test" -L "$1"; then
        fail "missing_guest_path:$1"
    fi
}

numeric() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

if [ "${1:-}" != prepare ]; then
    echo "usage: $0 prepare" >&2
    exit 2
fi
if [ "$($system_id -u)" -eq 0 ]; then
    fail root_uid_detected
fi
for value in SOURCE_ROOTFS DEST_ROOTFS PROOT_BIN PROOT_LOADER_PATH PROOT_LIB_DIR \
    STATE PACKAGE_DIR HOLO_MANIFEST EXTERNAL_MANIFEST STEAM_CLIENT; do
    eval "value_text=\${$value:-}"
    [ -n "$value_text" ] || fail "missing_$value"
done
if [ "$SOURCE_ROOTFS" = "$DEST_ROOTFS" ]; then
    fail source_and_destination_identical
fi
require_directory "$SOURCE_ROOTFS"
require_directory "$PACKAGE_DIR"
require_file "$HOLO_MANIFEST"
require_file "$EXTERNAL_MANIFEST"
require_directory "$STEAM_CLIENT"
require_file "$PROOT_LOADER_PATH"
require_directory "$PROOT_LIB_DIR"
require_file "$PROOT_BIN"
require_directory "$STATE"
numeric "$MINIMUM_FREE_BYTES" || fail invalid_minimum_free_bytes

destination_parent=${DEST_ROOTFS%/*}
[ "$destination_parent" != "$DEST_ROOTFS" ] || destination_parent=/
require_directory "$destination_parent"

available_kib="$($system_df -Pk "$destination_parent" | "$system_awk" 'NR > 1 { print $4; exit }')"
numeric "$available_kib" || fail invalid_free_space
minimum_free_kib=$((MINIMUM_FREE_BYTES / 1024))
[ "$available_kib" -ge "$minimum_free_kib" ] ||
    fail "insufficient_free_space:${available_kib}KiB<${minimum_free_kib}KiB"

sha256_of() {
    "$system_sha256sum" "$1" | "$system_awk" '{ print $1 }'
}

verify_holo_manifest() {
    count=0
    while IFS="$(printf '\t')" read -r repo package_name package_version package_sha256 package_file; do
        case "${repo:-}" in
            ''|\#*) continue ;;
        esac
        package_path="$PACKAGE_DIR/$package_file"
        require_file "$package_path"
        [ "$(sha256_of "$package_path")" = "$package_sha256" ] ||
            fail "holo_package_sha256:$package_file"
        count=$((count + 1))
    done <"$HOLO_MANIFEST"
    [ "$count" -gt 0 ] || fail empty_holo_manifest
    actual_count="$($system_find "$PACKAGE_DIR" -maxdepth 1 -type f \
        -name '*.pkg.tar.zst' | "$system_wc" -l | "$system_awk" '{ print $1 }')"
    [ "$actual_count" = "$count" ] || fail "holo_package_count:$actual_count:$count"
}

verify_external_manifest() {
    count=0
    while IFS="$(printf '\t')" read -r source_name package_file package_size package_sha256 package_url; do
        case "${source_name:-}" in
            ''|\#*) continue ;;
        esac
        package_path="$PACKAGE_DIR/$package_file"
        require_file "$package_path"
        actual_size="$($system_wc -c <"$package_path" | /system/bin/tr -d '[:space:]')"
        [ "$actual_size" = "$package_size" ] || fail "external_package_size:$package_file"
        [ "$(sha256_of "$package_path")" = "$package_sha256" ] ||
            fail "external_package_sha256:$package_file"
        count=$((count + 1))
    done <"$EXTERNAL_MANIFEST"
    [ "$count" -eq 2 ] || fail "external_package_count:$count"
}

verify_holo_manifest
verify_external_manifest

marker="$DEST_ROOTFS/.nova-rootless-guest-rootfs"
if [ -e "$DEST_ROOTFS" ]; then
    if [ -f "$marker" ] && [ -e "$DEST_ROOTFS/usr/lib/libgtk-x11-2.0.so.0" ] &&
        [ -e "$DEST_ROOTFS/usr/lib/libgdk-x11-2.0.so.0" ]; then
        echo "nova_rootless_guest_rootfs=already-staged rootfs=$DEST_ROOTFS"
        exit 0
    fi
    fail "refusing_existing_destination:$DEST_ROOTFS"
fi

destination_parent=${DEST_ROOTFS%/*}
stage="$destination_parent/.$(basename "$DEST_ROOTFS").staging.$$"
[ ! -e "$stage" ] || fail "stale_stage:$stage"
stage_cleanup=1
cleanup() {
    status=$?
    if [ "$status" -ne 0 ] && [ "$stage_cleanup" -eq 1 ] && [ -e "$stage" ]; then
        "$system_rm" -rf "$stage"
    fi
}
trap cleanup EXIT INT TERM

"$system_mkdir" -p "$stage" "$STATE/proot-tmp"
echo "nova_rootless_guest_rootfs=copy source=$SOURCE_ROOTFS stage=$stage"
"$system_cp" -R "$SOURCE_ROOTFS/." "$stage/"

export LD_LIBRARY_PATH="$PROOT_LIB_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export PROOT_LOADER="$PROOT_LOADER_PATH"
export PROOT_TMP_DIR="$STATE/proot-tmp"

guest_install='set -eu
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
for archive in /tmp/nova-rootless-steamui-pkgs/*.pkg.tar.zst; do
    [ -f "$archive" ] || exit 41
done
/usr/bin/pacman --noconfirm --needed -U /tmp/nova-rootless-steamui-pkgs/*.pkg.tar.zst
for deb in /tmp/nova-rootless-steamui-pkgs/*.deb; do
    [ -f "$deb" ] || continue
    data_archive=/tmp/nova-rootless-steamui-pkgs/data.tar.xz
    /usr/bin/ar p "$deb" data.tar.xz >"$data_archive"
    /usr/bin/bsdtar -x -f "$data_archive" -C /
    /usr/bin/rm -f "$data_archive"
done
/usr/bin/mkdir -p /usr/lib/aarch64-linux-gnu
for library in libgtk-x11-2.0.so.0 libgdk-x11-2.0.so.0; do
    [ -e "/usr/lib/aarch64-linux-gnu/$library" ] || exit 42
    if [ -L "/usr/lib/$library" ]; then
        [ "$(/usr/bin/readlink "/usr/lib/$library")" = "/usr/lib/aarch64-linux-gnu/$library" ] || exit 43
    elif [ -e "/usr/lib/$library" ]; then
        exit 44
    else
        /usr/bin/ln -s "/usr/lib/aarch64-linux-gnu/$library" "/usr/lib/$library"
    fi
done
/usr/bin/mkdir -p /etc/ld.so.conf.d
/usr/bin/printf "%s\n" /usr/lib/aarch64-linux-gnu >/etc/ld.so.conf.d/nova-debian-arm64.conf
if [ -x /usr/bin/ldconfig ]; then
    /usr/bin/ldconfig
fi
for library in libgtk-x11-2.0.so.0 libgdk-x11-2.0.so.0 libgdk_pixbuf-2.0.so.0 libatk-1.0.so.0 libpipewire-0.3.so.0 libpulse.so.0; do
    [ -e "/usr/lib/$library" ] || exit 45
done
if [ -e /opt/nova-steam/steamrtarm64/steamui.so ]; then
    if /usr/bin/ldd /opt/nova-steam/steamrtarm64/steamui.so | /usr/bin/grep -F "not found" >/dev/null; then
        exit 46
    fi
fi
/usr/bin/printf "%s\n" gtk2_and_ui_audio_closure=pass >/.nova-rootless-guest-rootfs-check
'

"$PROOT_BIN" --kill-on-exit --sysvipc -0 -r "$stage" \
    -b /dev:/dev -b /proc:/proc \
    -b "$PACKAGE_DIR:/tmp/nova-rootless-steamui-pkgs" \
    -b "$STEAM_CLIENT:/opt/nova-steam" \
    -w / /usr/bin/sh -c "$guest_install" || fail guest_install

require_file "$stage/.nova-rootless-guest-rootfs-check"
require_guest_path "$stage/usr/lib/libgtk-x11-2.0.so.0"
require_guest_path "$stage/usr/lib/libgdk-x11-2.0.so.0"
require_guest_path "$stage/usr/lib/libgdk_pixbuf-2.0.so.0"
require_guest_path "$stage/usr/lib/libatk-1.0.so.0"
require_guest_path "$stage/usr/lib/libpipewire-0.3.so.0"
require_guest_path "$stage/usr/lib/libpulse.so.0"
{
    echo "source_rootfs=$SOURCE_ROOTFS"
    echo "holo_manifest=$HOLO_MANIFEST"
    echo "external_manifest=$EXTERNAL_MANIFEST"
    echo "gtk2_source=debian-bookworm"
    echo "rooted_runtime_modified=0"
    echo "steamui_patch=0"
} >"$stage/.nova-rootless-guest-rootfs"
"$system_mv" "$stage" "$DEST_ROOTFS"
stage_cleanup=0
echo "nova_rootless_guest_rootfs=pass rootfs=$DEST_ROOTFS"
