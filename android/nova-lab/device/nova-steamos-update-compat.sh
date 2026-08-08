#!/bin/sh

# The SteamOS Gamepad UI invokes this host update helper after the network
# selection page.  A Holo rootfs has no SteamOS host updater, so return success
# for this research-only boundary and retain an invocation record.  This does
# not claim that Steam content updates are available; network reachability is
# tested independently by the harness.

set -u

LOG=${NOVA_STEAMOS_UPDATE_LOG:-/tmp/nova-steamos-update-compat.log}
{
    echo "nova_steamos_update_compat=pass"
    echo "nova_steamos_update_args=$*"
    echo "nova_steamos_update_time=$(date +%s)"
} >>"$LOG"
exit 0
