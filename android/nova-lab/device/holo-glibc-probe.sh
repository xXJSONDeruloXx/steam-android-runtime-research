#!/system/bin/sh

set -u

ROOT="${1:-/data/local/tmp/nova-holo-rootfs}"
OUT="${2:-/data/local/tmp/nova-holo-glibc-report.txt}"
WORK="${3:-/data/local/tmp/nova-holo-glibc-work}"
OUT_DIR="${OUT%/*}"
VULKAN_LOADER_DEBUG="${VULKAN_LOADER_DEBUG:-error}"
VULKAN_NODEVICE_SELECT="${VULKAN_NODEVICE_SELECT:-}"
VULKAN_ICD_FILE="${VULKAN_ICD_FILE:-}"
VULKAN_OFFSCREEN_PROBE="${VULKAN_OFFSCREEN_PROBE:-}"
VULKAN_AHB_SOCKET_HOST_DIR="${VULKAN_AHB_SOCKET_HOST_DIR:-}"
VULKAN_AHB_SOCKET_NAME="${VULKAN_AHB_SOCKET_NAME:-nova-lab-ahb-bridge.sock}"
VULKAN_AHB_ASYNC_FENCE="${VULKAN_AHB_ASYNC_FENCE:-}"
VULKAN_AHB_DOUBLE_BUFFER="${VULKAN_AHB_DOUBLE_BUFFER:-}"
VULKAN_AHB_FRAME_COUNT="${VULKAN_AHB_FRAME_COUNT:-}"
VULKAN_AHB_WIDTH="${VULKAN_AHB_WIDTH:-}"
VULKAN_AHB_HEIGHT="${VULKAN_AHB_HEIGHT:-}"
VULKAN_AHB_OUTPUT_SOCKET="${VULKAN_AHB_OUTPUT_SOCKET:-}"
NOVA_XWAYLAND_ALLOW_LOCAL="${NOVA_XWAYLAND_ALLOW_LOCAL:-0}"
NOVA_STEAM_SKIP_INITIAL_BOOTSTRAP="${NOVA_STEAM_SKIP_INITIAL_BOOTSTRAP:-0}"
NOVA_STEAM_BOOTSTRAP_MODE="${NOVA_STEAM_BOOTSTRAP_MODE:-auto}"
NOVA_STEAM_DISABLE_PRELOAD="${NOVA_STEAM_DISABLE_PRELOAD:-0}"
NOVA_STEAM_MESA_DRIVER="${NOVA_STEAM_MESA_DRIVER:-msm}"
NOVA_STEAM_PRELOAD_PROFILE="${NOVA_STEAM_PRELOAD_PROFILE:-full}"
NOVA_STEAM_GALLIUM_DRIVER="${NOVA_STEAM_GALLIUM_DRIVER:-}"
NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE="${NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE:-0}"
NOVA_STEAM_LIBGL_ALWAYS_INDIRECT="${NOVA_STEAM_LIBGL_ALWAYS_INDIRECT:-0}"
NOVA_STEAM_LP_NATIVE_VECTOR_WIDTH="${NOVA_STEAM_LP_NATIVE_VECTOR_WIDTH:-}"
NOVA_STEAM_NO_CEF_SANDBOX="${NOVA_STEAM_NO_CEF_SANDBOX:-0}"
NOVA_STEAM_CLIENT_TIMEOUT="${NOVA_STEAM_CLIENT_TIMEOUT:-25}"
NOVA_STEAM_GAMESCOPE_TIMEOUT="${NOVA_STEAM_GAMESCOPE_TIMEOUT:-35}"
NOVA_STEAM_EXECUTABLE="${NOVA_STEAM_EXECUTABLE:-}"
NOVA_STEAM_EXTRA_ARGS="${NOVA_STEAM_EXTRA_ARGS:-}"
NOVA_STEAM_CLIENT_FLAGS="${NOVA_STEAM_CLIENT_FLAGS:-}"
NOVA_HOLO_NAMESERVER="${NOVA_HOLO_NAMESERVER:-}"
mkdir -p "$OUT_DIR" "$WORK"

