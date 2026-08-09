#!/system/bin/sh

set -u

private_helper="${1:-}"
stdout_path="${2:-}"
stderr_path="${3:-}"
shift 3 2>/dev/null || true

if [ -z "$private_helper" ] || [ -z "$stdout_path" ] || [ -z "$stderr_path" ] || [ "$#" -eq 0 ]; then
    echo "x11_client_launcher_error=missing_arguments" >&2
    exit 2
fi

exec "$private_helper" chroot "$@" >"$stdout_path" 2>"$stderr_path"
