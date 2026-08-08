#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
CLIENT_LOG="$BUILD_DIR/nova-steam-hardware-client.log"
CLIENT_STDOUT="$BUILD_DIR/nova-steam-hardware-client.stdout"
CLIENT_STDERR="$BUILD_DIR/nova-steam-hardware-client.stderr"

export INSTALL_HOLO_GAMESCOPE=${INSTALL_HOLO_GAMESCOPE:-0}
export NOVA_AHB_FRAME_COUNT=${NOVA_AHB_FRAME_COUNT:-10}
export NOVA_AHB_WIDTH=${NOVA_AHB_WIDTH:-960}
export NOVA_AHB_HEIGHT=${NOVA_AHB_HEIGHT:-540}
export NOVA_GAMESCOPE_AHB_SKIP_WAYLAND=${NOVA_GAMESCOPE_AHB_SKIP_WAYLAND:-1}
export NOVA_GAMESCOPE_AHB_SKIP_WAYLAND_SHM=${NOVA_GAMESCOPE_AHB_SKIP_WAYLAND_SHM:-1}
export NOVA_GAMESCOPE_AHB_XWAYLAND=${NOVA_GAMESCOPE_AHB_XWAYLAND:-1}
export NOVA_GAMESCOPE_AHB_CONTROL=${NOVA_GAMESCOPE_AHB_CONTROL:-$SCRIPT_DIR/device/gamescope-headless-steam-xwayland-control.sh}
export NOVA_STEAM_BOOTSTRAP_MODE=${NOVA_STEAM_BOOTSTRAP_MODE:-skip}
export NOVA_STEAM_PRELOAD_PROFILE=${NOVA_STEAM_PRELOAD_PROFILE:-sysv}
export NOVA_STEAM_MESA_DRIVER=${NOVA_STEAM_MESA_DRIVER:-msm}
# An unset/empty value is intentional: it lets Mesa select the native Gallium
# driver. Set NOVA_STEAM_GALLIUM_DRIVER=freedreno to probe that explicit name.
export NOVA_STEAM_GALLIUM_DRIVER=${NOVA_STEAM_GALLIUM_DRIVER-}
export NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE=${NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE:-0}
export NOVA_STEAM_NO_CEF_SANDBOX=${NOVA_STEAM_NO_CEF_SANDBOX:-1}
export NOVA_STEAM_CLIENT_TIMEOUT=${NOVA_STEAM_CLIENT_TIMEOUT:-30}
export NOVA_STEAM_GAMESCOPE_TIMEOUT=${NOVA_STEAM_GAMESCOPE_TIMEOUT:-45}

mkdir -p "$BUILD_DIR"
set +e
"$SCRIPT_DIR/deploy-gamescope-headless-ahb-test.sh"
probe_status=$?
set -e

set +e
"$ADB" shell su -c "cat $DEVICE_ROOT/tmp/nova-steam-client.log" >"$CLIENT_LOG" 2>/dev/null
"$ADB" shell su -c "cat $DEVICE_ROOT/tmp/nova-steam-client.stdout" >"$CLIENT_STDOUT" 2>/dev/null
"$ADB" shell su -c "cat $DEVICE_ROOT/tmp/nova-steam-client.stderr" >"$CLIENT_STDERR" 2>/dev/null
set -e

echo "hardware client log: $CLIENT_LOG"
echo "hardware client stdout: $CLIENT_STDOUT"
echo "hardware client stderr: $CLIENT_STDERR"
rg -n --no-heading \
    'client_mesa_driver=|client_gallium_driver=|client_status=|glx: failed|UpdateUI GL|Illegal instruction|SIGILL' \
    "$CLIENT_LOG" "$CLIENT_STDOUT" "$CLIENT_STDERR" || true

if [ "$probe_status" -eq 0 ]; then
    echo "native_steam_hardware_probe=pass"
else
    echo "native_steam_hardware_probe=fail status=$probe_status"
fi
exit "$probe_status"
