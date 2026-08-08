#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
PACKAGE=com.xjsonderulo.steamandroid.novalab
PROFILE=${NOVA_ACCEPTANCE_PROFILE:-bounded-ahb-1280x960}

if [ "$PROFILE" != "bounded-ahb-1280x960" ]; then
    echo "unsupported Nova acceptance profile: $PROFILE" >&2
    echo "supported profiles: bounded-ahb-1280x960" >&2
    exit 2
fi

: "${NOVA_GAMESCOPE_HEADLESS:?set NOVA_GAMESCOPE_HEADLESS to the exact Gamescope binary}"
: "${GAMESCOPE_HEADLESS_SOURCE:?set GAMESCOPE_HEADLESS_SOURCE to the exact Gamescope source tree}"

if [ ! -f "$NOVA_GAMESCOPE_HEADLESS" ]; then
    echo "missing Gamescope artifact: $NOVA_GAMESCOPE_HEADLESS" >&2
    exit 1
fi
if [ ! -d "$GAMESCOPE_HEADLESS_SOURCE/.git" ]; then
    echo "Gamescope source tree is not a Git worktree: $GAMESCOPE_HEADLESS_SOURCE" >&2
    exit 1
fi

source_commit=$(git -C "$GAMESCOPE_HEADLESS_SOURCE" rev-parse HEAD)
binary_sha256=$(shasum -a 256 "$NOVA_GAMESCOPE_HEADLESS" | awk '{print $1}')
libei_marker=$(strings "$NOVA_GAMESCOPE_HEADLESS" | rg -m1 -i \
    'successfully initialized libei|built without libei' || true)
if ! printf '%s\n' "$libei_marker" | rg -qi 'successfully initialized libei'; then
    echo "acceptance requires a Gamescope binary built with libei" >&2
    exit 1
fi

if [ "${NOVA_AHB_FRAME_COUNT:-10}" != "10" ] || \
    [ "${NOVA_AHB_WIDTH:-1280}" != "1280" ] || \
    [ "${NOVA_AHB_HEIGHT:-960}" != "960" ] || \
    [ "${NOVA_FULLSCREEN_PRESENTATION:-1}" != "1" ] || \
    [ "${NOVA_FULLSCREEN_WIDTH:-1280}" != "1280" ] || \
    [ "${NOVA_FULLSCREEN_HEIGHT:-960}" != "960" ] || \
    [ "${NOVA_FORCE_GPU_COMPOSITION:-0}" != "0" ] || \
    [ "${NOVA_GAMESCOPE_AHB_REQUIRE_TARGET:-1}" != "1" ] || \
    [ "${NOVA_GAMESCOPE_AHB_SKIP_WAYLAND:-0}" != "0" ] || \
    [ "${NOVA_GAMESCOPE_AHB_SKIP_WAYLAND_SHM:-0}" != "0" ] || \
    [ "${NOVA_GAMESCOPE_AHB_XWAYLAND:-0}" != "0" ]; then
    echo "environment does not match $PROFILE" >&2
    echo "profile requires 10 frames at 1280x960, fullscreen 1280x960, overlay composition, and Wayland" >&2
    exit 2
fi

RUN_ID=${NOVA_ACCEPTANCE_RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)-$$}
if [[ ! "$RUN_ID" =~ ^[A-Za-z0-9_.-]+$ ]]; then
    echo "invalid acceptance run id: $RUN_ID" >&2
    exit 2
fi
RUN_DIR=${NOVA_ACCEPTANCE_RUN_DIR:-$BUILD_DIR/runs/$RUN_ID}
if [ -e "$RUN_DIR" ]; then
    if [ -n "$(find "$RUN_DIR" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
        echo "acceptance run directory is not empty: $RUN_DIR" >&2
        exit 2
    fi
else
    mkdir -p "$RUN_DIR"
fi

RUN_STARTED_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)
DEVICE_STARTED_EPOCH=$("$ADB" shell date +%s 2>/dev/null | tr -d '\r')
case "$DEVICE_STARTED_EPOCH" in
    ''|*[!0-9]*)
        echo "could not capture device start timestamp" >&2
        exit 1
        ;;
esac

exec > >(tee "$RUN_DIR/acceptance.log") 2>&1

echo "nova_acceptance_profile=$PROFILE"
echo "nova_run_id=$RUN_ID"
echo "run_started_utc=$RUN_STARTED_UTC"
echo "device_started_epoch=$DEVICE_STARTED_EPOCH"
echo "gamescope_binary=$NOVA_GAMESCOPE_HEADLESS"
echo "gamescope_binary_sha256=$binary_sha256"
echo "gamescope_source_tree=$GAMESCOPE_HEADLESS_SOURCE"
echo "gamescope_source_commit=$source_commit"
echo "gamescope_libei_build=enabled"

{
    echo "nova_acceptance_profile=$PROFILE"
    echo "nova_run_id=$RUN_ID"
    echo "run_started_utc=$RUN_STARTED_UTC"
    echo "device_started_epoch=$DEVICE_STARTED_EPOCH"
    echo "gamescope_binary=$NOVA_GAMESCOPE_HEADLESS"
    echo "gamescope_binary_sha256=$binary_sha256"
    echo "gamescope_source_tree=$GAMESCOPE_HEADLESS_SOURCE"
    echo "gamescope_source_commit=$source_commit"
    echo "gamescope_libei_build=enabled"
    echo "ahb_frames=10"
    echo "ahb_size=1280x960"
    echo "fullscreen_size=1280x960"
    echo "force_gpu_composition=0"
} >"$RUN_DIR/acceptance-manifest.txt"

