#!/bin/sh

# Steam's legacy SteamOS update boundary is still used by the Gamepad UI
# OOBE. Holo's ARM64 rootfs has no A/B OS image or atomupd-manager, so Nova
# cannot truthfully apply a SteamOS host update. Implement the small legacy
# command contract instead of returning success for every invocation:
#
#   --supports-duplicate-detection       success (capability probe)
#   [--enable-duplicate-detection] check 7 (no update available)
#   [--enable-duplicate-detection]       7 (no update available)
#
# Valve's helper uses status 7 for the normal, already-up-to-date case. A
# status-0 result means that an update was actually applied and allows Steam
# to request a restart. Returning 0 here would therefore be a false update
# result and can strand OOBE on the restart/error surface.

set -u

LOG=${NOVA_STEAMOS_UPDATE_LOG:-/tmp/nova-steamos-update-compat.log}
INVOCATION_ARGS=$*

record() {
    status=$1
    operation=$2
    message=$3
    now=$(date +%s 2>/dev/null) || now=0
    {
        printf '%s\n' "nova_steamos_update_compat=pass"
        printf '%s\n' "nova_steamos_update_operation=$operation"
        printf '%s\n' "nova_steamos_update_status=$status"
        printf '%s\n' "nova_steamos_update_args=$INVOCATION_ARGS"
        printf '%s\n' "nova_steamos_update_message=$message"
        printf '%s\n' "nova_steamos_update_time=$now"
    } >>"$LOG" 2>/dev/null || :
}

fail_usage() {
    option=${1-}
    message="Unknown option \"$option\""
    printf '%s\n' "$message" >&2
    record 1 usage "$message"
    exit 1
}

# The probe is a distinct command in the Valve helper and must not be
# interpreted as an update check.
if [ "$#" -eq 1 ] && [ "$1" = '--supports-duplicate-detection' ]; then
    message='This script supports the duplicate detection option'
    printf '%s\n' "$message" >&2
    record 0 capability "$message"
    exit 0
fi

check_mode=0
for argument in "$@"; do
    case "$argument" in
        check)
            check_mode=1
            ;;
        --enable-duplicate-detection|--beta|-d)
            ;;
        *)
            fail_usage "$argument"
            ;;
    esac
done

if [ "$check_mode" -eq 1 ]; then
    operation=check
else
    operation=apply
fi
message='No update available'
printf '%s\n' "$message" >&2
record 7 "$operation" "$message"
exit 7
