#!/system/bin/sh

set -u

if [ "${1:-}" != "--child" ]; then
    exec /system/bin/unshare -m /system/bin/sh "$0" --child "$@"
fi
shift

mode="${1:-}"
shift 2>/dev/null || true

case "$mode" in
    chroot)
        root="${1:-}"
        shift 2>/dev/null || true
        if [ -z "$root" ] || [ "$#" -eq 0 ]; then
            echo "x11_namespace_error=chroot_arguments" >&2
            exit 2
        fi
        exec /system/bin/chroot "$root" "$@"
        ;;
    chroot-dev)
        mount_private="${1:-}"
        root="${2:-}"
        shift 2 2>/dev/null || true
        if [ -z "$mount_private" ] || [ -z "$root" ] || [ "$#" -eq 0 ]; then
            echo "x11_namespace_error=chroot_dev_arguments" >&2
            exit 2
        fi
        if ! "$mount_private" /; then
            echo "x11_namespace_error=mount_private" >&2
            exit 1
        fi
        if ! /system/bin/mount -o bind /dev "$root/dev"; then
            echo "x11_namespace_error=bind_dev" >&2
            exit 1
        fi
        mounted=1
        shm_mounted=0
        proc_mounted=0
        cleanup_mount() {
            if [ "$proc_mounted" -eq 1 ]; then
                /system/bin/umount -l "$root/proc" >/dev/null 2>&1 || true
                proc_mounted=0
            fi
            if [ "$shm_mounted" -eq 1 ]; then
                /system/bin/umount -l "$root/dev/shm" >/dev/null 2>&1 || true
                shm_mounted=0
            fi
            if [ "$mounted" -eq 1 ]; then
                /system/bin/umount -l "$root/dev" >/dev/null 2>&1 || true
                mounted=0
            fi
        }
        trap cleanup_mount EXIT INT TERM
        if ! /system/bin/mount -t tmpfs -o mode=1777 tmpfs "$root/dev/shm"; then
            echo "x11_namespace_error=mount_shm" >&2
            exit 1
        fi
        shm_mounted=1
        if ! /system/bin/mount -o bind /proc "$root/proc"; then
            echo "x11_namespace_error=bind_proc" >&2
            exit 1
        fi
        proc_mounted=1
        /system/bin/chroot "$root" "$@"
        status=$?
        trap - EXIT INT TERM
        cleanup_mount
        exit "$status"
        ;;
    remove)
        status=0
        for path in "$@"; do
            /system/bin/rm -f "$path" || status=$?
        done
        exit "$status"
        ;;
    *)
        echo "x11_namespace_error=unknown_mode:$mode" >&2
        exit 2
        ;;
esac
