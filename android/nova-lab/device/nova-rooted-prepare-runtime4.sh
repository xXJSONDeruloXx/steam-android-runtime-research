#!/system/bin/sh

# Prepare a root-owned, guest-visible Runtime 4 shadow for the rooted Holo
# path. This copies only the installed ARM64 runtime; it does not download or
# modify Valve payloads. The separate conventional SteamLinuxRuntime_4 depot
# supplies real Pressure Vessel files when the installed ARM depot contains
# PRoot-style .l2s links.

set -eu

root="${1:-/data/local/tmp/nova-holo-rootfs}"
client_root="${2:-$root/opt/nova-steam/home/.local/share/Steam}"
destination="${3:-$root/opt/nova-steam/runtime/SteamLinuxRuntime_4-arm64}"

system_cp=/system/bin/cp
system_find=/system/bin/find
system_mkdir=/system/bin/mkdir
system_mv=/system/bin/mv
system_rm=/system/bin/rm
system_sha256sum=/usr/bin/sha256sum
system_test=/system/bin/test

fail() {
    echo "nova_rooted_runtime4=fail reason=$1" >&2
    exit 1
}

require_file() {
    "$system_test" -f "$1" || fail "missing_file:$1"
}

require_directory() {
    "$system_test" -d "$1" || fail "missing_directory:$1"
}

reject_l2s_links() {
    root_path="$1"
    match="$($system_find "$root_path" -type l -lname '*/.l2s/*' -print -quit)"
    [ -z "$match" ] || fail "pseudo_hardlink_tree:$match"
}

require_directory "$root"
source_runtime="$client_root/steamapps/common/SteamLinuxRuntime_4-arm64"
pressure_vessel_donor="$client_root/steamapps/common/SteamLinuxRuntime_4/pressure-vessel-arm64"
require_directory "$source_runtime"
require_file "$source_runtime/_v2-entry-point"
require_file "$source_runtime/run"
require_file "$source_runtime/pressure-vessel/bin/pressure-vessel-wrap"
require_directory "$pressure_vessel_donor"
require_file "$pressure_vessel_donor/bin/pressure-vessel-wrap"
reject_l2s_links "$pressure_vessel_donor"

source_hash="$($system_sha256sum "$source_runtime/pressure-vessel/bin/pressure-vessel-wrap" |
    /system/bin/awk '{print $1}')"
donor_hash="$($system_sha256sum "$pressure_vessel_donor/bin/pressure-vessel-wrap" |
    /system/bin/awk '{print $1}')"
[ "$source_hash" = "$donor_hash" ] ||
    fail "pressure_vessel_hash_mismatch:$donor_hash:$source_hash"

marker="$destination/.nova-rooted-runtime4"
if [ -e "$destination" ]; then
    if [ -f "$marker" ] && [ -x "$destination/_v2-entry-point" ] &&
        [ -x "$destination/pressure-vessel/bin/pressure-vessel-wrap" ]; then
        reject_l2s_links "$destination/pressure-vessel"
        installed_hash="$($system_sha256sum \
            "$destination/pressure-vessel/bin/pressure-vessel-wrap" |
            /system/bin/awk '{print $1}')"
        if [ "$installed_hash" = "$source_hash" ]; then
            echo "nova_rooted_runtime4=already-staged destination=$destination pressure_vessel_sha256=$source_hash"
            exit 0
        fi
    fi
    fail "refusing_existing_destination:$destination"
fi

parent="${destination%/*}"
[ "$parent" != "$destination" ] || parent=/
stage="$parent/.SteamLinuxRuntime_4-arm64.prepare.$$"
[ ! -e "$stage" ] || fail "stale_stage:$stage"
"$system_mkdir" -p "$parent"
"$system_mkdir" "$stage"
cleanup() {
    [ ! -e "$stage" ] || "$system_rm" -rf "$stage"
}
trap cleanup EXIT INT TERM

"$system_cp" -a "$source_runtime/." "$stage/"
if [ -e "$stage/var" ]; then
    "$system_mv" "$stage/var" "$stage/var-installed-state"
fi
"$system_mkdir" -p "$stage/var"
"$system_mv" "$stage/pressure-vessel" "$stage/pressure-vessel-l2s-original"
"$system_cp" -a "$pressure_vessel_donor" "$stage/pressure-vessel"
reject_l2s_links "$stage/pressure-vessel"

prepared_hash="$($system_sha256sum \
    "$stage/pressure-vessel/bin/pressure-vessel-wrap" |
    /system/bin/awk '{print $1}')"
[ "$prepared_hash" = "$source_hash" ] || fail prepared_pressure_vessel_hash_mismatch

{
    echo "source_runtime=$source_runtime"
    echo "pressure_vessel_sha256=$source_hash"
    echo "auth_secrets_exported=0"
} >"$stage/.nova-rooted-runtime4"
"$system_mv" "$stage" "$destination"
trap - EXIT INT TERM
echo "nova_rooted_runtime4=pass destination=$destination pressure_vessel_sha256=$source_hash"
