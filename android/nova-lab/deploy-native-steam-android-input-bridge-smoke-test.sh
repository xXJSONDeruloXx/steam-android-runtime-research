#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
PACKAGE=com.xjsonderulo.steamandroid.novalab
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
DEVICE_STAGE=/data/local/tmp/nova-libei-stage
DEVICE_HELPER="$DEVICE_ROOT/opt/nova-kgsl-driver/nova-uinput-gamepad-relay"
CHROOT_HELPER=/opt/nova-kgsl-driver/nova-uinput-gamepad-relay
HELPER=${NOVA_UINPUT_GAMEPAD_RELAY:-$BUILD_DIR/nova-uinput-gamepad-relay}
SOURCE_EVENT=${NOVA_STEAM_GAMEPAD_SOURCE:-/dev/input/event7}
MODE=socket
RELAY_TIMEOUT=${NOVA_STEAM_ANDROID_INPUT_RELAY_TIMEOUT:-30000}
WAIT_TIMEOUT=${NOVA_STEAM_ANDROID_INPUT_WAIT_TIMEOUT:-60}
INPUT_KEYCODE=${NOVA_STEAM_ANDROID_INPUT_KEYCODE:-96}
INPUT_MODE=${NOVA_STEAM_ANDROID_INPUT_MODE:-keyevent}
INPUT_EVENT_CODE=${NOVA_STEAM_ANDROID_INPUT_EVENT_CODE:-305}
RUN_LOG="$BUILD_DIR/native-steam-android-input-bridge-smoke.log"
HELPER_LOG="$BUILD_DIR/nova-uinput-android-input-bridge.log"
APP_LOG="$BUILD_DIR/nova-android-input-bridge-logcat.txt"
APP_REPORT="$BUILD_DIR/nova-android-input-bridge-report.txt"

export INSTALL_HOLO_GAMESCOPE=${INSTALL_HOLO_GAMESCOPE:-0}
export NOVA_ANDROID_INPUT_BRIDGE=1
export NOVA_AHB_FRAME_COUNT=${NOVA_AHB_FRAME_COUNT:-5}
export NOVA_AHB_WIDTH=${NOVA_AHB_WIDTH:-960}
export NOVA_AHB_HEIGHT=${NOVA_AHB_HEIGHT:-540}
export NOVA_STEAM_BOOTSTRAP_MODE=${NOVA_STEAM_BOOTSTRAP_MODE:-skip}
export NOVA_STEAM_PRELOAD_PROFILE=${NOVA_STEAM_PRELOAD_PROFILE:-sysv}
export NOVA_STEAM_MESA_DRIVER=${NOVA_STEAM_MESA_DRIVER:-swrast}
export NOVA_STEAM_GALLIUM_DRIVER=${NOVA_STEAM_GALLIUM_DRIVER:-softpipe}
export NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE=${NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE:-1}
export NOVA_STEAM_NO_CEF_SANDBOX=${NOVA_STEAM_NO_CEF_SANDBOX:-1}
export NOVA_STEAM_CLIENT_TIMEOUT=${NOVA_STEAM_CLIENT_TIMEOUT:-30}
export NOVA_STEAM_GAMESCOPE_TIMEOUT=${NOVA_STEAM_GAMESCOPE_TIMEOUT:-40}

if [ ! -x "$HELPER" ]; then
    "$SCRIPT_DIR/build-uinput-gamepad-relay.sh"
fi

mkdir -p "$BUILD_DIR"
rm -f "$RUN_LOG" "$HELPER_LOG" "$APP_LOG" "$APP_REPORT"

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
APP_DATA_DIR=$(
    "$ADB" shell run-as "$PACKAGE" pwd | tr -d '\r'
)
SOCKET_PATH="@$APP_DATA_DIR/files/nova-input.sock"

set +e
wait "$run_pid"
run_status=$?
set -e

probe_status=1
socket_ready=0
for _ in $(seq 1 "$WAIT_TIMEOUT"); do
    if "$ADB" shell cat /proc/net/unix | tr -d '\r' | rg -F -- "$SOCKET_PATH" >/dev/null; then
        socket_ready=1
        break
    fi
    sleep 1