export NOVA_RUN_ID="$RUN_ID"
export NOVA_RUN_DIR="$RUN_DIR"
export NOVA_RUN_STARTED_UTC="$RUN_STARTED_UTC"
export NOVA_RUN_PROFILE="$PROFILE"
export NOVA_REQUIRE_RUN_MANIFEST=1
export NOVA_GAMESCOPE_INPUT_EMULATION=enabled
export NOVA_REQUIRE_GAMESCOPE_PROVENANCE=1
export NOVA_REQUIRE_GAMESCOPE_LIBEI=1
export NOVA_AHB_FRAME_COUNT=10
export NOVA_AHB_WIDTH=1280
export NOVA_AHB_HEIGHT=960
export NOVA_FULLSCREEN_PRESENTATION=1
export NOVA_FULLSCREEN_WIDTH=1280
export NOVA_FULLSCREEN_HEIGHT=960
export NOVA_FORCE_GPU_COMPOSITION=0
export NOVA_GAMESCOPE_AHB_REQUIRE_TARGET=1
export INSTALL_HOLO_GAMESCOPE=0

set +e
"$SCRIPT_DIR/deploy-gamescope-headless-ahb-test.sh"
deploy_status=$?
set -e
echo "nova_acceptance_deploy_status=$deploy_status"

REPORT="$RUN_DIR/device-gamescope-headless-ahb-report.txt"
LOGCAT="$RUN_DIR/device-gamescope-headless-ahb-logcat.txt"
APP_REPORT="$RUN_DIR/device-gamescope-headless-ahb-app-report.txt"
SCREENSHOT="$RUN_DIR/device-gamescope-headless-ahb-screenshot.png"
METADATA="$RUN_DIR/device-gamescope-headless-ahb-metadata.txt"

if [ "$deploy_status" -ne 0 ]; then
    echo "nova_acceptance=fail stage=deploy" >&2
    exit "$deploy_status"
fi

for artifact in "$REPORT" "$LOGCAT" "$APP_REPORT" "$SCREENSHOT" "$METADATA"; do
    if [ ! -s "$artifact" ]; then
        echo "missing acceptance artifact: $artifact" >&2
        exit 1
    fi
done

for text_artifact in "$REPORT" "$LOGCAT" "$APP_REPORT" "$METADATA"; do
    if ! rg -q "^nova_run_id=$RUN_ID$" "$text_artifact"; then
        echo "artifact is not attributed to current run: $text_artifact" >&2
        exit 1
    fi
done

for marker in \
    '^gamescope_libei_build=enabled$' \
    '^gamescope_input_emulation=enabled$' \
    '^fullscreen_presentation=1$' \
    '^force_gpu_composition=0$' \
    "^gamescope_binary_sha256=$binary_sha256$" \
    "^gamescope_source_commit=$source_commit$"; do
    if ! rg -q -- "$marker" "$METADATA"; then
        echo "missing acceptance provenance marker: $marker" >&2
        exit 1
    fi
done

for marker in \
    '^headless_gamescope_ahb=pass$' \
    '^headless_ahb_runtime_cleanup=pass$' \
    '^headless_ahb_residual_processes=pass$' \
    '^nova_app_runtime_files_cleanup=pass$'; do
    if ! rg -q -- "$marker" "$RUN_DIR/acceptance.log"; then
        echo "missing acceptance lifecycle marker: $marker" >&2
        exit 1
    fi
done

device_processes=$("$ADB" shell su -c "/system/bin/ps -A -o PID,PPID,ARGS" 2>/dev/null | tr -d '\r')
residual_processes=$(printf '%s\n' "$device_processes" | \
    rg -e '/data/local/tmp/nova-holo-rootfs/opt/nova-steam' \
       -e '/opt/nova-kgsl-driver/gamescope-headless' \
       -e '/opt/nova-kgsl-driver/nova-libei-input-bridge' \
       -e '/opt/nova-kgsl-driver/nova-uinput-gamepad-relay' | \
    rg -v 'nova-runtime-cleanup|ps -A -o PID,PPID,ARGS' || true)
if [ -n "$residual_processes" ]; then
    echo "nova_acceptance_residual_processes=fail" >&2
    printf '%s\n' "$residual_processes" >&2
    exit 1
fi
echo "nova_acceptance_residual_processes=pass"

stale_app_files=$("$ADB" shell \
    "run-as $PACKAGE sh -c 'for path in files/nova-input.sock files/nova-touch.sock files/nova-lab-ahb-double-buffer.sock.* files/dmabuf-double-buffer-report.txt files/android-input-bridge-report.txt files/android-touch-bridge-report.txt; do if [ -e \"\$path\" ]; then echo \"\$path\"; fi; done'" \
    2>/dev/null | tr -d '\r')
if [ -n "$stale_app_files" ]; then
    echo "nova_acceptance_app_files=fail" >&2
    printf '%s\n' "$stale_app_files" >&2
    exit 1
fi
echo "nova_acceptance_app_files=pass"

for artifact in "$REPORT" "$LOGCAT" "$APP_REPORT" "$SCREENSHOT" "$METADATA" "$RUN_DIR/acceptance.log"; do
    artifact_name=$(basename "$artifact" | tr '[:upper:]' '[:lower:]' | tr '.-' '__')
    echo "artifact_${artifact_name}_sha256=$(shasum -a 256 "$artifact" | awk '{print $1}')" \
        >>"$RUN_DIR/acceptance-manifest.txt"
done
echo "finished_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >>"$RUN_DIR/acceptance-manifest.txt"
echo "nova_acceptance=pass"
