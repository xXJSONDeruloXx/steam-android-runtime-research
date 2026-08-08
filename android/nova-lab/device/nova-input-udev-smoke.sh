#!/system/bin/sh

set -u

ROOT="${1:-/data/local/tmp/nova-holo-rootfs}"
HELPER="${2:-/opt/nova-kgsl-driver/nova-uinput-gamepad-relay}"
PROBE="${3:-/opt/nova-kgsl-driver/nova-input-udev-probe}"
SOURCE="${4:-/dev/input/event7}"
RELAY_TIMEOUT="${5:-10000}"
OUT="${6:-/data/local/tmp/nova-input-udev-report.txt}"
WORK="${7:-/data/local/tmp/nova-input-udev-work}"
helper_pid=
status=0

mkdir -p "${OUT%/*}" "$WORK" "$ROOT/tmp"

cleanup() {
    if [ -n "$helper_pid" ]; then
        /system/bin/kill "$helper_pid" >/dev/null 2>&1 || true
        wait "$helper_pid" >/dev/null 2>&1 || true
    fi
    /system/bin/umount -l "$ROOT/proc" >/dev/null 2>&1 || true
    /system/bin/umount -l "$ROOT/sys" >/dev/null 2>&1 || true
    /system/bin/umount -l "$ROOT/dev" >/dev/null 2>&1 || true
}

mount_one() {
    source="$1"
    target="$2"
    mkdir -p "$target"
    /system/bin/mount -o bind "$source" "$target" >/dev/null 2>&1 || true
}

trap cleanup EXIT
mount_one /dev "$ROOT/dev"
mount_one /sys "$ROOT/sys"
mount_one /proc "$ROOT/proc"

HELPER_LOG="$WORK/helper.log"
PROBE_LOG="$WORK/probe.log"
/system/bin/chroot "$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp \
    "$HELPER" "$SOURCE" "$RELAY_TIMEOUT" none >"$HELPER_LOG" 2>&1 &
helper_pid=$!

virtual_path=
attempt=0
while [ "$attempt" -lt 50 ]; do
    virtual_path=$(sed -n 's/^uinput_device=//p' "$HELPER_LOG")
    if [ -n "$virtual_path" ] && [ -e "$ROOT$virtual_path" ]; then
        break
    fi
    /system/bin/sleep 0.1
    attempt=$((attempt + 1))
done

if [ -z "$virtual_path" ] || [ ! -e "$ROOT$virtual_path" ]; then
    echo "udev_smoke_error=virtual_device_timeout" >"$OUT"
    status=1
else
    /system/bin/chroot "$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp \
        "$PROBE" "Nova Virtual Xbox Controller" "$virtual_path" >"$PROBE_LOG" 2>&1
    probe_status=$?
    {
        echo "udev_smoke_source=$SOURCE"
        echo "udev_smoke_virtual_device=$virtual_path"
        echo "udev_smoke_helper_begin"
        cat "$HELPER_LOG"
        echo "udev_smoke_helper_end"
        echo "udev_smoke_probe_begin"
        cat "$PROBE_LOG"
        echo "udev_smoke_probe_end"
        echo "udev_smoke_probe_status=$probe_status"
    } >"$OUT"
    status=$probe_status
fi

exit "$status"
