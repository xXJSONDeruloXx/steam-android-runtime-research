#!/usr/bin/env sh

set -eu

mode="${1:-}"
run_id="${2:-}"
game="${3:-/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe}"

case "$mode" in
    wined3d|wined3d-noaudio|dxvk|dxvk-wsi|runtime4-smoke)
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
vulkan_icd=${NOVA_GLIBC_PROTON_VULKAN_ICD:-/opt/nova-kgsl-driver/freedreno-kgsl.icd.json}
vk_selector=${NOVA_GLIBC_PROTON_VK_SELECTOR:-driver-files}
runtime_profile=${NOVA_GLIBC_PROTON_RUNTIME:-steamrt3c}
runtime4_root=${NOVA_GLIBC_PROTON_RUNTIME4_ROOT:-/opt/nova-steam/runtime/SteamLinuxRuntime_4-arm64}
audio_mode=${NOVA_GLIBC_PROTON_AUDIO_MODE:-pulse}
pulse_server=${NOVA_GLIBC_PROTON_PULSE_SERVER:-tcp:127.0.0.1:4713}
proton="$steam_root/compatibilitytools.d/proton-11-arm64/proton"
runtime_entry=
run_root="/tmp/$run_id"
compat_data="$run_root/compatdata/8400"
proton_log_dir="$run_root/proton-log"
dxvk_log_dir="$run_root/dxvk-log"
renderer_mode=$mode
wsi_mode=disabled

case "$vk_selector" in
    driver-files|icd-filenames|none)
        ;;
    *)
        echo "nova_glibc_proton=fail reason=invalid_vk_selector selector=$vk_selector" >&2
        exit 2
        ;;
esac
case "$runtime_profile" in
    steamrt3c|runtime4)
        ;;
    *)
        echo "nova_glibc_proton=fail reason=invalid_runtime_profile profile=$runtime_profile" >&2
        exit 2
        ;;
esac
case "$audio_mode" in
    bridge|pulse|none)
        ;;
    *)
        echo "nova_glibc_proton=fail reason=invalid_audio_mode mode=$audio_mode" >&2
        exit 2
        ;;
