#!/system/bin/sh

# Explicit diagnostic runner for a GameNative ARM64EC/FEX game on Nova's
# rooted X11 display.  This is intentionally separate from the Nova Steam
# launcher: it borrows GameNative's Bionic compatibility layer without
# replacing Nova's Holo/direct-X11 architecture.

set -u

root="${1:-}"
imagefs="${2:-}"
wine_root="${3:-}"
prefix="${4:-}"
evshim="${5:-}"
game="${6:-}"
display="${7:-}"
game_dir="${8:-${game%/*}}"
desktop_geometry="${9:-1280x960}"
wine_debug="${10:--all}"

if [ -z "$root" ] || [ -z "$imagefs" ] || [ -z "$wine_root" ] ||
    [ -z "$prefix" ] || [ -z "$evshim" ] || [ -z "$game" ] ||
    [ -z "$display" ]; then
    echo "usage: $0 ROOT IMAGEFS WINE_ROOT WINEPREFIX EVSHIM GAME DISPLAY [GAME_DIR] [GEOMETRY] [WINEDEBUG]" >&2
    exit 2
fi

wine_bin="$wine_root/bin/wine"
wine_server="$wine_root/bin/wineserver"
sysvshm="$imagefs/usr/lib/libandroid-sysvshm.so"
redirect="$imagefs/usr/lib/libredirect-bionic.so"

export HOME="$imagefs/home/xuser"
export USER=xuser
export LOGNAME=xuser
export TMPDIR="$imagefs/usr/tmp"
export DISPLAY="$display"
export PATH="$wine_root/bin:$imagefs/usr/bin"
export REDIRECT_EXEC__PROC_SELF_EXE="$wine_bin"
export LD_LIBRARY_PATH="$imagefs/usr/lib:/system/lib64:$wine_root/lib"
export ANDROID_SYSVSHM_SERVER="$imagefs/tmp/.sysvshm/SM0"
export FONTCONFIG_PATH="$imagefs/usr/etc/fonts"
export XDG_DATA_DIRS="$imagefs/usr/share"
export XDG_CONFIG_DIRS="$imagefs/usr/etc/xdg"
export WINE_NO_DUPLICATE_EXPLORER=1
export PREFIX="$imagefs/usr"
export WINE_DISABLE_FULLSCREEN_HACK=1
export ENABLE_UTIL_LAYER=1
export WINE_X11FORCEGLX=1
export WINE_GST_NO_GL=1
export WINE_NEW_NDIS=1
export SteamGameId=0
export HODLL=libwow64fex.dll
export WINELOADER="$wine_bin"
export WINESERVER="$wine_server"
export WINEDLLPATH="$wine_root/lib/wine/aarch64-unix"
export WINEPREFIX="$prefix"
export EVSHIM_WINE=1
export EVSHIM_SHM_NAME=controller-shm0
export EVSHIM_MAX_PLAYERS=4
export EVSHIM_SHM_ID=1
export LD_PRELOAD="$sysvshm:$evshim:$redirect"
export WINEDEBUG="$wine_debug"

/system/bin/mkdir -p "$imagefs/tmp/.sysvshm" "$imagefs/usr/tmp" \
    "$imagefs/tmp/game-logs" "$imagefs/tmp/gamepad"
for n in gamepad gamepad1 gamepad2 gamepad3; do
    /system/bin/dd if=/dev/zero of="$imagefs/tmp/$n.mem" bs=64 count=1 2>/dev/null || exit 1
done

cd "$game_dir" || exit 1
if [ ! -r "$game" ]; then
    echo "nova_gamenative_rooted_game=fail reason=game_unreadable path=$game" >&2
    exit 1
fi

echo "nova_gamenative_rooted_game=pass" >&2
echo "nova_gamenative_rooted_display=$DISPLAY" >&2
echo "nova_gamenative_rooted_game=$game" >&2
echo "nova_gamenative_rooted_prefix=$WINEPREFIX" >&2

# GameNative's production path starts the Wine desktop host first.  That is
# required for the ARM64EC X11 driver to initialize before the game window.
exec /system/bin/linker64 "$wine_bin" explorer \
    "/desktop=shell,$desktop_geometry" "$game"