done
if [ "$socket_ready" -eq 1 ]; then
    set +e
    "$ADB" shell su -c "/system/bin/chroot $DEVICE_ROOT /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp $CHROOT_HELPER $SOURCE_EVENT $RELAY_TIMEOUT $MODE $SOCKET_PATH" \
        >"$HELPER_LOG" 2>&1 &
    helper_pid=$!
    set -e
    connected=0
    for _ in $(seq 1 250); do
        "$ADB" shell run-as "$PACKAGE" cat files/android-input-bridge-report.txt \
            >"$APP_REPORT" 2>/dev/null || true
        if rg -q -- 'android_input_socket_connected=pass' "$HELPER_LOG" && \
            rg -q -- 'android_input_socket=connected' "$APP_REPORT"; then
            connected=1
            break
        fi
        if ! kill -0 "$helper_pid" 2>/dev/null; then
            break
        fi
        sleep 0.1
    done
    if [ "$connected" -eq 1 ]; then
        case "$INPUT_MODE" in
            keyevent)
                "$ADB" shell input keyevent "$INPUT_KEYCODE" || true
                ;;
            physical)
                "$ADB" shell su -c "sendevent $SOURCE_EVENT 1 $INPUT_EVENT_CODE 1; sendevent $SOURCE_EVENT 0 0 0; sendevent $SOURCE_EVENT 1 $INPUT_EVENT_CODE 0; sendevent $SOURCE_EVENT 0 0 0" || true
                ;;
            *)
                echo "unknown Android input mode: $INPUT_MODE" >&2
                exit 2
                ;;
        esac
    fi
    set +e
    wait "$helper_pid"
    probe_status=$?
    set -e
    for _ in $(seq 1 50); do
        "$ADB" logcat -d -v threadtime -s NovaLab:I >"$APP_LOG"
        "$ADB" shell run-as "$PACKAGE" cat files/android-input-bridge-report.txt \
            >"$APP_REPORT" 2>/dev/null || true
        if rg -q -- 'android_input_key_forwarded=pass' "$APP_REPORT"; then
            break
        fi
        sleep 0.1
    done
fi

cat "$HELPER_LOG" 2>/dev/null || true
cat "$RUN_LOG"
"$ADB" logcat -d -v threadtime -s NovaLab:I >"$APP_LOG"
"$ADB" shell run-as "$PACKAGE" cat files/android-input-bridge-report.txt \
    >"$APP_REPORT" 2>/dev/null || true
cat "$APP_LOG"
cat "$APP_REPORT"

if [ "$probe_status" -ne 0 ]; then
    echo "native_steam_android_input_bridge_smoke=fail reason=uinput_socket_bridge" >&2
    exit 1
fi
for marker in \
    'uinput_open=pass' \
    'uinput_device_ready=pass' \
    'android_input_socket_connected=pass' \
    'android_key_forwarded=pass' \
    'android_input_forwarded=pass' \
    'uinput_probe=pass'; do
    if ! rg -q -- "$marker" "$HELPER_LOG"; then
        echo "missing Android input bridge marker: $marker" >&2
        exit 1
    fi
done
for marker in \
    'android_input_socket=listening' \
    'android_input_device_controller=pass'; do
    if ! rg -q -- "$marker" "$APP_LOG"; then
        echo "missing app Android input marker: $marker" >&2
        exit 1
    fi
done
for marker in \
    'android_input_socket=connected' \
    'android_input_key_forwarded=pass'; do
    if ! rg -q -- "$marker" "$APP_REPORT"; then
        echo "missing app Android input report marker: $marker" >&2
        exit 1
    fi
done
if [ "$INPUT_MODE" = "physical" ] && \
    ! rg -q -- 'android_input_key_event device=[0-9]+ keycode=[0-9]+ source=0x' "$APP_REPORT"; then
    echo "missing physical Android controller key marker" >&2
    exit 1
fi
if [ "$run_status" -ne 0 ]; then
    echo "native_steam_android_input_bridge_smoke=fail underlying_status=$run_status" >&2
    exit "$run_status"
fi

echo "helper log: $HELPER_LOG"
echo "app logcat: $APP_LOG"
echo "app report: $APP_REPORT"
echo "native Steam log: $RUN_LOG"
echo "native_steam_android_input_bridge_smoke=pass"