esac
case "$vulkan_icd" in
    /*)
        ;;
    *)
        echo "nova_glibc_proton=fail reason=invalid_vulkan_icd path=$vulkan_icd" >&2
        exit 2
        ;;
esac
case "$pulse_server" in
    ''|*[!A-Za-z0-9:._/-]*)
        echo "nova_glibc_proton=fail reason=invalid_pulse_server value=$pulse_server" >&2
        exit 2
        ;;
esac

if [ "$mode" = runtime4-smoke ]; then
    runtime_profile=runtime4
    audio_mode=none
fi

if [ "$runtime_profile" = runtime4 ]; then
    proton="$steam_root/steamapps/common/Proton 11.0 (ARM64)/proton"
    runtime_entry="$runtime4_root/_v2-entry-point"
fi

configure_vulkan_selector() {
    case "$vk_selector" in
        driver-files)
            export VK_DRIVER_FILES="$vulkan_icd"
            unset VK_ICD_FILENAMES
            ;;
        icd-filenames)
            unset VK_DRIVER_FILES
            export VK_ICD_FILENAMES="$vulkan_icd"
            ;;
        none)
            unset VK_DRIVER_FILES
            unset VK_ICD_FILENAMES
            ;;
    esac
}

case "$mode" in
    wined3d)
        export PROTON_USE_WINED3D=1
        unset WINEDLLOVERRIDES
        unset VK_DRIVER_FILES
        unset VK_ICD_FILENAMES
        unset VK_IMPLICIT_LAYER_PATH
        unset MESA_LOADER_DRIVER_OVERRIDE
        unset GALLIUM_DRIVER
        unset LIBGL_ALWAYS_SOFTWARE
        export MESA_LOADER_DRIVER_OVERRIDE=swrast
        export GALLIUM_DRIVER=softpipe
        export LIBGL_ALWAYS_SOFTWARE=1
        export WINE_X11FORCEGLX=1
        ;;
    wined3d-noaudio)
        export PROTON_USE_WINED3D=1
        audio_mode=none
        export WINEDLLOVERRIDES='winepulse.drv=d;winealsa.drv=d'
        unset VK_DRIVER_FILES
        unset VK_ICD_FILENAMES
        unset VK_IMPLICIT_LAYER_PATH
        unset MESA_LOADER_DRIVER_OVERRIDE
        unset GALLIUM_DRIVER
        unset LIBGL_ALWAYS_SOFTWARE
        export MESA_LOADER_DRIVER_OVERRIDE=swrast
        export GALLIUM_DRIVER=softpipe
        export LIBGL_ALWAYS_SOFTWARE=1
        export WINE_X11FORCEGLX=1
        ;;
    dxvk)
        export PROTON_USE_WINED3D=0
        export WINEDLLOVERRIDES='d3d11=n;d3d10core=n;d3d9=n;dxgi=n'
        configure_vulkan_selector
        unset VK_IMPLICIT_LAYER_PATH
        unset MESA_LOADER_DRIVER_OVERRIDE
        unset GALLIUM_DRIVER
        unset LIBGL_ALWAYS_SOFTWARE
        unset WINE_X11FORCEGLX
        ;;
    dxvk-wsi)
        export PROTON_USE_WINED3D=0
        export WINEDLLOVERRIDES='d3d11=n;d3d10core=n;d3d9=n;dxgi=n'
        configure_vulkan_selector
        export VK_IMPLICIT_LAYER_PATH="$run_root/wsi-stage"
        wsi_mode=implicit
        unset MESA_LOADER_DRIVER_OVERRIDE
        unset GALLIUM_DRIVER
        unset LIBGL_ALWAYS_SOFTWARE
        unset WINE_X11FORCEGLX
        ;;
    runtime4-smoke)
        export PROTON_USE_WINED3D=0
        unset WINEDLLOVERRIDES
        unset VK_DRIVER_FILES
        unset VK_ICD_FILENAMES
        unset VK_IMPLICIT_LAYER_PATH
        unset MESA_LOADER_DRIVER_OVERRIDE
        unset GALLIUM_DRIVER
        unset LIBGL_ALWAYS_SOFTWARE
        unset WINE_X11FORCEGLX
        ;;
esac

if [ "$mode" = "dxvk-wsi" ]; then
    for path in \
        "$run_root/wsi-stage/VkLayer_window_system_integration.json" \
        "$run_root/wsi-stage/libVkLayer_window_system_integration.so"; do
        if [ ! -e "$path" ]; then
            echo "nova_glibc_proton=fail reason=missing_wsi_path path=$path" >&2
            exit 1
        fi
    done
fi

if [ "$runtime_profile" = runtime4 ]; then
    for path in \
        "$runtime_entry" \
        "$runtime4_root/run" \
        "$runtime4_root/pressure-vessel/bin/pressure-vessel-wrap" \
        "$runtime4_root/.nova-rooted-runtime4"; do
        if [ ! -e "$path" ]; then
            echo "nova_glibc_proton=fail reason=missing_runtime4_path path=$path" >&2
            exit 1
        fi
    done
    if [ ! -x "$runtime_entry" ] ||
        [ ! -x "$runtime4_root/run" ] ||
        [ ! -x "$runtime4_root/pressure-vessel/bin/pressure-vessel-wrap" ]; then
        echo "nova_glibc_proton=fail reason=nonexecutable_runtime4_path" >&2
        exit 1
    fi
    l2s_path=$(/usr/bin/find "$runtime4_root/pressure-vessel" -type l \
        -lname '*/.l2s/*' -print -quit 2>/dev/null || true)
    if [ -n "$l2s_path" ]; then
        echo "nova_glibc_proton=fail reason=pseudo_hardlink_tree path=$l2s_path" >&2
        exit 1
    fi
fi

if [ "$mode" != runtime4-smoke ]; then
    for path in "$proton" "$game" "$compat_data/pfx"; do
        if [ ! -e "$path" ]; then
            echo "nova_glibc_proton=fail reason=missing_path path=$path" >&2
            exit 1
        fi
    done
fi

/usr/bin/mkdir -p "$proton_log_dir" "$dxvk_log_dir"

runtime_ld_library_path="$steam_root/steamrtarm64:$steam_root/lib/aarch64-linux-gnu:/usr/lib"
if [ "$runtime_profile" = steamrt3c ]; then
    steamrt3c_platform_lib=
    for candidate in "$steam_root"/steam-runtime-steamrt-arm64/*/files/lib/aarch64-linux-gnu; do
        if [ -d "$candidate" ]; then
            steamrt3c_platform_lib=$candidate
            break
        fi
    done
    if [ -z "$steamrt3c_platform_lib" ]; then
        echo "nova_glibc_proton=fail reason=missing_steamrt3c_platform_lib" >&2
        exit 1
    fi
    runtime_ld_library_path="$runtime_ld_library_path:$steamrt3c_platform_lib"
