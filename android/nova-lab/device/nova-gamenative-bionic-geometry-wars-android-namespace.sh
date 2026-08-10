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
evshim="${8:-}"

if [ "$mode" != "smoke" ] && [ "$mode" != "game" ]; then
    echo "gamenative_bionic_adapter=fail reason=invalid_mode" >&2
    exit 2
fi
if [ -z "$run_id" ] || [ -z "$root" ] || [ -z "$imagefs" ] ||
    [ -z "$wine_root" ] || [ -z "$game" ] || [ -z "$prefix" ] ||
    [ -z "$evshim" ]; then
    echo "gamenative_bionic_adapter=fail reason=missing_argument" >&2
    exit 2
fi

for path in \
    /system/bin/linker64 \
    "$root/usr/bin/env" \
    "$root/usr/bin/setpriv" \
    "$root/tmp/.X11-unix/X0" \
    "$imagefs/usr/lib/libandroid-sysvshm.so" \
    "$imagefs/usr/lib/libredirect-bionic.so" \
    "$evshim" \
    "$wine_root/bin/wine" \
    "$wine_root/bin/wineserver" \
    "$root/opt/nova-kgsl-driver/freedreno-kgsl.icd.json" \
    "$root/tmp/$run_id/VkLayer_window_system_integration.json" \
    "$root/tmp/$run_id/libVkLayer_window_system_integration.so"; do
    if [ ! -e "$path" ]; then
        echo "gamenative_bionic_adapter=fail reason=missing_path path=$path" >&2
        exit 1
    fi
done

for path in system vendor apex product odm linkerconfig dev proc; do
    if [ ! -d "$root/$path" ]; then
        /system/bin/mkdir -p "$root/$path" || {
            echo "gamenative_bionic_adapter=fail reason=mkdir_target path=$root/$path" >&2
            exit 1
        }
    fi
done

mounted_system=0
mounted_vendor=0
mounted_apex=0
mounted_apex_runtime=0
mounted_product=0
mounted_odm=0
mounted_linkerconfig=0
mounted_dev=0
mounted_proc=0

cleanup_mounts() {
    if [ "$mounted_proc" -eq 1 ]; then
        /system/bin/umount -l "$root/proc" >/dev/null 2>&1 || true
        mounted_proc=0
    fi
    if [ "$mounted_dev" -eq 1 ]; then
        /system/bin/umount -l "$root/dev" >/dev/null 2>&1 || true
        mounted_dev=0
    fi
    if [ "$mounted_linkerconfig" -eq 1 ]; then
        /system/bin/umount -l "$root/linkerconfig" >/dev/null 2>&1 || true
        mounted_linkerconfig=0
    fi
    if [ "$mounted_odm" -eq 1 ]; then
        /system/bin/umount -l "$root/odm" >/dev/null 2>&1 || true
        mounted_odm=0
    fi
    if [ "$mounted_product" -eq 1 ]; then
        /system/bin/umount -l "$root/product" >/dev/null 2>&1 || true
        mounted_product=0
    fi
    if [ "$mounted_apex_runtime" -eq 1 ]; then
        /system/bin/umount -l "$root/apex/com.android.runtime" >/dev/null 2>&1 || true
        mounted_apex_runtime=0
    fi
    if [ "$mounted_apex" -eq 1 ]; then
        /system/bin/umount -l "$root/apex" >/dev/null 2>&1 || true
        mounted_apex=0
    fi
    if [ "$mounted_vendor" -eq 1 ]; then
        /system/bin/umount -l "$root/vendor" >/dev/null 2>&1 || true
        mounted_vendor=0
    fi
    if [ "$mounted_system" -eq 1 ]; then
        /system/bin/umount -l "$root/system" >/dev/null 2>&1 || true
        mounted_system=0
    fi
}
trap cleanup_mounts EXIT INT TERM

if ! /system/bin/mount -o bind /system "$root/system"; then
    echo "gamenative_bionic_adapter=fail reason=bind_system" >&2
    exit 1
fi
mounted_system=1
if ! /system/bin/mount -o bind /vendor "$root/vendor"; then
    echo "gamenative_bionic_adapter=fail reason=bind_vendor" >&2
    exit 1
fi
mounted_vendor=1
if ! /system/bin/mount -o bind /apex "$root/apex"; then
    echo "gamenative_bionic_adapter=fail reason=bind_apex" >&2
    exit 1
fi
mounted_apex=1
if [ -d /apex/com.android.runtime ]; then
    /system/bin/mkdir -p "$root/apex/com.android.runtime"
    if ! /system/bin/mount -o bind /apex/com.android.runtime "$root/apex/com.android.runtime"; then
        echo "gamenative_bionic_adapter=fail reason=bind_apex_runtime" >&2
        exit 1
    fi
    mounted_apex_runtime=1
fi
if ! /system/bin/mount -o bind /product "$root/product"; then
    echo "gamenative_bionic_adapter=fail reason=bind_product" >&2
    exit 1
fi
mounted_product=1
if ! /system/bin/mount -o bind /odm "$root/odm"; then
    echo "gamenative_bionic_adapter=fail reason=bind_odm" >&2
    exit 1
fi
mounted_odm=1
if ! /system/bin/mount -o bind /linkerconfig "$root/linkerconfig"; then
    echo "gamenative_bionic_adapter=fail reason=bind_linkerconfig" >&2
    exit 1
fi
mounted_linkerconfig=1
if ! /system/bin/mount -o bind /dev "$root/dev"; then
    echo "gamenative_bionic_adapter=fail reason=bind_dev" >&2
    exit 1
