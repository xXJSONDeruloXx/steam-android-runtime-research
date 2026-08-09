#!/system/bin/sh

set -u

private_helper="${1:-}"
stdout_path="${2:-}"
stderr_path="${3:-}"
shift 3 2>/dev/null || true
namespace_mode="${1:-}"
shift 2>/dev/null || true

if [ -z "$private_helper" ] || [ -z "$stdout_path" ] || [ -z "$stderr_path" ] || \
    [ -z "$namespace_mode" ] || [ "$#" -eq 0 ]; then
    echo "x11_client_launcher_error=missing_arguments" >&2
    exit 2
fi

case "$namespace_mode" in
    chroot|chroot-dev)
        ;;
    *)
        echo "x11_client_launcher_error=invalid_namespace_mode:$namespace_mode" >&2
        exit 2
        ;;
esac

exec "$private_helper" "$namespace_mode" "$@" >"$stdout_path" 2>"$stderr_path"
