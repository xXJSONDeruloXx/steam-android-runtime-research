#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
DEVICE_STAGE=/data/local/tmp/nova-input-udev-stage
DEVICE_SCRIPT=/data/local/tmp/nova-input-udev-smoke.sh
DEVICE_REPORT=/data/local/tmp/nova-input-udev-report.txt
DEVICE_HELPER="$DEVICE_ROOT/opt/nova-kgsl-driver/nova-uinput-gamepad-relay"
DEVICE_PROBE="$DEVICE_ROOT/opt/nova-kgsl-driver/nova-input-udev-probe"
HELPER=${NOVA_UINPUT_GAMEPAD_RELAY:-$BUILD_DIR/nova-uinput-gamepad-relay}
PROBE=${NOVA_INPUT_UDEV_PROBE:-$BUILD_DIR/nova-input-udev-probe}
SOURCE_EVENT=${NOVA_STEAM_GAMEPAD_SOURCE:-/dev/input/event7}
RELAY_TIMEOUT=${NOVA_INPUT_UDEV_RELAY_TIMEOUT:-10000}
UDEVD_MODE=${NOVA_INPUT_UDEV_MODE:-disabled}
SDL3_MODE=${NOVA_INPUT_SDL3_PROBE:-0}
SDL3_PROBE=${NOVA_SDL3_JOYSTICK_PROBE:-$BUILD_DIR/nova-sdl3-joystick-probe}
SDL3_LIBRARY=${NOVA_SDL3_LIBRARY:-/opt/nova-steam/home/.local/share/Steam/steamrtarm64/libSDL3.so.0}
CHROOT_SDL3_PROBE=/opt/nova-kgsl-driver/nova-sdl3-joystick-probe
REPORT="$BUILD_DIR/nova-input-udev-report.txt"

if [ ! -x "$HELPER" ]; then
    "$SCRIPT_DIR/build-uinput-gamepad-relay.sh"
fi
if [ ! -x "$PROBE" ]; then
    "$SCRIPT_DIR/build-input-udev-probe.sh"
fi
if [ "$SDL3_MODE" = "1" ] && [ ! -x "$SDL3_PROBE" ]; then
    "$SCRIPT_DIR/build-sdl3-joystick-probe.sh"
fi

mkdir -p "$BUILD_DIR"
rm -f "$REPORT"
"$ADB" shell su -c "mkdir -p $DEVICE_STAGE $DEVICE_ROOT/opt/nova-kgsl-driver"
"$ADB" shell su -c "chmod 777 $DEVICE_STAGE"
"$ADB" push "$HELPER" "$DEVICE_STAGE/nova-uinput-gamepad-relay" >/dev/null
"$ADB" push "$PROBE" "$DEVICE_STAGE/nova-input-udev-probe" >/dev/null
"$ADB" push "$SCRIPT_DIR/device/nova-input-udev-smoke.sh" "$DEVICE_SCRIPT" >/dev/null
"$ADB" shell su -c "cp $DEVICE_STAGE/nova-uinput-gamepad-relay $DEVICE_HELPER"
"$ADB" shell su -c "cp $DEVICE_STAGE/nova-input-udev-probe $DEVICE_PROBE"
if [ "$SDL3_MODE" = "1" ]; then
    DEVICE_SDL3_PROBE="$DEVICE_ROOT$CHROOT_SDL3_PROBE"
    "$ADB" push "$SDL3_PROBE" "$DEVICE_STAGE/nova-sdl3-joystick-probe" >/dev/null
    "$ADB" shell su -c "cp $DEVICE_STAGE/nova-sdl3-joystick-probe $DEVICE_SDL3_PROBE"
    "$ADB" shell su -c "chmod 755 $DEVICE_SDL3_PROBE"
    SDL_ARGS="$CHROOT_SDL3_PROBE $SDL3_LIBRARY"
else
    DEVICE_SDL3_PROBE=
    SDL_ARGS=
fi
"$ADB" shell su -c "chmod 755 $DEVICE_HELPER $DEVICE_PROBE $DEVICE_SCRIPT"

set +e
"$ADB" shell su -c "/system/bin/sh $DEVICE_SCRIPT $DEVICE_ROOT /opt/nova-kgsl-driver/nova-uinput-gamepad-relay /opt/nova-kgsl-driver/nova-input-udev-probe $SOURCE_EVENT $RELAY_TIMEOUT $DEVICE_REPORT /data/local/tmp/nova-input-udev-work $UDEVD_MODE $SDL_ARGS" >/dev/null
run_status=$?
set -e
"$ADB" pull "$DEVICE_REPORT" "$REPORT" >/dev/null 2>&1 || true
cat "$REPORT" 2>/dev/null || true

if [ "$run_status" -ne 0 ]; then
    echo "native_steam_input_device_probe=fail status=$run_status" >&2
    exit "$run_status"
fi
for marker in \
    'udev_context=pass' \
    'udev_virtual_sysfs=pass' \
    'udev_virtual_discoverable=pass' \
    'input_ioctl_name=pass' \
    'input_nonroot_open=pass' \
    'udev_probe=pass'; do
    if ! rg -q -- "$marker" "$REPORT"; then
        echo "missing input device probe marker: $marker" >&2
        exit 1
    fi
done
if [ "$UDEVD_MODE" = "enabled" ]; then
    for marker in \
        'udev_smoke_udevd=pass' \
        'udev_virtual_id_input_joystick=1'; do
        if ! rg -q -- "$marker" "$REPORT"; then
            echo "missing enabled udev marker: $marker" >&2
            exit 1
        fi
    done
fi
if [ "$SDL3_MODE" = "1" ]; then
    for marker in \
        'sdl3_virtual_joystick=pass' \
        'sdl3_virtual_open=pass' \
        'sdl3_probe=pass'; do
        if ! rg -q -- "$marker" "$REPORT"; then
            echo "missing SDL3 joystick marker: $marker" >&2
            exit 1
        fi
    done
fi

echo "report: $REPORT"
echo "native_steam_input_device_probe=pass"
