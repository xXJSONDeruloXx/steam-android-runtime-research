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
