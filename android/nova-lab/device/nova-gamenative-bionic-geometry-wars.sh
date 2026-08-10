#!/system/bin/sh

set -u

if [ "${1:-}" != "--child" ]; then
    exec /system/bin/unshare -m /system/bin/sh "$0" --child "$@"
fi
shift

mode="${1:-}"
run_id="${2:-}"
root="${3:-}"
imagefs="${4:-}"
wine_root="${5:-}"
game="${6:-}"
prefix="${7:-}"
icd="${8:-}"
wsi_dir="${9:-}"
evshim="${10:-}"

if [ "$mode" != "smoke" ] && [ "$mode" != "game" ]; then
    echo "gamenative_bionic=fail reason=invalid_mode" >&2
    exit 2
fi
if [ -z "$run_id" ] || [ -z "$root" ] || [ -z "$imagefs" ] ||
    [ -z "$wine_root" ] || [ -z "$game" ] || [ -z "$prefix" ] ||
    [ -z "$icd" ] || [ -z "$wsi_dir" ] || [ -z "$evshim" ]; then
    echo "gamenative_bionic=fail reason=missing_argument" >&2
    exit 2
fi

linker=/system/bin/linker64
wine_bin="$wine_root/bin/wine"
wine_server="$wine_root/bin/wineserver"
sysvshm="$imagefs/usr/lib/libandroid-sysvshm.so"
redirect="$imagefs/usr/lib/libredirect-bionic.so"
x11_source="$root/tmp/.X11-unix"

for path in "$linker" "$wine_bin" "$wine_server" "$sysvshm" "$redirect" "$evshim" "$icd" "$wsi_dir/VkLayer_window_system_integration.json" "$wsi_dir/libVkLayer_window_system_integration.so" "$x11_source/."; do
    if [ ! -e "$path" ]; then
        echo "gamenative_bionic=fail reason=missing_path path=$path" >&2
        exit 1
    fi
done

export PATH="$wine_root/bin:$imagefs/usr/bin:/system/bin:/product/bin"
export HOME="$imagefs/home/xuser"
export USER=xuser
export LOGNAME=xuser
export DISPLAY="unix:$root/tmp:0"
export XDG_RUNTIME_DIR="$imagefs/tmp"
export TMPDIR="$imagefs/tmp"
export LANG=C
export LC_ALL=C
export WINEPREFIX="$prefix"
export WINELOADER="$wine_bin"
export WINESERVER="$wine_server"
export WINEDLLPATH="$wine_root/lib/wine/aarch64-unix"
export HODLL=libwow64fex.dll
export REDIRECT_EXEC__PROC_SELF_EXE="$wine_bin"
export WINE_X11FORCEGLX=1
export WINE_NEW_NDIS=1
export STEAM_COMPAT_CLIENT_INSTALL_PATH="$root/opt/nova-steam/home/.local/share/Steam"
export STEAM_COMPAT_DATA_PATH="$root/opt/nova-steam/home/.local/share/Steam/steamapps/compatdata/8400"
export SteamAppId=8400
export SteamGameId=8400
export VK_ICD_FILENAMES="$icd"
export VK_IMPLICIT_LAYER_PATH="$wsi_dir"
export VK_LOADER_DEBUG=error,warn,driver
export DXVK_LOG_LEVEL=info
export DXVK_LOG_PATH="$imagefs/tmp/$run_id/game-logs"
export WINEDEBUG=+loaddll,+seh
export ANDROID_SYSVSHM_SERVER="$imagefs/tmp/.sysvshm/SM0"
export LD_LIBRARY_PATH="$imagefs/usr/lib:/system/lib64:$wine_root/lib:$wine_root/lib/wine/aarch64-unix"
export LD_PRELOAD="$sysvshm:$evshim:$redirect"
export EVSHIM_WINE=1
export EVSHIM_SHM_NAME=controller-shm0
export EVSHIM_MAX_PLAYERS=4
export EVSHIM_SHM_ID=1
export WINE_NO_DUPLICATE_EXPLORER=1
export WINE_DISABLE_FULLSCREEN_HACK=1
export PREFIX="$imagefs/usr"
export XDG_DATA_DIRS="$imagefs/usr/share"
export XDG_CONFIG_DIRS="$imagefs/usr/etc/xdg"
export FONTCONFIG_PATH="$imagefs/usr/etc/fonts"
export SSL_CERT_FILE="$imagefs/usr/etc/tls/cert.pem"
export SSL_CERT_DIR="$imagefs/usr/etc/tls/certs"
export ANDROID_RESOLV_DNS=8.8.4.4

/system/bin/mkdir -p "$HOME" "$DXVK_LOG_PATH" "$imagefs/tmp/.sysvshm"

echo "gamenative_bionic=pass mode=$mode run_id=$run_id" >&2
echo "gamenative_bionic_linker=$linker" >&2
echo "gamenative_bionic_wine=$wine_bin" >&2
echo "gamenative_bionic_hodll=$HODLL" >&2
echo "gamenative_bionic_display=$DISPLAY" >&2
echo "gamenative_bionic_vk_icd=$VK_ICD_FILENAMES" >&2
echo "gamenative_bionic_wsi_layer=$VK_IMPLICIT_LAYER_PATH" >&2
echo "gamenative_bionic_ld_library_path=$LD_LIBRARY_PATH" >&2
echo "gamenative_bionic_ld_preload=$LD_PRELOAD" >&2

if [ "$mode" = "smoke" ]; then
    exec "$linker" "$wine_bin" --version
fi

game_dir="${game%/*}"
if [ -d "$game_dir" ]; then
    cd "$game_dir" || exit 1
fi

exec "$linker" "$imagefs/usr/bin/timeout" 45 "$wine_bin" "$game"
