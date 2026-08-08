#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
DEVICE_SCRIPT=/data/local/tmp/nova-steam-input-fd-probe.sh
DEVICE_REPORT=/data/local/tmp/nova-steam-input-fd-report.txt
TIMEOUT=${NOVA_STEAM_INPUT_FD_TIMEOUT:-90}
RUN_LOG="$BUILD_DIR/native-steam-input-fd-probe.log"
REPORT="$BUILD_DIR/nova-steam-input-fd-report.txt"

export INSTALL_HOLO_GAMESCOPE=${INSTALL_HOLO_GAMESCOPE:-0}
export NOVA_STEAM_GAMEPAD_RELAY_TIMEOUT=${NOVA_STEAM_GAMEPAD_RELAY_TIMEOUT:-30000}
export NOVA_STEAM_GAMEPAD_WAIT_TIMEOUT=${NOVA_STEAM_GAMEPAD_WAIT_TIMEOUT:-90}
export NOVA_STEAM_CLIENT_TIMEOUT=${NOVA_STEAM_CLIENT_TIMEOUT:-60}
export NOVA_STEAM_GAMESCOPE_TIMEOUT=${NOVA_STEAM_GAMESCOPE_TIMEOUT:-70}

mkdir -p "$BUILD_DIR"
: >"$RUN_LOG"
: >"$REPORT"

"$ADB" push "$SCRIPT_DIR/device/nova-steam-input-fd-probe.sh" "$DEVICE_SCRIPT" >/dev/null
"$ADB" shell su -c "chmod 755 $DEVICE_SCRIPT"

set +e
"$ADB" shell su -c "/system/bin/sh $DEVICE_SCRIPT $DEVICE_ROOT $DEVICE_REPORT $TIMEOUT" >"$REPORT" 2>&1 &
fd_pid=$!
set -e

set +e
"$SCRIPT_DIR/deploy-native-steam-gamepad-input-smoke-test.sh" >"$RUN_LOG" 2>&1
run_status=$?
set -e

set +e
wait "$fd_pid"
fd_status=$?
set -e

cat "$REPORT"
cat "$RUN_LOG"

if [ "$run_status" -ne 0 ]; then
    echo "native_steam_input_fd_probe=fail underlying_status=$run_status" >&2
    exit "$run_status"
fi
if [ "$fd_status" -ne 0 ]; then
    echo "native_steam_input_fd_probe=fail reason=steam_process_fd_missing" >&2
    exit 1
fi
for marker in \
    'headless_gamescope_ahb=pass' \
    'native_steam_smoke=pass' \
    'native_steam_gamepad_input_smoke=pass' \
    'steam_input_fd=pass' \
    'steam_input_fd_probe=pass'; do
    if ! rg -q -- "$marker" "$REPORT" "$RUN_LOG"; then
        echo "missing Steam input FD marker: $marker" >&2
        exit 1
    fi
done

echo "report: $REPORT"
echo "native_steam_input_fd_probe=pass"