{
    echo "probe_version=1"
    echo "rootfs=$ROOT"
    echo "timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "host_id=$(/system/bin/id)"
    echo "host_kernel=$(/system/bin/uname -a 2>&1)"
    echo "vulkan_ahb_socket_host_dir=$VULKAN_AHB_SOCKET_HOST_DIR"
    echo "vulkan_ahb_socket_name=$VULKAN_AHB_SOCKET_NAME"
    echo "vulkan_ahb_output_socket=$VULKAN_AHB_OUTPUT_SOCKET"

    for path in /usr/bin/env /usr/bin/true /usr/bin/sh /usr/bin/vulkaninfo /usr/lib/ld-linux-aarch64.so.1 /usr/lib/libc.so.6; do
        if [ -e "$ROOT$path" ]; then
            echo "rootfs.path.$path=present"
        else
            echo "rootfs.path.$path=missing"
        fi
    done

    HELPER="$WORK/holo-helper.sh"
    cat >"$HELPER" <<EOF
#!/system/bin/sh

ROOT='$ROOT'
VULKAN_LOADER_DEBUG='$VULKAN_LOADER_DEBUG'
VULKAN_NODEVICE_SELECT='$VULKAN_NODEVICE_SELECT'
VULKAN_ICD_FILE='$VULKAN_ICD_FILE'
VULKAN_OFFSCREEN_PROBE='$VULKAN_OFFSCREEN_PROBE'
VULKAN_AHB_SOCKET_HOST_DIR='$VULKAN_AHB_SOCKET_HOST_DIR'
VULKAN_AHB_SOCKET_NAME='$VULKAN_AHB_SOCKET_NAME'
VULKAN_AHB_ASYNC_FENCE='$VULKAN_AHB_ASYNC_FENCE'
VULKAN_AHB_DOUBLE_BUFFER='$VULKAN_AHB_DOUBLE_BUFFER'
VULKAN_AHB_FRAME_COUNT='$VULKAN_AHB_FRAME_COUNT'
VULKAN_AHB_WIDTH='$VULKAN_AHB_WIDTH'
VULKAN_AHB_HEIGHT='$VULKAN_AHB_HEIGHT'
VULKAN_AHB_OUTPUT_SOCKET='$VULKAN_AHB_OUTPUT_SOCKET'
# These are the child-process names consumed by gamescope and the probes.
NOVA_XWAYLAND_ALLOW_LOCAL='$NOVA_XWAYLAND_ALLOW_LOCAL'
NOVA_STEAM_SKIP_INITIAL_BOOTSTRAP='$NOVA_STEAM_SKIP_INITIAL_BOOTSTRAP'
NOVA_STEAM_BOOTSTRAP_MODE='$NOVA_STEAM_BOOTSTRAP_MODE'
NOVA_STEAM_DISABLE_PRELOAD='$NOVA_STEAM_DISABLE_PRELOAD'
NOVA_STEAM_MESA_DRIVER='$NOVA_STEAM_MESA_DRIVER'
NOVA_STEAM_PRELOAD_PROFILE='$NOVA_STEAM_PRELOAD_PROFILE'
NOVA_STEAM_GALLIUM_DRIVER='$NOVA_STEAM_GALLIUM_DRIVER'
NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE='$NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE'
NOVA_STEAM_LIBGL_ALWAYS_INDIRECT='$NOVA_STEAM_LIBGL_ALWAYS_INDIRECT'
NOVA_STEAM_LP_NATIVE_VECTOR_WIDTH='$NOVA_STEAM_LP_NATIVE_VECTOR_WIDTH'
NOVA_STEAM_NO_CEF_SANDBOX='$NOVA_STEAM_NO_CEF_SANDBOX'
NOVA_STEAM_CLIENT_TIMEOUT='$NOVA_STEAM_CLIENT_TIMEOUT'
NOVA_STEAM_GAMESCOPE_TIMEOUT='$NOVA_STEAM_GAMESCOPE_TIMEOUT'
NOVA_STEAM_EXECUTABLE='$NOVA_STEAM_EXECUTABLE'
NOVA_STEAM_EXTRA_ARGS='$NOVA_STEAM_EXTRA_ARGS'
NOVA_STEAM_CLIENT_FLAGS='$NOVA_STEAM_CLIENT_FLAGS'
NOVA_HOLO_NAMESERVER='$NOVA_HOLO_NAMESERVER'
VULKAN_AHB_HANDLE_SOCKET=''
status=0

unmount_target() {
    unmount_path="\$1"
    unmount_attempt=0
    while [ "\$unmount_attempt" -lt 16 ]; do
        /system/bin/umount -l "\$unmount_path" >/dev/null 2>&1 || break
        unmount_attempt=\$((unmount_attempt + 1))
    done
}

cleanup() {
    unmount_target "\$ROOT/run/nova-lab-app"
    unmount_target "\$ROOT/linkerconfig"
    unmount_target "\$ROOT/apex"
    unmount_target "\$ROOT/system"
    unmount_target "\$ROOT/vendor"
    unmount_target "\$ROOT/sys"
    unmount_target "\$ROOT/proc"
    unmount_target "\$ROOT/dev/shm"
    unmount_target "\$ROOT/dev"
}

mount_one() {
    mount_source="\$1"
    mount_target="\$2"
    if [ "\$mount_target" = "\$ROOT/dev" ]; then
        unmount_target "\$ROOT/dev/shm"
    fi
    unmount_target "\$mount_target"
    mkdir -p "\$mount_target"
    if /system/bin/mount -o bind "\$mount_source" "\$mount_target"; then
        echo "mount.\$mount_target=pass"
    else
        echo "mount.\$mount_target=fail"
        status=1
    fi
}

mount_shm() {
    mount_target="\$ROOT/dev/shm"
    unmount_target "\$mount_target"
    mkdir -p "\$mount_target"
    if /system/bin/mount -t tmpfs -o mode=1777 tmpfs "\$mount_target"; then
        echo "mount.\$mount_target=pass"
    else
        echo "mount.\$mount_target=fail"
        status=1
    fi
}

trap cleanup EXIT
mount_one /dev "\$ROOT/dev"
mount_shm
mount_one /proc "\$ROOT/proc"
mount_one /sys "\$ROOT/sys"
mount_one /vendor "\$ROOT/vendor"
mount_one /system "\$ROOT/system"
mount_one /apex "\$ROOT/apex"
if [ -d /linkerconfig ]; then
    mount_one /linkerconfig "\$ROOT/linkerconfig"
fi
if [ -n "\$VULKAN_AHB_SOCKET_HOST_DIR" ]; then
    mount_one "\$VULKAN_AHB_SOCKET_HOST_DIR" "\$ROOT/run/nova-lab-app"
    if [ "\$status" -eq 0 ]; then
        VULKAN_AHB_HANDLE_SOCKET="/run/nova-lab-app/\$VULKAN_AHB_SOCKET_NAME"
    fi
fi

if [ -z "\$NOVA_HOLO_NAMESERVER" ] && [ -x /system/bin/ip ]; then
    NOVA_HOLO_NAMESERVER=\$(
        /system/bin/ip route show table all 2>/dev/null |
            /system/bin/grep -m 1 'default via' |
            /system/bin/sed -n 's/.*default via \([^ ]*\).*/\1/p' |
            /system/bin/head -n 1
    )
fi
if [ -n "\$NOVA_HOLO_NAMESERVER" ]; then
    mkdir -p "\$ROOT/etc"
    echo "nameserver \$NOVA_HOLO_NAMESERVER" >"\$ROOT/etc/resolv.conf"
    echo "rootfs.resolv_conf=generated:\$NOVA_HOLO_NAMESERVER"
else
    echo "rootfs.resolv_conf=unavailable"
fi
if [ ! -s "\$ROOT/etc/machine-id" ]; then
    mkdir -p "\$ROOT/etc" "\$ROOT/var/lib/dbus"
    machine_id=\$(cat /proc/sys/kernel/random/uuid 2>/dev/null | tr -d '-')
    if [ "\${#machine_id}" -ne 32 ]; then
        machine_id=0123456789abcdef0123456789abcdef
    fi
    printf '%s\\n' "\$machine_id" >"\$ROOT/etc/machine-id"
    rm -f "\$ROOT/var/lib/dbus/machine-id"
    ln -s /etc/machine-id "\$ROOT/var/lib/dbus/machine-id"
    echo "rootfs.machine_id=generated"
else
    echo "rootfs.machine_id=existing"
fi
mkdir -p "\$ROOT/opt/nova-steam"
echo "\$NOVA_STEAM_CLIENT_TIMEOUT" >"\$ROOT/opt/nova-steam/client-timeout"
echo "\$NOVA_STEAM_GAMESCOPE_TIMEOUT" >"\$ROOT/opt/nova-steam/gamescope-timeout"
echo "rootfs.steam_client_timeout=\$NOVA_STEAM_CLIENT_TIMEOUT"
echo "rootfs.gamescope_timeout=\$NOVA_STEAM_GAMESCOPE_TIMEOUT"
if [ -n "\$NOVA_STEAM_EXECUTABLE" ]; then
    echo "\$NOVA_STEAM_EXECUTABLE" >"\$ROOT/opt/nova-steam/executable"
    echo "rootfs.steam_executable=\$NOVA_STEAM_EXECUTABLE"
else
    rm -f "\$ROOT/opt/nova-steam/executable"
    echo "rootfs.steam_executable=default"
fi

if [ "\$status" -eq 0 ]; then
    run_holo_env() {
        if [ -n "\$VULKAN_ICD_FILE" ]; then
            if [ -n "\$VULKAN_AHB_HANDLE_SOCKET" ]; then
                /system/bin/chroot "\$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp VK_LOADER_DEBUG="\$VULKAN_LOADER_DEBUG" NODEVICE_SELECT="\$VULKAN_NODEVICE_SELECT" VK_ICD_FILENAMES="\$VULKAN_ICD_FILE" NOVA_AHB_HANDLE_SOCKET="\$VULKAN_AHB_HANDLE_SOCKET" NOVA_AHB_ASYNC_FENCE="\$VULKAN_AHB_ASYNC_FENCE" NOVA_AHB_DOUBLE_BUFFER="\$VULKAN_AHB_DOUBLE_BUFFER" NOVA_AHB_FRAME_COUNT="\$VULKAN_AHB_FRAME_COUNT" NOVA_AHB_WIDTH="\$VULKAN_AHB_WIDTH" NOVA_AHB_HEIGHT="\$VULKAN_AHB_HEIGHT" NOVA_AHB_OUTPUT_SOCKET="\$VULKAN_AHB_OUTPUT_SOCKET" NOVA_XWAYLAND_ALLOW_LOCAL="\$NOVA_XWAYLAND_ALLOW_LOCAL" NOVA_STEAM_SKIP_INITIAL_BOOTSTRAP="\$NOVA_STEAM_SKIP_INITIAL_BOOTSTRAP" NOVA_STEAM_BOOTSTRAP_MODE="\$NOVA_STEAM_BOOTSTRAP_MODE" NOVA_STEAM_DISABLE_PRELOAD="\$NOVA_STEAM_DISABLE_PRELOAD" NOVA_STEAM_MESA_DRIVER="\$NOVA_STEAM_MESA_DRIVER" NOVA_STEAM_PRELOAD_PROFILE="\$NOVA_STEAM_PRELOAD_PROFILE" NOVA_STEAM_GALLIUM_DRIVER="\$NOVA_STEAM_GALLIUM_DRIVER" NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE="\$NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE" NOVA_STEAM_LIBGL_ALWAYS_INDIRECT="\$NOVA_STEAM_LIBGL_ALWAYS_INDIRECT" NOVA_STEAM_LP_NATIVE_VECTOR_WIDTH="\$NOVA_STEAM_LP_NATIVE_VECTOR_WIDTH" NOVA_STEAM_NO_CEF_SANDBOX="\$NOVA_STEAM_NO_CEF_SANDBOX" NOVA_STEAM_RUNTIME_X11_FIRST="\$NOVA_STEAM_RUNTIME_X11_FIRST" NOVA_STEAM_HOLO_MESA_PRELOAD="\$NOVA_STEAM_HOLO_MESA_PRELOAD" NOVA_STEAM_EXTRA_ARGS="\$NOVA_STEAM_EXTRA_ARGS" NOVA_STEAM_CLIENT_FLAGS="\$NOVA_STEAM_CLIENT_FLAGS" "\$@"
            else
                /system/bin/chroot "\$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp VK_LOADER_DEBUG="\$VULKAN_LOADER_DEBUG" NODEVICE_SELECT="\$VULKAN_NODEVICE_SELECT" VK_ICD_FILENAMES="\$VULKAN_ICD_FILE" NOVA_AHB_ASYNC_FENCE="\$VULKAN_AHB_ASYNC_FENCE" NOVA_AHB_DOUBLE_BUFFER="\$VULKAN_AHB_DOUBLE_BUFFER" NOVA_AHB_FRAME_COUNT="\$VULKAN_AHB_FRAME_COUNT" NOVA_AHB_WIDTH="\$VULKAN_AHB_WIDTH" NOVA_AHB_HEIGHT="\$VULKAN_AHB_HEIGHT" NOVA_AHB_OUTPUT_SOCKET="\$VULKAN_AHB_OUTPUT_SOCKET" NOVA_XWAYLAND_ALLOW_LOCAL="\$NOVA_XWAYLAND_ALLOW_LOCAL" NOVA_STEAM_SKIP_INITIAL_BOOTSTRAP="\$NOVA_STEAM_SKIP_INITIAL_BOOTSTRAP" NOVA_STEAM_BOOTSTRAP_MODE="\$NOVA_STEAM_BOOTSTRAP_MODE" NOVA_STEAM_DISABLE_PRELOAD="\$NOVA_STEAM_DISABLE_PRELOAD" NOVA_STEAM_MESA_DRIVER="\$NOVA_STEAM_MESA_DRIVER" NOVA_STEAM_PRELOAD_PROFILE="\$NOVA_STEAM_PRELOAD_PROFILE" NOVA_STEAM_GALLIUM_DRIVER="\$NOVA_STEAM_GALLIUM_DRIVER" NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE="\$NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE" NOVA_STEAM_LIBGL_ALWAYS_INDIRECT="\$NOVA_STEAM_LIBGL_ALWAYS_INDIRECT" NOVA_STEAM_LP_NATIVE_VECTOR_WIDTH="\$NOVA_STEAM_LP_NATIVE_VECTOR_WIDTH" NOVA_STEAM_NO_CEF_SANDBOX="\$NOVA_STEAM_NO_CEF_SANDBOX" NOVA_STEAM_RUNTIME_X11_FIRST="\$NOVA_STEAM_RUNTIME_X11_FIRST" NOVA_STEAM_HOLO_MESA_PRELOAD="\$NOVA_STEAM_HOLO_MESA_PRELOAD" NOVA_STEAM_EXTRA_ARGS="\$NOVA_STEAM_EXTRA_ARGS" NOVA_STEAM_CLIENT_FLAGS="\$NOVA_STEAM_CLIENT_FLAGS" "\$@"
            fi
        elif [ -n "\$VULKAN_AHB_HANDLE_SOCKET" ]; then
            /system/bin/chroot "\$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp VK_LOADER_DEBUG="\$VULKAN_LOADER_DEBUG" NODEVICE_SELECT="\$VULKAN_NODEVICE_SELECT" NOVA_AHB_HANDLE_SOCKET="\$VULKAN_AHB_HANDLE_SOCKET" NOVA_AHB_ASYNC_FENCE="\$VULKAN_AHB_ASYNC_FENCE" NOVA_AHB_DOUBLE_BUFFER="\$VULKAN_AHB_DOUBLE_BUFFER" NOVA_AHB_FRAME_COUNT="\$VULKAN_AHB_FRAME_COUNT" NOVA_AHB_WIDTH="\$VULKAN_AHB_WIDTH" NOVA_AHB_HEIGHT="\$VULKAN_AHB_HEIGHT" NOVA_AHB_OUTPUT_SOCKET="\$VULKAN_AHB_OUTPUT_SOCKET" NOVA_XWAYLAND_ALLOW_LOCAL="\$NOVA_XWAYLAND_ALLOW_LOCAL" NOVA_STEAM_SKIP_INITIAL_BOOTSTRAP="\$NOVA_STEAM_SKIP_INITIAL_BOOTSTRAP" NOVA_STEAM_BOOTSTRAP_MODE="\$NOVA_STEAM_BOOTSTRAP_MODE" NOVA_STEAM_DISABLE_PRELOAD="\$NOVA_STEAM_DISABLE_PRELOAD" NOVA_STEAM_MESA_DRIVER="\$NOVA_STEAM_MESA_DRIVER" NOVA_STEAM_PRELOAD_PROFILE="\$NOVA_STEAM_PRELOAD_PROFILE" NOVA_STEAM_GALLIUM_DRIVER="\$NOVA_STEAM_GALLIUM_DRIVER" NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE="\$NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE" NOVA_STEAM_LIBGL_ALWAYS_INDIRECT="\$NOVA_STEAM_LIBGL_ALWAYS_INDIRECT" NOVA_STEAM_LP_NATIVE_VECTOR_WIDTH="\$NOVA_STEAM_LP_NATIVE_VECTOR_WIDTH" NOVA_STEAM_NO_CEF_SANDBOX="\$NOVA_STEAM_NO_CEF_SANDBOX" NOVA_STEAM_RUNTIME_X11_FIRST="\$NOVA_STEAM_RUNTIME_X11_FIRST" NOVA_STEAM_HOLO_MESA_PRELOAD="\$NOVA_STEAM_HOLO_MESA_PRELOAD" NOVA_STEAM_EXTRA_ARGS="\$NOVA_STEAM_EXTRA_ARGS" NOVA_STEAM_CLIENT_FLAGS="\$NOVA_STEAM_CLIENT_FLAGS" "\$@"
        else
            /system/bin/chroot "\$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin VK_LOADER_DEBUG="\$VULKAN_LOADER_DEBUG" NODEVICE_SELECT="\$VULKAN_NODEVICE_SELECT" NOVA_AHB_ASYNC_FENCE="\$VULKAN_AHB_ASYNC_FENCE" NOVA_AHB_DOUBLE_BUFFER="\$VULKAN_AHB_DOUBLE_BUFFER" NOVA_AHB_FRAME_COUNT="\$VULKAN_AHB_FRAME_COUNT" NOVA_AHB_WIDTH="\$VULKAN_AHB_WIDTH" NOVA_AHB_HEIGHT="\$VULKAN_AHB_HEIGHT" NOVA_AHB_OUTPUT_SOCKET="\$VULKAN_AHB_OUTPUT_SOCKET" NOVA_XWAYLAND_ALLOW_LOCAL="\$NOVA_XWAYLAND_ALLOW_LOCAL" NOVA_STEAM_SKIP_INITIAL_BOOTSTRAP="\$NOVA_STEAM_SKIP_INITIAL_BOOTSTRAP" NOVA_STEAM_BOOTSTRAP_MODE="\$NOVA_STEAM_BOOTSTRAP_MODE" NOVA_STEAM_DISABLE_PRELOAD="\$NOVA_STEAM_DISABLE_PRELOAD" NOVA_STEAM_MESA_DRIVER="\$NOVA_STEAM_MESA_DRIVER" NOVA_STEAM_PRELOAD_PROFILE="\$NOVA_STEAM_PRELOAD_PROFILE" NOVA_STEAM_GALLIUM_DRIVER="\$NOVA_STEAM_GALLIUM_DRIVER" NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE="\$NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE" NOVA_STEAM_LIBGL_ALWAYS_INDIRECT="\$NOVA_STEAM_LIBGL_ALWAYS_INDIRECT" NOVA_STEAM_LP_NATIVE_VECTOR_WIDTH="\$NOVA_STEAM_LP_NATIVE_VECTOR_WIDTH" NOVA_STEAM_NO_CEF_SANDBOX="\$NOVA_STEAM_NO_CEF_SANDBOX" NOVA_STEAM_RUNTIME_X11_FIRST="\$NOVA_STEAM_RUNTIME_X11_FIRST" NOVA_STEAM_HOLO_MESA_PRELOAD="\$NOVA_STEAM_HOLO_MESA_PRELOAD" NOVA_STEAM_EXTRA_ARGS="\$NOVA_STEAM_EXTRA_ARGS" NOVA_STEAM_CLIENT_FLAGS="\$NOVA_STEAM_CLIENT_FLAGS" "\$@"
        fi
    }

    echo "chroot.begin"
    echo "glibc.loader.begin"
    /system/bin/chroot "\$ROOT" /lib/ld-linux-aarch64.so.1 --version || status=1
    echo "glibc.loader.end"
    echo "glibc.true.begin"
    /system/bin/chroot "\$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp /usr/bin/true || status=1
    echo "glibc.true.end"
    echo "glibc.shell.begin"
    /system/bin/chroot "\$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp /usr/bin/sh -c 'echo chroot.shell=ok; /usr/bin/uname -m; /usr/bin/printf "glibc=%s\\n" "\$(/usr/bin/ldd --version 2>&1 | /usr/bin/head -n 1)"' || status=1
    echo "glibc.shell.end"
    if [ -x "\$ROOT/usr/bin/vulkaninfo" ]; then
        echo "vulkaninfo.begin"
        if [ -n "\$VULKAN_ICD_FILE" ]; then
            echo "vulkan_icd_file=\$VULKAN_ICD_FILE"
        fi
        run_holo_env /usr/bin/vulkaninfo --summary
        vulkan_status=\$?
        echo "vulkaninfo_status=\$vulkan_status"
        if [ "\$vulkan_status" -ne 0 ]; then
            status=1
        fi
        echo "vulkaninfo.end"
    else
        echo "vulkaninfo=missing"
        status=1
    fi
    if [ -n "\$VULKAN_OFFSCREEN_PROBE" ] && [ -x "\$ROOT\$VULKAN_OFFSCREEN_PROBE" ]; then
        echo "offscreen_probe.begin"
        run_holo_env "\$VULKAN_OFFSCREEN_PROBE"
        offscreen_status=\$?
        echo "offscreen_probe_status=\$offscreen_status"
        if [ "\$offscreen_status" -ne 0 ]; then
            status=1
        fi
        echo "offscreen_probe.end"
    elif [ -n "\$VULKAN_OFFSCREEN_PROBE" ]; then
        echo "offscreen_probe=missing"
        status=1
    fi
    echo "chroot.end"
else
    echo "chroot=skipped-mount-failure"
fi

exit "\$status"
EOF
    chmod 700 "$HELPER"
    /system/bin/unshare -m /system/bin/sh "$HELPER"
    status=$?
    rm -f "$HELPER"
    echo "probe_status=$status"
    exit "$status"
} >"$OUT" 2>&1

exit $?
