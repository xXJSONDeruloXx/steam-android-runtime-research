#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
DEVICE_STAGE=/data/local/tmp/nova-libei-stage
DEVICE_HELPER="$DEVICE_ROOT/opt/nova-kgsl-driver/nova-uinput-gamepad-relay"
CHROOT_HELPER=/opt/nova-kgsl-driver/nova-uinput-gamepad-relay
HELPER=${NOVA_UINPUT_GAMEPAD_RELAY:-$BUILD_DIR/nova-uinput-gamepad-relay}
SOURCE_EVENT=${NOVA_STEAM_GAMEPAD_SOURCE:-/dev/input/event7}
MODE=${NOVA_STEAM_GAMEPAD_MODE:-relay}
RELAY_TIMEOUT=${NOVA_STEAM_GAMEPAD_RELAY_TIMEOUT:-6000}
WAIT_TIMEOUT=${NOVA_STEAM_GAMEPAD_WAIT_TIMEOUT:-60}
INJECT_TEST=${NOVA_STEAM_GAMEPAD_INJECT:-0}
INJECT_CODE=${NOVA_STEAM_GAMEPAD_INJECT_CODE:-305}
RUN_LOG="$BUILD_DIR/native-steam-gamepad-input-smoke.log"
HELPER_LOG="$BUILD_DIR/nova-uinput-gamepad-relay.log"

export INSTALL_HOLO_GAMESCOPE=${INSTALL_HOLO_GAMESCOPE:-0}
export NOVA_AHB_FRAME_COUNT=${NOVA_AHB_FRAME_COUNT:-60}
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

if [ ! -x "$HELPER" ]; then
    "$SCRIPT_DIR/build-uinput-gamepad-relay.sh"
fi

mkdir -p "$BUILD_DIR"
rm -f "$RUN_LOG" "$HELPER_LOG"

"$ADB" shell "mkdir -p $DEVICE_STAGE"
"$ADB" push "$HELPER" "$DEVICE_STAGE/nova-uinput-gamepad-relay" >/dev/null
"$ADB" shell su -c "mkdir -p $DEVICE_ROOT/opt/nova-kgsl-driver"
"$ADB" shell su -c "cp $DEVICE_STAGE/nova-uinput-gamepad-relay $DEVICE_HELPER"
if ! "$ADB" shell su -c "test -x $DEVICE_HELPER"; then
    echo "uinput gamepad relay was not executable in the Holo rootfs" >&2
    exit 1
fi

set +e
"$SCRIPT_DIR/deploy-native-steam-smoke-test.sh" >"$RUN_LOG" 2>&1 &
run_pid=$!
set -e

probe_status=1
elapsed=0
while [ "$elapsed" -lt "$WAIT_TIMEOUT" ]; do
    if "$ADB" shell su -c "test -e $DEVICE_ROOT$SOURCE_EVENT" >/dev/null 2>&1; then
        set +e
        "$ADB" shell su -c "/system/bin/chroot $DEVICE_ROOT /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp $CHROOT_HELPER $SOURCE_EVENT $RELAY_TIMEOUT $MODE" \
            >"$HELPER_LOG" 2>&1 &
        helper_pid=$!
        set -e
        if [ "$INJECT_TEST" = "1" ]; then
            sleep 1
            "$ADB" shell su -c "sendevent $SOURCE_EVENT 1 $INJECT_CODE 1; sendevent $SOURCE_EVENT 0 0 0; sendevent $SOURCE_EVENT 1 $INJECT_CODE 0; sendevent $SOURCE_EVENT 0 0 0" || true
        fi
        set +e
        wait "$helper_pid"
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
cat "$HELPER_LOG"
cat "$RUN_LOG"

if [ "$probe_status" -ne 0 ]; then
    echo "native_steam_gamepad_input_smoke=fail reason=uinput_relay" >&2
    exit 1
fi
for marker in \
    'uinput_open=pass' \
    'uinput_device_ready=pass' \
    'uinput_probe=pass'; do
    if ! rg -q -- "$marker" "$HELPER_LOG"; then
        echo "missing uinput marker: $marker" >&2
        exit 1
    fi
done
if [ "$INJECT_TEST" = "1" ] && ! rg -q -- 'uinput_event_forwarded=pass' "$HELPER_LOG"; then
    echo "missing uinput forwarding marker" >&2
    exit 1
fi
if [ "$run_status" -ne 0 ]; then
    echo "native_steam_gamepad_input_smoke=fail underlying_status=$run_status" >&2
    exit "$run_status"
fi

echo "native_steam_gamepad_input_smoke=pass"
