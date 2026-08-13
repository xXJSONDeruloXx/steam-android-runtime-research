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
        root_bind_enabled="${NOVA_X11_BIND_ROOT_MOUNT:-0}"
        case "$root_bind_enabled" in
            0|1)
                ;;
            *)
                echo "x11_namespace_error=invalid_root_bind:$root_bind_enabled" >&2
                exit 2
                ;;
        esac
        root_proxy_enabled="${NOVA_X11_ROOT_PROXY:-0}"
        case "$root_proxy_enabled" in
            0|1)
                ;;
            *)
                echo "x11_namespace_error=invalid_root_proxy:$root_proxy_enabled" >&2
                exit 2
                ;;
        esac
        if ! "$mount_private" /; then
            echo "x11_namespace_error=mount_private" >&2
            exit 1
        fi
        root_bind_mounted=0
        root_proxy_pid=
        root_proxy_socket=/tmp/nova-root-bwrap.sock
        if [ "$root_bind_enabled" -eq 1 ]; then
            if ! /system/bin/mount -o bind "$root" "$root"; then
                echo "x11_namespace_error=bind_root" >&2
                exit 1
            fi
            root_bind_mounted=1
            echo "x11_namespace_root_bind=pass root=$root"
        fi
        if ! /system/bin/mount -o bind /dev "$root/dev"; then
            if [ "$root_bind_mounted" -eq 1 ]; then
                /system/bin/umount -l "$root" >/dev/null 2>&1 || true
            fi
            echo "x11_namespace_error=bind_dev" >&2
            exit 1
        fi
        mounted=1
        shm_mounted=0
        shm_dir_created=0
        input_mounted=0
        proc_mounted=0
        runtime4_mounted=0
        runtime4_shadow="${NOVA_X11_RUNTIME4_SHADOW:-}"
        runtime4_guest="${NOVA_X11_RUNTIME4_GUEST:-/opt/nova-steam/home/.local/share/Steam/steamapps/common/SteamLinuxRuntime_4-arm64}"
        cleanup_mount() {
            if [ "$runtime4_mounted" -eq 1 ]; then
                /system/bin/umount -l "$root$runtime4_guest" >/dev/null 2>&1 || true
                runtime4_mounted=0
            fi
            if [ "$proc_mounted" -eq 1 ]; then
                /system/bin/umount -l "$root/proc" >/dev/null 2>&1 || true
                proc_mounted=0
            fi
            if [ "$input_mounted" -eq 1 ]; then
                /system/bin/umount -l "$root/dev/input" >/dev/null 2>&1 || true
                input_mounted=0
            fi
            if [ "$shm_mounted" -eq 1 ]; then
                /system/bin/umount -l "$root/dev/shm" >/dev/null 2>&1 || true
                shm_mounted=0
            fi
            if [ "$shm_dir_created" -eq 1 ]; then
                /system/bin/rmdir "$root/dev/shm" >/dev/null 2>&1 || true
                shm_dir_created=0
            fi
            if [ "$mounted" -eq 1 ]; then
                /system/bin/umount -l "$root/dev" >/dev/null 2>&1 || true
                mounted=0
            fi
            if [ -n "$root_proxy_pid" ]; then
                /system/bin/kill -TERM "$root_proxy_pid" >/dev/null 2>&1 || true
                /system/bin/wait "$root_proxy_pid" >/dev/null 2>&1 || true
                root_proxy_pid=
            fi
            if [ "$root_bind_mounted" -eq 1 ]; then
                /system/bin/umount -l "$root" >/dev/null 2>&1 || true
                root_bind_mounted=0
            fi
        }
        trap cleanup_mount EXIT INT TERM
        if [ ! -d "$root/dev/shm" ]; then
            if ! /system/bin/mkdir -p "$root/dev/shm"; then
                echo "x11_namespace_error=mkdir_shm" >&2
                exit 1
            fi
            shm_dir_created=1
        fi
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
        allow_input_events="${NOVA_X11_ALLOW_INPUT_EVENTS:-}"
        hide_input_events="${NOVA_X11_HIDE_INPUT_EVENTS:-}"
        if [ -n "$allow_input_events" ] || [ -n "$hide_input_events" ]; then
            if ! /system/bin/mount -t tmpfs -o mode=1777 tmpfs "$root/dev/input"; then
                echo "x11_namespace_error=mount_input" >&2
                exit 1
            fi
            input_mounted=1
            input_index=0
            while [ "$input_index" -lt 64 ]; do
                hidden=0
                case ",$allow_input_events," in
                    *,"$input_index",*)
                        hidden=0
                        ;;
                    *)
                        hidden=1
                        ;;
                esac
                case ",$hide_input_events," in
                    *,"$input_index",*)
                        hidden=1
                        ;;
                esac
                if [ "$hidden" -eq 0 ]; then
                    input_node="$root/dev/input/event$input_index"
                    if ! /system/bin/mknod "$input_node" c 13 $((64 + input_index)) ||
                        ! /system/bin/chmod 0666 "$input_node"; then
                        echo "x11_namespace_error=mknod_input_event$input_index" >&2
                        exit 1
                    fi
                fi
                input_index=$((input_index + 1))
            done
            echo "x11_namespace_input=pass allowed_events=$allow_input_events hidden_events=$hide_input_events"
        fi
        if [ -n "$runtime4_shadow" ]; then
            case "$runtime4_shadow:$runtime4_guest" in
                /*:/*)
                    ;;
                *)
                    echo "x11_namespace_error=runtime4_path" >&2
                    exit 1
                    ;;
            esac
            runtime4_shadow_host="$root$runtime4_shadow"
            if [ ! -d "$runtime4_shadow_host" ] || [ ! -d "$root$runtime4_guest" ]; then
                echo "x11_namespace_error=runtime4_path_missing" >&2
                exit 1
            fi
            if ! /system/bin/mount -o bind "$runtime4_shadow_host" "$root$runtime4_guest"; then
                echo "x11_namespace_error=bind_runtime4" >&2
                exit 1
            fi
            runtime4_mounted=1
            echo "x11_namespace_runtime4=pass shadow=$runtime4_shadow guest=$runtime4_guest"
        fi
        if [ "$root_proxy_enabled" -eq 1 ]; then
            root_proxy="$root/opt/nova-kgsl-driver/nova-runtime4-bwrap-proxy"
            if [ ! -x "$root_proxy" ]; then
                echo "x11_namespace_error=missing_root_proxy path=$root_proxy" >&2
                exit 1
            fi
            /system/bin/rm -f "$root$root_proxy_socket"
            "$root_proxy" "$root" "$root_proxy_socket" >"$root/tmp/nova-root-bwrap-proxy.log" 2>&1 &
            root_proxy_pid=$!
            proxy_attempt=0
            while [ "$proxy_attempt" -lt 50 ]; do
                if [ -S "$root$root_proxy_socket" ]; then
                    break
                fi
                if ! /system/bin/kill -0 "$root_proxy_pid" 2>/dev/null; then
                    break
                fi
                /system/bin/sleep 0.1
                proxy_attempt=$((proxy_attempt + 1))
            done
            if [ ! -S "$root$root_proxy_socket" ]; then
                echo "x11_namespace_error=root_proxy_not_ready" >&2
                exit 1
            fi
            echo "x11_namespace_root_proxy=pass socket=$root_proxy_socket"
        fi
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
