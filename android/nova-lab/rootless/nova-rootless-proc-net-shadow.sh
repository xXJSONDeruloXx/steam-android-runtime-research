#!/system/bin/sh

# Copy only the route files visible to the Nova app UID into a private,
# validated directory. PRoot can bind this directory over /proc/net without
# requiring root, while the Android-owned network namespace remains unchanged.

set -eu

destination="${1:-${NOVA_ROOTLESS_PROC_NET:-}}"
source_route=/proc/net/route
source_ipv6_route=/proc/net/ipv6_route

system_id=/system/bin/id
system_awk=/system/bin/awk
system_cat=/system/bin/cat
system_find=/system/bin/find
system_mkdir=/system/bin/mkdir
system_mv=/system/bin/mv
system_rm=/system/bin/rm
system_test=/system/bin/test

fail() {
    echo "nova_rootless_proc_net=fail reason=$1" >&2
    exit 1
}

[ -n "$destination" ] || fail missing_destination
[ "$($system_id -u)" -ne 0 ] || fail root_detected
[ -r "$source_route" ] || fail route_unreadable

if [ -L "$destination" ]; then
    fail symlinked_destination
fi
$system_mkdir -p "$destination"
$system_test -d "$destination" || fail destination_not_directory

unexpected="$($system_find "$destination" -mindepth 1 -maxdepth 1 \
    ! -name route ! -name ipv6_route -print -quit)"
[ -z "$unexpected" ] || fail "unexpected_destination_entry:$unexpected"
for existing in "$destination/route" "$destination/ipv6_route"; do
    [ ! -L "$existing" ] || fail "symlinked_destination_entry:$existing"
    if [ -e "$existing" ] && [ ! -f "$existing" ]; then
        fail "nonregular_destination_entry:$existing"
    fi
done

route_tmp="$destination/.route.$$"
ipv6_tmp="$destination/.ipv6_route.$$"
cleanup() {
    $system_rm -f "$route_tmp" "$ipv6_tmp"
}
trap cleanup EXIT

$system_cat "$source_route" >"$route_tmp" || fail route_snapshot_failed
# Some Android app UIDs can see the connected route but not the default route.
# Preserve that evidence for Wine instead of fabricating a gateway. A usable
# route entry is still required; the status line records default-route absence.
$system_awk 'NR > 1 && $1 != "" { found = 1 } END { exit(found ? 0 : 1) }' \
    "$route_tmp" || fail route_snapshot_empty
default_route=absent
if $system_awk 'NR > 1 && $2 == "00000000" { found = 1 } END { exit(found ? 0 : 1) }' \
        "$route_tmp"; then
    default_route=present
fi

if [ -r "$source_ipv6_route" ]; then
    $system_cat "$source_ipv6_route" >"$ipv6_tmp" || fail ipv6_route_snapshot_failed
else
    : >"$ipv6_tmp"
fi
chmod 600 "$route_tmp" "$ipv6_tmp"
$system_mv -f "$route_tmp" "$destination/route"
$system_mv -f "$ipv6_tmp" "$destination/ipv6_route"
trap - EXIT

echo "nova_rootless_proc_net=pass destination=$destination default_route=$default_route"
