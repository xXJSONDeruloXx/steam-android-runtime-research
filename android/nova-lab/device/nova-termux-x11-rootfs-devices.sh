#!/system/bin/sh

set -u

ROOTFS="${1:-}"
if [ -z "$ROOTFS" ]; then
    echo "nova_rootfs_devices=fail reason=missing_rootfs" >&2
    exit 2
fi

DEVICE_DIR="$ROOTFS/dev"
if [ ! -d "$DEVICE_DIR" ]; then
    echo "nova_rootfs_devices=fail reason=missing_device_dir path=$DEVICE_DIR" >&2
    exit 1
fi

ensure_device() {
    name="$1"
    major="$2"
    minor="$3"
    path="$DEVICE_DIR/$name"
    if [ ! -c "$path" ]; then
        /system/bin/rm -f "$path" || return 1
        /system/bin/mknod "$path" c "$major" "$minor" || return 1
        /system/bin/chmod 666 "$path" || return 1
    fi
    if [ ! -c "$path" ]; then
        echo "nova_rootfs_device=fail name=$name path=$path" >&2
        return 1
    fi
    echo "nova_rootfs_device=pass name=$name path=$path"
    return 0
}

status=0
ensure_device null 1 3 || status=1
ensure_device zero 1 5 || status=1
ensure_device full 1 7 || status=1
ensure_device random 1 8 || status=1
ensure_device urandom 1 9 || status=1
ensure_device tty 5 0 || status=1

if [ "$status" -ne 0 ]; then
    echo "nova_rootfs_devices=fail root=$ROOTFS" >&2
    exit 1
fi
echo "nova_rootfs_devices=pass root=$ROOTFS"
