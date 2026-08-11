#!/system/bin/sh

# Prepare the official ARM64 Steam Linux Runtime 4 tree without root. The
# runtime depot can contain PRoot pseudo-hardlinks (.l2s); the installed ARM64
# Pressure Vessel donor is copied as real files so $ORIGIN lookup remains valid.

set -eu

client_root="${1:-${NOVA_ROOTLESS_GUEST_CLIENT:-/opt/nova-steam}}"
destination="${2:-${NOVA_ROOTLESS_GUEST_RUNTIME4:-/run/nova/runtime/SteamLinuxRuntime_4-arm64}}"
vdf_template="${3:-${NOVA_ROOTLESS_COMPATIBILITYTOOLS_VDF:-/run/nova/nova-rootless-steam-arm64-compatibilitytools.vdf.in}}"

source_runtime="$client_root/steamapps/common/SteamLinuxRuntime_4-arm64"
pressure_vessel_donor="$client_root/steamapps/common/SteamLinuxRuntime_4/pressure-vessel-arm64"
compatibility_dir="$client_root/compatibilitytools.d/nova-rootless-steamclienttermux-arm64"
compatibility_manifest="$compatibility_dir/compatibilitytool.vdf"

system_cp=/system/bin/cp
system_find=/system/bin/find
system_mkdir=/system/bin/mkdir
system_mv=/system/bin/mv
system_rm=/system/bin/rm
system_sed=/system/bin/sed
system_sha256sum=/usr/bin/sha256sum
system_test=/system/bin/test

fail() {
    echo "nova_rootless_runtime4=fail reason=$1" >&2
    exit 1
}

require_file() {
    "$system_test" -f "$1" || fail "missing_file:$1"
}

require_directory() {
    "$system_test" -d "$1" || fail "missing_directory:$1"
}

reject_l2s_links() {
    root="$1"
    match="$($system_find "$root" -type l -lname '*/.l2s/*' -print -quit)"
    [ -z "$match" ] || fail "pseudo_hardlink_tree:$match"
}

write_compatibility_manifest() {
    require_file "$vdf_template"
    case "$client_root" in
        *[!A-Za-z0-9_./-]*) fail unsafe_client_root_for_vdf ;;
    esac
    if [ -L "$compatibility_dir" ] || [ -L "$compatibility_manifest" ]; then
        fail symlinked_compatibility_manifest
    fi
    "$system_mkdir" -p "$compatibility_dir"
    temp_manifest="$compatibility_manifest.new.$$"
    "$system_sed" "s|@CLIENT_ROOT@|$client_root|g" "$vdf_template" >"$temp_manifest"
    "$system_mv" -f "$temp_manifest" "$compatibility_manifest"
    chmod 600 "$compatibility_manifest"
}

require_directory "$source_runtime"
require_file "$source_runtime/_v2-entry-point"
require_file "$source_runtime/run"
require_file "$source_runtime/pressure-vessel/bin/pressure-vessel-wrap"
require_directory "$pressure_vessel_donor"
require_file "$pressure_vessel_donor/bin/pressure-vessel-wrap"
reject_l2s_links "$pressure_vessel_donor"

source_hash="$($system_sha256sum "$source_runtime/pressure-vessel/bin/pressure-vessel-wrap" | \
    /system/bin/awk '{print $1}')"
donor_hash="$($system_sha256sum "$pressure_vessel_donor/bin/pressure-vessel-wrap" | \
    /system/bin/awk '{print $1}')"
[ "$source_hash" = "$donor_hash" ] || fail "pressure_vessel_hash_mismatch:$donor_hash:$source_hash"

marker="$destination/.nova-rootless-runtime4"
if [ -e "$destination" ]; then
    if [ -f "$marker" ] && [ -x "$destination/pressure-vessel/bin/pressure-vessel-wrap" ]; then
        reject_l2s_links "$destination/pressure-vessel"
        installed_hash="$($system_sha256sum \
            "$destination/pressure-vessel/bin/pressure-vessel-wrap" | /system/bin/awk '{print $1}')"
        if [ "$installed_hash" = "$source_hash" ]; then
            write_compatibility_manifest
            echo "nova_rootless_runtime4=already-staged destination=$destination"
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
trap cleanup EXIT

"$system_cp" -a "$source_runtime/." "$stage/"
if [ -e "$stage/var" ]; then
    "$system_mv" "$stage/var" "$stage/var-installed-state"
fi
"$system_mkdir" -p "$stage/var"
"$system_mv" "$stage/pressure-vessel" "$stage/pressure-vessel-l2s-original"
"$system_cp" -a "$pressure_vessel_donor" "$stage/pressure-vessel"
reject_l2s_links "$stage/pressure-vessel"
prepared_hash="$($system_sha256sum \
    "$stage/pressure-vessel/bin/pressure-vessel-wrap" | /system/bin/awk '{print $1}')"
[ "$prepared_hash" = "$source_hash" ] || fail "prepared_pressure_vessel_hash_mismatch"

{
    echo "source_runtime=$source_runtime"
    echo "pressure_vessel_sha256=$source_hash"
} >"$stage/.nova-rootless-runtime4"
"$system_mv" "$stage" "$destination"
trap - EXIT
write_compatibility_manifest
echo "nova_rootless_runtime4=pass destination=$destination pressure_vessel_sha256=$source_hash"
