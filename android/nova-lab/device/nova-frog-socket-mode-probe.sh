#!/usr/bin/env sh

set -eu

runtime_dir="${XDG_RUNTIME_DIR:-/tmp}"
display_name="${GAMESCOPE_WAYLAND_DISPLAY:-gamescope-0}"
socket_path="$runtime_dir/$display_name"
ei_socket_path="$socket_path-ei"

echo "socket_mode_probe_display=$display_name" >&2
echo "socket_mode_probe_runtime=$runtime_dir" >&2
while [ ! -S "$socket_path" ]; do
    /usr/bin/sleep 0.05
done

echo "socket_mode_probe_before=" >&2
/usr/bin/ls -ld "$socket_path" "$ei_socket_path" 2>&1 || true
/usr/bin/chmod 0777 "$socket_path"
if [ -S "$ei_socket_path" ]; then
    /usr/bin/chmod 0777 "$ei_socket_path"
fi
echo "socket_mode_probe_after=" >&2
/usr/bin/ls -ld "$socket_path" "$ei_socket_path" 2>&1 || true

exec /usr/bin/setpriv --reuid=501 --regid=20 --groups=1005 \
    /usr/bin/env ENABLE_GAMESCOPE_WSI=1 \
    /usr/bin/sh -c '
        printf "child_gamescope_wayland_display=%s\nchild_wayland_display=%s\nchild_xdg_runtime_dir=%s\n" \
            "$GAMESCOPE_WAYLAND_DISPLAY" "$WAYLAND_DISPLAY" "$XDG_RUNTIME_DIR" >&2
        id >&2
        exec /usr/bin/timeout 10 /usr/bin/vulkaninfo --summary
    '
