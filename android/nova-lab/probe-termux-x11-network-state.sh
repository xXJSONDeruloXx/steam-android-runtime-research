#!/usr/bin/env bash

set -euo pipefail

if [ "$#" -ne 11 ]; then
    echo "usage: $0 ADB ADB_SERIAL DEVICE_ROOT RUN_ID RUN_DIR PRIVATE_HELPER NAMESPACE_MODE MOUNT_PRIVATE REMOTE_OBSERVER DURATION_SECONDS INTERVAL_SECONDS" >&2
    exit 2
fi

ADB=$1
ADB_SERIAL=$2
DEVICE_ROOT=$3
RUN_ID=$4
RUN_DIR=$5
PRIVATE_HELPER=$6
NAMESPACE_MODE=$7
MOUNT_PRIVATE=$8
REMOTE_OBSERVER=$9
DURATION_SECONDS=${10}
INTERVAL_SECONDS=${11}
REMOTE_PID=
EXIT_STATUS=0

case "$RUN_ID" in
    ''|*[!A-Za-z0-9._-]*)
        echo "invalid run id: $RUN_ID" >&2
        exit 2
        ;;
esac
case "$NAMESPACE_MODE" in
    chroot)
        ;;
    chroot-dev)
        if [ -z "$MOUNT_PRIVATE" ] || [ "$MOUNT_PRIVATE" = - ]; then
            echo "chroot-dev requires mount-private helper" >&2
            exit 2
        fi
        ;;
    *)
        echo "invalid namespace mode: $NAMESPACE_MODE" >&2
        exit 2
        ;;
esac
case "$DURATION_SECONDS:$INTERVAL_SECONDS" in
    ''|*[!0-9:]*|*:*:*)
        echo "duration and interval must be numeric" >&2
        exit 2
        ;;
esac
if [ "$DURATION_SECONDS" -lt 1 ] || [ "$INTERVAL_SECONDS" -lt 1 ]; then
    echo "duration and interval must be at least one second" >&2
    exit 2
fi
if [ ! -d "$RUN_DIR" ]; then
    echo "missing run directory: $RUN_DIR" >&2
    exit 1
fi

case "$REMOTE_OBSERVER" in
    "$DEVICE_ROOT"/*)
        CHROOT_OBSERVER="/${REMOTE_OBSERVER#"$DEVICE_ROOT/"}"
        ;;
    *)
        echo "observer must be staged below device root: $REMOTE_OBSERVER" >&2
        exit 2
        ;;
esac

ADB_ARGS=(-s "$ADB_SERIAL")
adb() {
    "$ADB" "${ADB_ARGS[@]}" "$@"
}

collect_android_snapshot() {
    label="$1"
    output="$RUN_DIR/network-android-$label.txt"
    {
        echo "network_android_sample=$label"
        echo "network_android_timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "adb_serial=$ADB_SERIAL"
        echo "device_root=$DEVICE_ROOT"
        echo
        echo "[dumpsys_connectivity]"
        adb shell dumpsys connectivity 2>&1 || true
        echo
        echo "[ip_addr]"
        adb shell ip addr 2>&1 || true
        echo
        echo "[ip_route]"
        adb shell ip route 2>&1 || true
        echo
        echo "[dns_properties]"
        adb shell getprop 2>&1 | rg -i 'dns|net\.|wifi|validated|interface' || true
        echo
        echo "[/proc/net/route]"
        adb shell cat /proc/net/route 2>&1 || true
        echo
        echo "[/proc/net/tcp]"
        adb shell cat /proc/net/tcp 2>&1 || true
        echo
        echo "[/proc/net/tcp6]"
        adb shell cat /proc/net/tcp6 2>&1 || true
        echo
        echo "[/proc/net/unix]"
        adb shell cat /proc/net/unix 2>&1 || true
        echo
        echo "[processes]"
        adb shell ps -A -o PID,PPID,USER,ARGS 2>&1 || true
        echo
        echo "[local_endpoints]"
        adb shell ls -ld \
            /dev/socket/dnsproxyd \
            /dev/socket/netd \
            /dev/socket/fwmarkd \
            /dev/socket/mdns \
            /data/misc/net 2>&1 || true
    } >"$output"
    echo "network_android_snapshot=pass label=$label path=$output"
}

cleanup() {
    status=$?
    trap - EXIT INT TERM
    if [ -n "${REMOTE_PID:-}" ] && kill -0 "$REMOTE_PID" 2>/dev/null; then
        kill "$REMOTE_PID" 2>/dev/null || true
        wait "$REMOTE_PID" 2>/dev/null || true
    fi
    adb shell su -c "/system/bin/rm -f $REMOTE_OBSERVER" >/dev/null 2>&1 || true
    if [ "$status" -eq 0 ] && [ "$EXIT_STATUS" -ne 0 ]; then
        status="$EXIT_STATUS"
    fi
    exit "$status"
}
trap cleanup EXIT INT TERM

if [ "$NAMESPACE_MODE" = chroot-dev ]; then
    REMOTE_COMMAND="$PRIVATE_HELPER chroot-dev $MOUNT_PRIVATE $DEVICE_ROOT /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp TMPDIR=/tmp $CHROOT_OBSERVER $RUN_ID $DURATION_SECONDS $INTERVAL_SECONDS"
else
    REMOTE_COMMAND="$PRIVATE_HELPER chroot $DEVICE_ROOT /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp TMPDIR=/tmp $CHROOT_OBSERVER $RUN_ID $DURATION_SECONDS $INTERVAL_SECONDS"
fi

echo "network_observer_remote_command=$REMOTE_COMMAND"
adb shell su -c "$REMOTE_COMMAND" >"$RUN_DIR/network-chroot-observer.txt" 2>&1 &
REMOTE_PID=$!

sample=0
collect_android_snapshot "$(printf '%02d' "$sample")"
while kill -0 "$REMOTE_PID" 2>/dev/null; do
    sleep "$INTERVAL_SECONDS"
    sample=$((sample + 1))
    collect_android_snapshot "$(printf '%02d' "$sample")"
done

remote_status=0
wait "$REMOTE_PID" || remote_status=$?
REMOTE_PID=
sample=$((sample + 1))
collect_android_snapshot "$(printf '%02d' "$sample")-final"

{
    echo "network_observer_run_id=$RUN_ID"
    echo "network_observer_remote_status=$remote_status"
    echo "network_observer_android_samples=$((sample + 1))"
    echo "network_observer_timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    if [ "$remote_status" -eq 0 ] && rg -q '^network_observer=pass ' "$RUN_DIR/network-chroot-observer.txt"; then
        echo "network_observer_status=pass"
    else
        echo "network_observer_status=fail"
        EXIT_STATUS=1
    fi
} >"$RUN_DIR/network-observer-status.txt"
cat "$RUN_DIR/network-observer-status.txt"
