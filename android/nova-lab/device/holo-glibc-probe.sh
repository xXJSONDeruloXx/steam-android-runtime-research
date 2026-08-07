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
mkdir -p "$OUT_DIR" "$WORK"

{
    echo "probe_version=1"
    echo "rootfs=$ROOT"
    echo "timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "host_id=$(/system/bin/id)"
    echo "host_kernel=$(/system/bin/uname -a 2>&1)"

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
VULKAN_AHB_HANDLE_SOCKET=''
status=0

cleanup() {
    /system/bin/umount -l "\$ROOT/run/nova-lab-app" >/dev/null 2>&1 || true
    /system/bin/umount -l "\$ROOT/linkerconfig" >/dev/null 2>&1 || true
    /system/bin/umount -l "\$ROOT/apex" >/dev/null 2>&1 || true
    /system/bin/umount -l "\$ROOT/system" >/dev/null 2>&1 || true
    /system/bin/umount -l "\$ROOT/vendor" >/dev/null 2>&1 || true
    /system/bin/umount -l "\$ROOT/sys" >/dev/null 2>&1 || true
    /system/bin/umount -l "\$ROOT/proc" >/dev/null 2>&1 || true
    /system/bin/umount -l "\$ROOT/dev" >/dev/null 2>&1 || true
}

mount_one() {
    source="\$1"
    target="\$2"
    mkdir -p "\$target"
    if /system/bin/mount -o bind "\$source" "\$target"; then
        echo "mount.\$target=pass"
    else
        echo "mount.\$target=fail"
        status=1
    fi
}

trap cleanup EXIT
mount_one /dev "\$ROOT/dev"
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

if [ "\$status" -eq 0 ]; then
    run_holo_env() {
        if [ -n "\$VULKAN_ICD_FILE" ]; then
            if [ -n "\$VULKAN_AHB_HANDLE_SOCKET" ]; then
                /system/bin/chroot "\$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp VK_LOADER_DEBUG="\$VULKAN_LOADER_DEBUG" NODEVICE_SELECT="\$VULKAN_NODEVICE_SELECT" VK_ICD_FILENAMES="\$VULKAN_ICD_FILE" NOVA_AHB_HANDLE_SOCKET="\$VULKAN_AHB_HANDLE_SOCKET" "\$@"
            else
                /system/bin/chroot "\$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp VK_LOADER_DEBUG="\$VULKAN_LOADER_DEBUG" NODEVICE_SELECT="\$VULKAN_NODEVICE_SELECT" VK_ICD_FILENAMES="\$VULKAN_ICD_FILE" "\$@"
            fi
        elif [ -n "\$VULKAN_AHB_HANDLE_SOCKET" ]; then
            /system/bin/chroot "\$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp VK_LOADER_DEBUG="\$VULKAN_LOADER_DEBUG" NODEVICE_SELECT="\$VULKAN_NODEVICE_SELECT" NOVA_AHB_HANDLE_SOCKET="\$VULKAN_AHB_HANDLE_SOCKET" "\$@"
        else
            /system/bin/chroot "\$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp VK_LOADER_DEBUG="\$VULKAN_LOADER_DEBUG" NODEVICE_SELECT="\$VULKAN_NODEVICE_SELECT" "\$@"
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
