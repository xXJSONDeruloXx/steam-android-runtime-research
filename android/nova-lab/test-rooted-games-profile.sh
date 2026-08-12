#!/usr/bin/env bash

set -euo pipefail

root_dir="$(cd "$(dirname "$0")" && pwd)"
device_dir="$root_dir/device"
client="$device_dir/nova-termux-x11-steam-client.sh"
game_runner="$device_dir/nova-proton-glibc-geometry-wars.sh"
runtime_helper="$device_dir/nova-rooted-prepare-runtime4.sh"
official_vdf="$device_dir/nova-steam-arm64-official-compatibilitytools.vdf.in"
launcher="$root_dir/src/main/assets/nova-one-click-root-launcher.sh"
build_script="$root_dir/build.sh"
turnip_build="$root_dir/build-kgsl-turnip.sh"
activity="$root_dir/src/main/java/com/xjsonderulo/steamandroid/novalab/LauncherActivity.java"
session_guard="$root_dir/rootless/nova-rootless-session-guard.py"

[[ -x "$client" ]]
[[ -x "$game_runner" ]]
[[ -x "$runtime_helper" ]]
[[ -f "$official_vdf" ]]
[[ -f "$launcher" ]]
[[ -f "$build_script" ]]
[[ -f "$turnip_build" ]]
[[ -f "$activity" ]]
[[ -f "$session_guard" ]]

sh -n "$client"
bash -n "$game_runner"
bash -n "$runtime_helper"
bash -n "$launcher"
bash -n "$turnip_build"
python3 -c 'from pathlib import Path; compile(Path(__import__("sys").argv[1]).read_text(), __import__("sys").argv[1], "exec")' "$session_guard"

grep -Fq '"appid"               "4628740"' "$official_vdf"
grep -Fq '"depotid"             "4628741"' "$official_vdf"
grep -Fq '"require_tool_appid"  "4185400"' "$official_vdf"
grep -Fq 'SteamLinuxRuntime_4-arm64' "$official_vdf"
grep -Fq '@CLIENT_ROOT@/steamapps/common/Proton 11.0 (ARM64)' "$official_vdf"

grep -Fq 'pressure_vessel_donor=' "$runtime_helper"
grep -Fq 'pseudo_hardlink_tree' "$runtime_helper"
grep -Fq 'auth_secrets_exported=0' "$runtime_helper"
grep -Fq 'does not download or' "$runtime_helper"
if grep -Eq '(^|[[:space:]])(curl|wget)([[:space:]]|$)' "$runtime_helper"; then
    echo "rooted Runtime 4 helper unexpectedly downloads payloads" >&2
    exit 1
fi

grep -Fq 'NOVA_ANDROID_LAUNCHER_VULKAN_SELECTOR' "$launcher"
grep -Fq 'NOVA_ANDROID_LAUNCHER_RUNTIME_PROFILE' "$launcher"
grep -Fq 'NOVA_ANDROID_LAUNCHER_AUDIO_MODE' "$launcher"
grep -Fq 'stage_rooted_runtime_contracts' "$launcher"
grep -Fq 'nova-session-guard.py' "$launcher"
grep -Fq 'nova-steam-arm64-official' "$launcher"
grep -Fq 'nova-proton-glibc-geometry-wars.sh' "$launcher"
grep -Fq 'NOVA_TERMUX_X11_STEAM_VK_SELECTOR' "$launcher"
grep -Fq 'NOVA_TERMUX_X11_STEAM_RUNTIME_PROFILE' "$launcher"
grep -Fq 'NOVA_TERMUX_X11_STEAM_PULSE_SERVER' "$launcher"
grep -Fq 'NOVA_X11_RUNTIME4_SHADOW' "$launcher"
grep -Fq 'NOVA_X11_RUNTIME4_GUEST' "$launcher"

namespace="$device_dir/nova-x11-private-namespace.sh"
grep -Fq 'NOVA_X11_RUNTIME4_SHADOW' "$namespace"
grep -Fq 'bind_runtime4' "$namespace"
grep -Fq 'runtime4_shadow_host' "$namespace"

grep -Fq 'append_capped_file' "$client"
grep -Fq 'NOVA_TERMUX_X11_STEAM_VK_SELECTOR' "$client"
grep -Fq 'VK_DRIVER_FILES' "$client"
grep -Fq 'NOVA_TERMUX_X11_STEAM_RUNTIME_PROFILE' "$client"
grep -Fq 'NOVA_TERMUX_X11_STEAM_RUNTIME4_ROOT' "$client"
grep -Fq 'NOVA_TERMUX_X11_STEAM_AUDIO_MODE' "$client"
grep -Fq 'PULSE_SERVER' "$client"
grep -Fq 'nova-session-guard.py' "$client"

grep -Fq 'runtime4-smoke' "$game_runner"
grep -Fq -- '--verb=run -- /bin/true' "$game_runner"
grep -Fq 'SteamLinuxRuntime_4-arm64' "$game_runner"
grep -Fq 'VK_DRIVER_FILES' "$game_runner"
grep -Fq 'PULSE_SERVER' "$game_runner"
grep -Fq 'pseudo_hardlink_tree' "$game_runner"

grep -Fq 'nova-rooted-prepare-runtime4.sh' "$build_script"
grep -Fq 'nova-steam-arm64-official-compatibilitytools.vdf.in' "$build_script"
grep -Fq 'nova-proton-glibc-geometry-wars.sh' "$build_script"
grep -Fq 'NOVA_MESA_PLATFORMS' "$turnip_build"
grep -Fq -- '-Dplatforms="$NOVA_MESA_PLATFORMS"' "$turnip_build"
grep -Fq 'X11_SYSROOT_HOST' "$turnip_build"
grep -Fq 'libxshmfence-*.pkg.tar.zst' "$turnip_build"
grep -Fq 'cp -al' "$turnip_build"
grep -Fq 'nova-rooted-prepare-runtime4.sh' "$activity"
grep -Fq 'nova-steam-arm64-official-compatibilitytools.vdf.in' "$activity"
grep -Fq 'nova-proton-glibc-geometry-wars.sh' "$activity"

echo "rooted_games_profile_static=pass"
