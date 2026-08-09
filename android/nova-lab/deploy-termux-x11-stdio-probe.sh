#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
ADB_SERIAL=${ADB_SERIAL:-675a2365}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
PROBE="$SCRIPT_DIR/device/nova-termux-x11-stdio-probe.sh"
RUNTIME_CLEANUP="$SCRIPT_DIR/device/nova-runtime-cleanup.sh"
RUN_ID=${NOVA_RUN_ID:-termux-x11-$(date -u +%Y%m%dT%H%M%SZ)-stdio-probe-0}
RUN_DIR=${NOVA_RUN_DIR:-$BUILD_DIR/manual-runs/$RUN_ID}
REMOTE_PROBE=/data/local/tmp/nova-termux-x11-stdio-probe-$RUN_ID.sh
REMOTE_CLEANUP=/data/local/tmp/nova-runtime-cleanup-$RUN_ID.sh
REMOTE_CASE_DIR=$DEVICE_ROOT/tmp/nova-x11-stdio-$RUN_ID
RUN_STARTED=0

case "$RUN_ID" in
    ''|*[!A-Za-z0-9._-]*)
        echo "invalid NOVA_RUN_ID: $RUN_ID" >&2
        exit 2
        ;;
esac

if [ ! -x "$PROBE" ] || [ ! -x "$RUNTIME_CLEANUP" ]; then
    echo "missing executable probe or cleanup helper" >&2
    exit 1
fi
if ! command -v sha256sum >/dev/null 2>&1; then
    echo "missing host tool: sha256sum" >&2
    exit 1
fi

mkdir -p "$RUN_DIR"
for artifact in \
    run-metadata.txt nova-termux-x11-stdio-probe.sha256 \
    nova-runtime-cleanup.sha256 pre-cleanup.txt probe-output.txt \
    post-cleanup.txt; do
    if [ -e "$RUN_DIR/$artifact" ]; then
        echo "run artifact already exists; choose a fresh NOVA_RUN_ID: $RUN_DIR/$artifact" >&2
        exit 2
    fi
done

ADB_ARGS=(-s "$ADB_SERIAL")
adb() {
    "$ADB" "${ADB_ARGS[@]}" "$@"
}

run_cleanup() {
    local output status=0
    output=$(adb shell su -c "/system/bin/sh $REMOTE_CLEANUP $DEVICE_ROOT" 2>&1) || status=$?
    output=$(printf '%s\n' "$output" | tr -d '\r')
    printf '%s\n' "$output"
    if [ "$status" -ne 0 ] || ! printf '%s\n' "$output" | rg -q '^nova_runtime_cleanup=pass '; then
        return 1
    fi
}

on_exit() {
    local status=$?
    trap - EXIT INT TERM
    if [ "$RUN_STARTED" -eq 1 ]; then
        adb pull "$REMOTE_CASE_DIR" "$RUN_DIR/cases" >/dev/null 2>&1 || status=1
        adb shell su -c "/system/bin/rm -r $REMOTE_CASE_DIR" >/dev/null 2>&1 || status=1
        run_cleanup >"$RUN_DIR/post-cleanup.txt" || status=1
        adb shell su -c "/system/bin/rm -f $REMOTE_PROBE $REMOTE_CLEANUP" >/dev/null 2>&1 || status=1
    fi
    exit "$status"
}
trap on_exit EXIT INT TERM

adb push "$PROBE" "$REMOTE_PROBE" >/dev/null
adb push "$RUNTIME_CLEANUP" "$REMOTE_CLEANUP" >/dev/null
adb shell "chmod 755 $REMOTE_PROBE $REMOTE_CLEANUP"

run_cleanup >"$RUN_DIR/pre-cleanup.txt"
adb shell su -c "/system/bin/rm -r $REMOTE_CASE_DIR" >/dev/null 2>&1 || true

{
    echo "run_id=$RUN_ID"
    echo "repo_commit=$(git -C "$SCRIPT_DIR/../.." rev-parse HEAD)"
    echo "adb_serial=$ADB_SERIAL"
    echo "device_root=$DEVICE_ROOT"
    echo "probe=$PROBE"
    echo "probe_sha256=$(sha256sum "$PROBE" | awk '{print $1}')"
    echo "runtime_cleanup=$RUNTIME_CLEANUP"
    echo "runtime_cleanup_sha256=$(sha256sum "$RUNTIME_CLEANUP" | awk '{print $1}')"
    echo "remote_probe=$REMOTE_PROBE"
    echo "remote_cleanup=$REMOTE_CLEANUP"
    echo "remote_case_dir=$REMOTE_CASE_DIR"
    echo "uid_gid=501:20"
    echo "termux_x11_server=not_launched"
    echo "gamescope=not_used"
    echo "ahb_bridge=not_used"
    echo "surfacecontrol=not_used"
} >"$RUN_DIR/run-metadata.txt"
sha256sum "$PROBE" >"$RUN_DIR/nova-termux-x11-stdio-probe.sha256"
sha256sum "$RUNTIME_CLEANUP" >"$RUN_DIR/nova-runtime-cleanup.sha256"

RUN_STARTED=1
adb shell su -c "/system/bin/sh $REMOTE_PROBE $DEVICE_ROOT $RUN_ID $REMOTE_CASE_DIR" \
    >"$RUN_DIR/probe-output.txt" 2>&1
echo "termux_x11_stdio_probe=pass run_id=$RUN_ID"
