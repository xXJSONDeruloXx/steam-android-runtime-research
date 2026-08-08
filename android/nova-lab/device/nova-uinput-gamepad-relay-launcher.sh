#!/system/bin/sh

set -u

if [ "${1:-}" = "--child" ]; then
    child=1
    shift
else
    child=0
fi

ROOT="${1:-}"
HELPER="${2:-}"
SOURCE="${3:-/dev/input/event7}"
TIMEOUT="${4:-10000}"
MODE="${5:-self-test}"
MOUNT_PRIVATE_HELPER="${NOVA_RELAY_MOUNT_PRIVATE_HELPER:-/data/local/tmp/nova-mount-private}"
shift 5 2>/dev/null || true

if [ -z "$ROOT" ] || [ -z "$HELPER" ]; then
    echo "relay_launcher_error=missing_arguments" >&2
    exit 2
fi

if [ "$child" -eq 0 ]; then
    exec /system/bin/unshare -m /system/bin/sh "$0" --child \
        "$ROOT" "$HELPER" "$SOURCE" "$TIMEOUT" "$MODE" "$@"
fi

if [ ! -x "$MOUNT_PRIVATE_HELPER" ] || \
    ! "$MOUNT_PRIVATE_HELPER" / >/dev/null 2>&1; then
    echo "relay_mount_propagation=private-fail" >&2
    exit 1
fi
echo "relay_mount_propagation=private"

for mount_target in "$ROOT/dev" "$ROOT/sys" "$ROOT/proc"; do
    mkdir -p "$mount_target"
done
if ! /system/bin/mount -o bind /dev "$ROOT/dev" >/dev/null 2>&1; then
    echo "relay_mount_dev=fail" >&2
    exit 1
fi
echo "relay_mount_dev=pass"
if ! /system/bin/mount -o bind /sys "$ROOT/sys" >/dev/null 2>&1; then
    echo "relay_mount_sys=fail" >&2
    exit 1
fi
echo "relay_mount_sys=pass"
if ! /system/bin/mount -o bind /proc "$ROOT/proc" >/dev/null 2>&1; then
    echo "relay_mount_proc=fail" >&2
    exit 1
fi
echo "relay_mount_proc=pass"

exec /system/bin/chroot "$ROOT" /usr/bin/env -i \
    PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp \
    "$HELPER" "$SOURCE" "$TIMEOUT" "$MODE" "$@"
