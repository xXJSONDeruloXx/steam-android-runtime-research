#!/usr/bin/env sh

set -eu

mode="${1:-}"
run_id="${2:-}"
game="${3:-/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe}"

case "$mode" in
    wined3d|wined3d-noaudio)
        ;;
    *)
        echo "nova_glibc_proton=fail reason=invalid_mode mode=$mode" >&2
        exit 2
        ;;
esac

case "$run_id" in
    ''|*[!A-Za-z0-9._-]*)
        echo "nova_glibc_proton=fail reason=invalid_run_id" >&2
        exit 2
        ;;
esac

steam_root=/opt/nova-steam/home/.local/share/Steam
proton="$steam_root/compatibilitytools.d/proton-11-arm64/proton"
run_root="/tmp/$run_id"
compat_data="$run_root/compatdata/8400"
proton_log_dir="$run_root/proton-log"
dxvk_log_dir="$run_root/dxvk-log"
audio_mode=enabled
if [ "$mode" = "wined3d-noaudio" ]; then
    audio_mode=disabled
    export WINEDLLOVERRIDES='winepulse.drv=d;winealsa.drv=d'
else
    unset WINEDLLOVERRIDES
fi

for path in "$proton" "$game" "$compat_data/pfx"; do
    if [ ! -e "$path" ]; then
        echo "nova_glibc_proton=fail reason=missing_path path=$path" >&2
        exit 1
    fi
done

/usr/bin/mkdir -p "$proton_log_dir" "$dxvk_log_dir"

export PATH="$steam_root/steam-runtime-steamrt-arm64/bin:/usr/bin:/bin"
export HOME=/opt/nova-steam/home
export USER=steam
export LOGNAME=steam
export DISPLAY=:0
export XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
export LANG=C
export LC_ALL=C
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$steam_root"
export STEAM_COMPAT_DATA_PATH="$compat_data"
export SteamAppId=8400
export SteamGameId=8400
export PROTON_USE_WINED3D=1
export PROTON_LOG=1
export PROTON_LOG_DIR="$proton_log_dir"
export DXVK_LOG_LEVEL=info
export DXVK_LOG_PATH="$dxvk_log_dir"
export WINE_X11FORCEGLX=1
export WINE_NEW_NDIS=1
export MESA_LOADER_DRIVER_OVERRIDE=swrast
export GALLIUM_DRIVER=softpipe
export LIBGL_ALWAYS_SOFTWARE=1
export LD_LIBRARY_PATH="$steam_root/steamrtarm64:$steam_root/lib/aarch64-linux-gnu:/usr/lib:$steam_root/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu"
export LD_PRELOAD=/opt/nova-kgsl-driver/libsysv-sem-shim.so
unset VK_ICD_FILENAMES
unset VK_IMPLICIT_LAYER_PATH
unset VK_INSTANCE_LAYERS

echo "nova_glibc_proton=pass mode=$mode run_id=$run_id" >&2
echo "nova_glibc_proton_tool=$proton" >&2
echo "nova_glibc_proton_game=$game" >&2
echo "nova_glibc_proton_compat_data=$compat_data" >&2
echo "nova_glibc_proton_setup=proton_run" >&2
echo "nova_glibc_proton_wined3d=$PROTON_USE_WINED3D" >&2
echo "nova_glibc_proton_software_gl=$MESA_LOADER_DRIVER_OVERRIDE/$GALLIUM_DRIVER" >&2
echo "nova_glibc_proton_audio=$audio_mode" >&2
echo "nova_glibc_proton_winedlloverrides=${WINEDLLOVERRIDES:-unset}" >&2
echo "nova_glibc_proton_vk_icd=unset" >&2
echo "nova_glibc_proton_ld_library_path=$LD_LIBRARY_PATH" >&2
echo "nova_glibc_proton_ld_preload=$LD_PRELOAD" >&2

exec /usr/bin/timeout 60 "$proton" run "$game"
