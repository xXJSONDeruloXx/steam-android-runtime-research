#!/system/bin/sh

set -u

ROOT="${1:-/data/local/tmp/nova-holo-rootfs}"
OUT="${2:-/data/local/tmp/nova-steam-input-fd-report.txt}"
TIMEOUT="${3:-90}"
TARGET_NAME="${4:-Nova Virtual Xbox Controller}"
status=1
attempt=0

mkdir -p "${OUT%/*}"
{
    echo "steam_input_fd_probe_begin"
    echo "steam_input_fd_root=$ROOT"
    echo "steam_input_fd_target_name=$TARGET_NAME"
    echo "steam_input_fd_timeout=$TIMEOUT"

    while [ "$attempt" -lt "$TIMEOUT" ]; do
        for name_path in /sys/class/input/event*/device/name; do
            [ -r "$name_path" ] || continue
            name=$(cat "$name_path" 2>/dev/null || true)
            [ "$name" = "$TARGET_NAME" ] || continue
            event_dir=${name_path%/device/name}
            event_name=${event_dir##*/}
            target="$ROOT/dev/input/$event_name"
            echo "steam_input_fd_target=$target"
            for pid in $(pidof steam steamwebhelper 2>/dev/null); do
                for fd in /proc/$pid/fd/*; do
                    link=$(readlink "$fd" 2>/dev/null || true)
                    if [ "$link" = "$target" ]; then
                        process_name=$(cat "/proc/$pid/comm" 2>/dev/null || true)
                        process_exe=$(readlink "/proc/$pid/exe" 2>/dev/null || true)
                        echo "steam_input_process pid=$pid name=$process_name exe=$process_exe fd=$fd target=$link"
                        echo "steam_input_fd=pass"
                        echo "steam_input_fd_probe=pass"
                        status=0
                        break 3
                    fi
                done
            done
        done
        if [ "$status" -eq 0 ]; then
            break
        fi
        /system/bin/sleep 1
        attempt=$((attempt + 1))
    done

    if [ "$status" -ne 0 ]; then
        echo "steam_input_fd=missing"
        echo "steam_input_fd_probe=fail"
    fi
    echo "steam_input_fd_probe_end"
} >"$OUT"

cat "$OUT"
exit "$status"
