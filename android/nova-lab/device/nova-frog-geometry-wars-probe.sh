#!/usr/bin/env sh

set -eu

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
display_name="${GAMESCOPE_WAYLAND_DISPLAY:-gamescope-0}"
socket_path="$runtime_dir/$display_name"
ei_socket_path="$socket_path-ei"
steam_root=/opt/nova-steam/home/.local/share/Steam
proton="$steam_root/compatibilitytools.d/proton-11-arm64/proton"
game="$steam_root/steamapps/common/Geometry Wars/GeometryWars.exe"
compat_data="$steam_root/steamapps/compatdata/8400"
proton_log_dir=/tmp/nova-frog-geometry-wars-proton-log

echo "socket_mode_probe_display=$display_name" >&2
echo "socket_mode_probe_runtime=$runtime_dir" >&2
while [ ! -S "$socket_path" ]; do
    /usr/bin/sleep 0.05
done
/usr/bin/ls -ld "$socket_path" "$ei_socket_path" >&2 2>&1 || true
/usr/bin/chmod 0777 "$socket_path"
if [ -S "$ei_socket_path" ]; then
    /usr/bin/chmod 0777 "$ei_socket_path"
fi
/usr/bin/ls -ld "$socket_path" "$ei_socket_path" >&2 2>&1 || true

/usr/bin/mkdir -p "$proton_log_dir"
/usr/bin/chown 501:20 "$proton_log_dir"
/usr/bin/chmod 700 "$proton_log_dir"

dbus_bus=
for candidate in /tmp/nova-steam-runtime/dbus-session-*/bus; do
    if [ -S "$candidate" ]; then
        dbus_bus="$candidate"
        break
    fi
done
echo "geometry_probe_dbus_bus=${dbus_bus:-absent}" >&2
echo "geometry_probe_game=$game" >&2
echo "geometry_probe_compat_data=$compat_data" >&2

common_env="PATH=/usr/bin:/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin HOME=/opt/nova-steam/home USER=steam LOGNAME=steam SteamAppId=8400 SteamGameId=8400 STEAM_COMPAT_CLIENT_INSTALL_PATH=$steam_root STEAM_COMPAT_DATA_PATH=$compat_data PROTON_LOG=1 PROTON_LOG_DIR=$proton_log_dir WINEDEBUG=-all DXVK_LOG_LEVEL=info PROTON_USE_WINED3D=0 WINEDLLOVERRIDES=d3d11=n;d3d10core=n;d3d9=n;dxgi=n VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json MESA_LOADER_DRIVER_OVERRIDE=swrast GALLIUM_DRIVER=softpipe LIBGL_ALWAYS_SOFTWARE=1 LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu LD_PRELOAD=/opt/nova-kgsl-driver/libsysv-sem-shim.so"

if [ -n "$dbus_bus" ]; then
    exec /usr/bin/setpriv --reuid=501 --regid=20 --groups=1005 \
        /usr/bin/env $common_env DBUS_SESSION_BUS_ADDRESS="unix:path=$dbus_bus" \
        /usr/bin/timeout 30 "$proton" runinprefix "$game"
fi

exec /usr/bin/setpriv --reuid=501 --regid=20 --groups=1005 \
    /usr/bin/env $common_env \
    /usr/bin/timeout 30 "$proton" runinprefix "$game"
