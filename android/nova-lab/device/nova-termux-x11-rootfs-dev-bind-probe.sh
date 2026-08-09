#!/system/bin/sh

set -u

ROOTFS="${1:-}"
MOUNT_PRIVATE="${2:-}"
mounted=0

if [ -z "$ROOTFS" ] || [ -z "$MOUNT_PRIVATE" ]; then
    echo "nova_x11_dev_bind_probe=fail reason=missing_arguments" >&2
    exit 2
fi

cleanup() {
    if [ "$mounted" -eq 1 ]; then
        /system/bin/umount -l "$ROOTFS/dev" >/dev/null 2>&1 || true
        mounted=0
    fi
}

if [ "${1:-}" != "--child" ]; then
    exec /system/bin/unshare -m /system/bin/sh "$0" --child "$@"
fi
shift
ROOTFS="${1:-}"
MOUNT_PRIVATE="${2:-}"
trap cleanup EXIT INT TERM

if ! "$MOUNT_PRIVATE" /; then
    echo "nova_x11_dev_bind_probe=fail reason=private_mount_setup" >&2
    exit 1
fi
echo "nova_mount_propagation=private"

if ! /system/bin/mount -o bind /dev "$ROOTFS/dev"; then
    echo "nova_x11_dev_bind_probe=fail reason=bind_dev" >&2
    exit 1
fi
mounted=1
echo "nova_mount_dev=pass source=/dev target=$ROOTFS/dev"
/system/bin/ls -lZ "$ROOTFS/dev/null" "$ROOTFS/dev/urandom"

probe_output=$(/system/bin/chroot "$ROOTFS" /usr/bin/setpriv \
    --reuid=501 --regid=20 --clear-groups \
    /bin/sh -c 'exec 3</dev/urandom; exec 4>/dev/null; echo device_open=pass' 2>&1)
probe_status=$?
echo "$probe_output"
if [ "$probe_status" -ne 0 ] || ! printf '%s\n' "$probe_output" | /system/bin/grep -q 'device_open=pass'; then
    echo "nova_x11_dev_bind_probe=fail reason=uid501_device_open status=$probe_status" >&2
    exit 1
fi

if ! /system/bin/umount -l "$ROOTFS/dev"; then
    echo "nova_x11_dev_bind_probe=fail reason=unbind_dev" >&2
    mounted=0
    exit 1
fi
mounted=0
echo "nova_x11_dev_bind_probe=pass"
exit 0