fi
mounted_dev=1
if ! /system/bin/mount -o bind /proc "$root/proc"; then
    echo "gamenative_bionic_adapter=fail reason=bind_proc" >&2
    exit 1
fi
mounted_proc=1

if ! /system/bin/chroot "$root" /usr/bin/ls -l \
    /system/bin/linker64 /apex/com.android.runtime/bin/linker64; then
    echo "gamenative_bionic_adapter=fail reason=linker_namespace_paths" >&2
    exit 1
fi

imagefs_rel="/tmp/$run_id/imagefs"
wine_root_rel="/tmp/$run_id/gamenative-proton"
compat_data_rel="/tmp/$run_id/compatdata/8400"
prefix_rel="$compat_data_rel/pfx"
game_rel="/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe"
wine_bin_rel="$wine_root_rel/bin/wine"
wine_server_rel="$wine_root_rel/bin/wineserver"
evshim_rel="/tmp/$run_id/libevshim.so"
wsi_rel="/tmp/$run_id"
icd_rel="/opt/nova-kgsl-driver/freedreno-kgsl.icd.json"

guest_path="$wine_root_rel/bin:$imagefs_rel/usr/bin:/system/bin:/product/bin"
guest_ld_library_path="$imagefs_rel/usr/lib:/system/lib64:$wine_root_rel/lib:$wine_root_rel/lib/wine/aarch64-unix"
guest_ld_preload="$imagefs_rel/usr/lib/libandroid-sysvshm.so:$evshim_rel:$imagefs_rel/usr/lib/libredirect-bionic.so"

echo "gamenative_bionic_adapter=pass mode=$mode run_id=$run_id" >&2
echo "gamenative_bionic_adapter_uid=2000" >&2
echo "gamenative_bionic_adapter_linker=/system/bin/linker64" >&2
echo "gamenative_bionic_adapter_wine=$wine_bin_rel" >&2
echo "gamenative_bionic_adapter_display=:0" >&2
echo "gamenative_bionic_adapter_vk_icd=$icd_rel" >&2
echo "gamenative_bionic_adapter_wsi_layer=$wsi_rel" >&2
echo "gamenative_bionic_adapter_ld_library_path=$guest_ld_library_path" >&2
echo "gamenative_bionic_adapter_ld_preload=$guest_ld_preload" >&2

run_guest() {
    unset LD_LIBRARY_PATH LD_PRELOAD
    /system/bin/chroot "$root" \
        /usr/bin/setpriv --reuid=2000 --regid=2000 --groups=2000 \
        /usr/bin/env -i \
        "PATH=$guest_path" \
        "HOME=$imagefs_rel/home/xuser" \
        USER=xuser \
        LOGNAME=xuser \
        DISPLAY=:0 \
        "XDG_RUNTIME_DIR=$imagefs_rel/tmp" \
        "TMPDIR=$imagefs_rel/tmp" \
        LANG=C \
        LC_ALL=C \
        "WINEPREFIX=$prefix_rel" \
        "WINELOADER=$wine_bin_rel" \
        "WINESERVER=$wine_server_rel" \
        "WINEDLLPATH=$wine_root_rel/lib/wine/aarch64-unix" \
        HODLL=libwow64fex.dll \
        "REDIRECT_EXEC__PROC_SELF_EXE=$wine_bin_rel" \
        WINE_X11FORCEGLX=1 \
        WINE_NEW_NDIS=1 \
        "STEAM_COMPAT_CLIENT_INSTALL_PATH=/opt/nova-steam/home/.local/share/Steam" \
        "STEAM_COMPAT_DATA_PATH=$compat_data_rel" \
        SteamAppId=8400 \
        SteamGameId=8400 \
        "VK_ICD_FILENAMES=$icd_rel" \
        "VK_IMPLICIT_LAYER_PATH=$wsi_rel" \
        VK_LOADER_DEBUG=error,warn,driver \
        DXVK_LOG_LEVEL=info \
        "DXVK_LOG_PATH=$imagefs_rel/tmp/game-logs" \
        WINEDEBUG=+loaddll,+seh \
        "ANDROID_SYSVSHM_SERVER=$imagefs_rel/tmp/.sysvshm/SM0" \
        "LD_LIBRARY_PATH=$guest_ld_library_path" \
        "LD_PRELOAD=$guest_ld_preload" \
        EVSHIM_WINE=1 \
        EVSHIM_SHM_NAME=controller-shm0 \
        EVSHIM_MAX_PLAYERS=4 \
        EVSHIM_SHM_ID=1 \
        WINE_NO_DUPLICATE_EXPLORER=1 \
        WINE_DISABLE_FULLSCREEN_HACK=1 \
        "PREFIX=$imagefs_rel/usr" \
        "XDG_DATA_DIRS=$imagefs_rel/usr/share" \
        "XDG_CONFIG_DIRS=$imagefs_rel/usr/etc/xdg" \
        "FONTCONFIG_PATH=$imagefs_rel/usr/etc/fonts" \
        "SSL_CERT_FILE=$imagefs_rel/usr/etc/tls/cert.pem" \
        "SSL_CERT_DIR=$imagefs_rel/usr/etc/tls/certs" \
        ANDROID_RESOLV_DNS=8.8.8.8 \
        /system/bin/linker64 "$@"
}

if [ "$mode" = "smoke" ]; then
    run_guest "$wine_bin_rel" --version
    exit $?
fi

run_guest "$imagefs_rel/usr/bin/timeout" 45 "$wine_bin_rel" "$game_rel"
