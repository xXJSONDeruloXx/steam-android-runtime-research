#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
CLIENT_LOG="$BUILD_DIR/nova-steam-client.log"
CLIENT_STDOUT="$BUILD_DIR/nova-steam-client.stdout"
CLIENT_STDERR="$BUILD_DIR/nova-steam-client.stderr"

export INSTALL_HOLO_GAMESCOPE=${INSTALL_HOLO_GAMESCOPE:-0}
export NOVA_XWAYLAND_ALLOW_LOCAL=${NOVA_XWAYLAND_ALLOW_LOCAL:-1}
export NOVA_AHB_FRAME_COUNT=${NOVA_AHB_FRAME_COUNT:-30}
export NOVA_AHB_WIDTH=${NOVA_AHB_WIDTH:-960}
export NOVA_AHB_HEIGHT=${NOVA_AHB_HEIGHT:-540}
export NOVA_GAMESCOPE_AHB_SKIP_WAYLAND=${NOVA_GAMESCOPE_AHB_SKIP_WAYLAND:-1}
export NOVA_GAMESCOPE_AHB_SKIP_WAYLAND_SHM=${NOVA_GAMESCOPE_AHB_SKIP_WAYLAND_SHM:-1}
export NOVA_GAMESCOPE_AHB_XWAYLAND=${NOVA_GAMESCOPE_AHB_XWAYLAND:-1}
export NOVA_GAMESCOPE_AHB_CONTROL=${NOVA_GAMESCOPE_AHB_CONTROL:-$SCRIPT_DIR/device/gamescope-headless-steam-xwayland-control.sh}
export NOVA_STEAM_BOOTSTRAP_MODE=${NOVA_STEAM_BOOTSTRAP_MODE:-skip}
export NOVA_STEAM_PRELOAD_PROFILE=${NOVA_STEAM_PRELOAD_PROFILE:-sysv}
export NOVA_STEAM_MESA_DRIVER=${NOVA_STEAM_MESA_DRIVER:-swrast}
export NOVA_STEAM_GALLIUM_DRIVER=${NOVA_STEAM_GALLIUM_DRIVER:-softpipe}
export NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE=${NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE:-1}
export NOVA_STEAM_NO_CEF_SANDBOX=${NOVA_STEAM_NO_CEF_SANDBOX:-1}
export NOVA_STEAM_CLIENT_TIMEOUT=${NOVA_STEAM_CLIENT_TIMEOUT:-25}

"$SCRIPT_DIR/deploy-gamescope-headless-ahb-test.sh"

mkdir -p "$BUILD_DIR"
"$ADB" shell "su -c 'cat $DEVICE_ROOT/tmp/nova-steam-client.log'" >"$CLIENT_LOG"
"$ADB" shell "su -c 'cat $DEVICE_ROOT/tmp/nova-steam-client.stdout'" >"$CLIENT_STDOUT"
"$ADB" shell "su -c 'cat $DEVICE_ROOT/tmp/nova-steam-client.stderr'" >"$CLIENT_STDERR"

for marker in \
    'client_started=pass' \
    'client_installed=pass' \
    'Using update UI: glx'; do
    if ! rg -q -- "$marker" "$CLIENT_LOG" "$CLIENT_STDERR"; then
        echo "missing native Steam smoke marker: $marker" >&2
        exit 1
    fi
done

echo "client log: $CLIENT_LOG"
echo "client stdout: $CLIENT_STDOUT"
echo "client stderr: $CLIENT_STDERR"
echo "native_steam_smoke=pass"
