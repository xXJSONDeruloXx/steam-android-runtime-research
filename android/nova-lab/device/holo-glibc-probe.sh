#!/system/bin/sh

set -u

ROOT="${1:-/data/local/tmp/nova-holo-rootfs}"
OUT="${2:-/data/local/tmp/nova-holo-glibc-report.txt}"
WORK="${3:-/data/local/tmp/nova-holo-glibc-work}"
OUT_DIR="${OUT%/*}"
VULKAN_LOADER_DEBUG="${VULKAN_LOADER_DEBUG:-error}"
VULKAN_NODEVICE_SELECT="${VULKAN_NODEVICE_SELECT:-}"
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
status=0

cleanup() {
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

if [ "\$status" -eq 0 ]; then
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
        /system/bin/chroot "\$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp VK_LOADER_DEBUG="\$VULKAN_LOADER_DEBUG" NODEVICE_SELECT="\$VULKAN_NODEVICE_SELECT" /usr/bin/vulkaninfo --summary
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
