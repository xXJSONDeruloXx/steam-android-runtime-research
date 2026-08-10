#!/usr/bin/env sh

set -eu

run_id="${1:-}"
if [ -z "$run_id" ]; then
    echo "gamenative_proton_runner=fail reason=missing_run_id" >&2
    exit 2
fi

steam_root=/opt/nova-steam/home/.local/share/Steam
compat_data="$steam_root/steamapps/compatdata/8400"
prefix="$compat_data/pfx"
game="$steam_root/steamapps/common/Geometry Wars/GeometryWars.exe"
wine_root="/tmp/$run_id/gamenative-proton"
log_root="/tmp/$run_id/game-logs"
steam_runtime_bin="$steam_root/steam-runtime-steamrt-arm64/bin"
steam_runtime_lib="$steam_root/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu"

/usr/bin/mkdir -p "$log_root"
/usr/bin/chown 501:20 "$log_root"
/usr/bin/chmod 700 "$log_root"

export PATH="$wine_root/bin:/usr/bin:/bin:$steam_runtime_bin"
export HOME=/opt/nova-steam/home
export USER=steam
export LOGNAME=steam
export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
export LANG=C
export LC_ALL=C
export WINEPREFIX="$prefix"
export WINELOADER="$wine_root/bin/wine"
export WINESERVER="$wine_root/bin/wineserver"
export WINEDLLPATH="$wine_root/lib/wine/aarch64-unix"
export HODLL=libwow64fex.dll
export WINE_X11FORCEGLX=1
export WINE_NEW_NDIS=1
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$steam_root"
export STEAM_COMPAT_DATA_PATH="$compat_data"
export SteamAppId=8400
export SteamGameId=8400
export VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
export VK_IMPLICIT_LAYER_PATH="/tmp/$run_id/wsi-stage"
export VK_LOADER_DEBUG=error,warn,driver
export DXVK_LOG_LEVEL=info
export DXVK_LOG_PATH="$log_root"
export WINEDEBUG=+loaddll,+seh
export LD_LIBRARY_PATH="$wine_root/lib:$wine_root/lib/wine/aarch64-unix:$steam_root/steamrtarm64:$steam_root/lib/aarch64-linux-gnu:/usr/lib:$steam_runtime_lib"
export LD_PRELOAD=/opt/nova-kgsl-driver/libsysv-sem-shim.so

echo "gamenative_proton_runner=pass run_id=$run_id" >&2
echo "gamenative_proton_wine=$wine_root/bin/wine" >&2
echo "gamenative_proton_wineserver=$wine_root/bin/wineserver" >&2
echo "gamenative_proton_hodll=$HODLL" >&2
echo "gamenative_proton_display=$DISPLAY" >&2
echo "gamenative_proton_vk_icd=$VK_ICD_FILENAMES" >&2
echo "gamenative_proton_wsi_layer=$VK_IMPLICIT_LAYER_PATH" >&2
echo "gamenative_proton_ld_library_path=$LD_LIBRARY_PATH" >&2
echo "gamenative_proton_ld_preload=$LD_PRELOAD" >&2

exec /usr/bin/timeout 45 "$wine_root/bin/wine" "$game"
