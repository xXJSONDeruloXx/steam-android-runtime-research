#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
DEVICE_STAGE=/data/local/tmp/nova-libei-stage
DEVICE_PROBE="$DEVICE_ROOT/opt/nova-kgsl-driver/nova-libei-key-probe"
PROBE=${NOVA_LIBEI_KEY_PROBE:-$BUILD_DIR/nova-libei-key-probe}
RUN_LOG="$BUILD_DIR/native-steam-input-smoke.log"
PROBE_LOG="$BUILD_DIR/nova-libei-key-probe.log"
SOCKET_NAME=gamescope-0-ei
WAIT_TIMEOUT=${NOVA_STEAM_INPUT_WAIT_TIMEOUT:-60}
KEYCODE=${NOVA_STEAM_INPUT_KEYCODE:-28}

export INSTALL_HOLO_GAMESCOPE=${INSTALL_HOLO_GAMESCOPE:-0}
export NOVA_AHB_FRAME_COUNT=${NOVA_AHB_FRAME_COUNT:-120}
export NOVA_AHB_WIDTH=${NOVA_AHB_WIDTH:-960}
export NOVA_AHB_HEIGHT=${NOVA_AHB_HEIGHT:-540}
export NOVA_STEAM_BOOTSTRAP_MODE=${NOVA_STEAM_BOOTSTRAP_MODE:-skip}
export NOVA_STEAM_PRELOAD_PROFILE=${NOVA_STEAM_PRELOAD_PROFILE:-sysv}
export NOVA_STEAM_MESA_DRIVER=${NOVA_STEAM_MESA_DRIVER:-swrast}
export NOVA_STEAM_GALLIUM_DRIVER=${NOVA_STEAM_GALLIUM_DRIVER:-softpipe}
export NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE=${NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE:-1}
export NOVA_STEAM_NO_CEF_SANDBOX=${NOVA_STEAM_NO_CEF_SANDBOX:-1}
export NOVA_STEAM_CLIENT_TIMEOUT=${NOVA_STEAM_CLIENT_TIMEOUT:-60}
export NOVA_STEAM_GAMESCOPE_TIMEOUT=${NOVA_STEAM_GAMESCOPE_TIMEOUT:-70}

if [ ! -x "$PROBE" ]; then
    "$SCRIPT_DIR/build-libei-key-probe.sh"
fi

mkdir -p "$BUILD_DIR"
rm -f "$RUN_LOG" "$PROBE_LOG"

"$ADB" shell su -c "mkdir -p $DEVICE_STAGE"
"$ADB" shell su -c "/system/bin/chmod 777 $DEVICE_STAGE"
"$ADB" push "$PROBE" "$DEVICE_STAGE/nova-libei-key-probe" >/dev/null
"$ADB" shell su -c "mkdir -p $DEVICE_ROOT/opt/nova-kgsl-driver"
"$ADB" shell su -c "cp $DEVICE_STAGE/nova-libei-key-probe $DEVICE_PROBE"
"$ADB" shell su -c "/system/bin/chmod 755 $DEVICE_PROBE" || true
if ! "$ADB" shell su -c "test -x $DEVICE_PROBE"; then
    echo "input probe was not executable in the Holo rootfs" >&2
    exit 1
fi

set +e
"$SCRIPT_DIR/deploy-native-steam-smoke-test.sh" >"$RUN_LOG" 2>&1 &
run_pid=$!
set -e

probe_status=1
elapsed=0
while [ "$elapsed" -lt "$WAIT_TIMEOUT" ]; do
    socket_path=$(
        "$ADB" shell su -c "find $DEVICE_ROOT/tmp -maxdepth 1 -type s -name '$SOCKET_NAME' -print 2>/dev/null" \
            2>/dev/null | tr -d '\r' | head -n 1
    )
    if [ -n "$socket_path" ]; then
        set +e
        "$ADB" shell su -c "/system/bin/chroot $DEVICE_ROOT /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp /opt/nova-kgsl-driver/nova-libei-key-probe /tmp/$SOCKET_NAME $KEYCODE 15000" \
            >"$PROBE_LOG" 2>&1
        probe_status=$?
        set -e
        break
    fi
    if ! kill -0 "$run_pid" 2>/dev/null; then
        break
    fi
    sleep 1
    elapsed=$((elapsed + 1))
done

set +e
wait "$run_pid"
run_status=$?
set -e
cat "$RUN_LOG"
cat "$PROBE_LOG"

if [ "$run_status" -ne 0 ]; then
    echo "native_steam_input_smoke=fail underlying_status=$run_status" >&2
    exit "$run_status"
fi
if [ "$probe_status" -ne 0 ]; then
    echo "native_steam_input_smoke=fail reason=libei_probe_timeout_or_error" >&2
    exit 1
fi
for marker in \
    'libei_connect=pass' \
    'libei_keyboard_seat=pass' \
    'libei_keyboard_device=pass' \
    'libei_device_resumed=pass' \
    'libei_key_sent=pass' \
    'libei_roundtrip=pass' \
    'libei_probe=pass'; do
    if ! rg -q -- "$marker" "$PROBE_LOG"; then
        echo "missing libei probe marker: $marker" >&2
        exit 1
    fi
done

echo "native_steam_input_smoke=pass"