fi

case "$audio_mode" in
    bridge)
        unset PULSE_SERVER
        ;;
    pulse)
        export PULSE_SERVER="$pulse_server"
        ;;
    none)
        unset PULSE_SERVER
        ;;
esac

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
export PROTON_LOG=1
export PROTON_LOG_DIR="$proton_log_dir"
export DXVK_LOG_LEVEL=info
export DXVK_LOG_PATH="$dxvk_log_dir"
export WINE_NEW_NDIS=1
export LD_LIBRARY_PATH="$runtime_ld_library_path"
export LD_PRELOAD=/opt/nova-kgsl-driver/libsysv-sem-shim.so
unset VK_INSTANCE_LAYERS

echo "nova_glibc_proton=pass mode=$mode run_id=$run_id" >&2
echo "nova_glibc_proton_tool=$proton" >&2
echo "nova_glibc_proton_game=$game" >&2
echo "nova_glibc_proton_compat_data=$compat_data" >&2
echo "nova_glibc_proton_setup=proton_run" >&2
echo "nova_glibc_proton_renderer=$renderer_mode" >&2
echo "nova_glibc_proton_wined3d=$PROTON_USE_WINED3D" >&2
echo "nova_glibc_proton_software_gl=${MESA_LOADER_DRIVER_OVERRIDE:-unset}/${GALLIUM_DRIVER:-unset}" >&2
echo "nova_glibc_proton_audio=$audio_mode" >&2
echo "nova_glibc_proton_pulse_server=${PULSE_SERVER:-unset}" >&2
echo "nova_glibc_proton_winedlloverrides=${WINEDLLOVERRIDES:-unset}" >&2
echo "nova_glibc_proton_runtime=$runtime_profile" >&2
echo "nova_glibc_proton_runtime_entry=${runtime_entry:-direct_proton}" >&2
echo "nova_glibc_proton_vk_selector=$vk_selector" >&2
echo "nova_glibc_proton_vk_driver_files=${VK_DRIVER_FILES:-unset}" >&2
echo "nova_glibc_proton_vk_icd=${VK_ICD_FILENAMES:-unset}" >&2
echo "nova_glibc_proton_wsi_layer=$wsi_mode" >&2
echo "nova_glibc_proton_vk_implicit_layer_path=${VK_IMPLICIT_LAYER_PATH:-unset}" >&2
echo "nova_glibc_proton_ld_library_path=$LD_LIBRARY_PATH" >&2
echo "nova_glibc_proton_ld_preload=$LD_PRELOAD" >&2

if [ "$mode" = runtime4-smoke ]; then
    echo "nova_glibc_proton_setup=runtime4_smoke" >&2
    exec /usr/bin/timeout 90 "$runtime_entry" --verb=run -- /bin/true
fi

if [ "$runtime_profile" = runtime4 ]; then
    echo "nova_glibc_proton_setup=runtime4_proton_run" >&2
    exec /usr/bin/timeout 90 "$runtime_entry" --verb=run -- "$proton" run "$game"
fi

exec /usr/bin/timeout 60 "$proton" run "$game"
