#!/system/bin/sh

set -u

SERVER_CMDLINE=termux-x11
CLIENT_TOKEN=nova-x11-animate

read_file() {
    file="$1"
    if [ -r "$file" ]; then
        /system/bin/cat "$file"
    fi
}

process_comm() {
    pid="$1"
    if [ -r "/proc/$pid/comm" ]; then
        /system/bin/cat "/proc/$pid/comm" | tr -d '\r\n'
    fi
}

process_cmdline() {
    pid="$1"
    if [ -r "/proc/$pid/cmdline" ]; then
        tr '\000' ' ' <"/proc/$pid/cmdline" | tr -d '\r\n'
    fi
}

process_parent() {
    pid="$1"
    if [ -r "/proc/$pid/status" ]; then
        /system/bin/sed -n 's/^PPid:[[:space:]]*//p' "/proc/$pid/status"
    fi
}

server_pids() {
    for proc in /proc/[0-9]*; do
        pid="${proc##*/}"
        [ "$pid" = "$$" ] && continue
        comm="$(process_comm "$pid")"
        cmdline="$(process_cmdline "$pid")"
        if [ "$comm" = "main" ] && [ "$cmdline" = "$SERVER_CMDLINE" ]; then
            echo "$pid"
        fi
    done
}

client_pids() {
    for proc in /proc/[0-9]*; do
        pid="${proc##*/}"
        [ "$pid" = "$$" ] && continue
        comm="$(process_comm "$pid")"
        case "$comm" in
            sh|su|app_process)
                continue
                ;;
        esac
        cmdline="$(process_cmdline "$pid")"
        case "$cmdline" in
            *"$CLIENT_TOKEN"*)
                echo "$pid"
                ;;
        esac
    done
}

kill_pid() {
    pid="$1"
    signal="${2:-}"
    if [ -n "$signal" ]; then
        /system/bin/kill "$signal" "$pid" 2>/dev/null || true
    else
        /system/bin/kill "$pid" 2>/dev/null || true
    fi
}

kill_servers() {
    signal="${1:-}"
    for pid in $(server_pids); do
        kill_pid "$pid" "$signal"
    done
}

kill_clients() {
    signal="${1:-}"
    for pid in $(client_pids); do
        kill_pid "$pid" "$signal"
    done
}

verify_absent() {
    pids="$1"
    if [ -n "$pids" ]; then
        return 1
    fi
    return 0
}

verify_mode() {
    state_dir="$1"
    socket="$2"
    server_state=absent
    client_state=absent
    parent_state=absent
    socket_state=absent
    if ! verify_absent "$(server_pids)"; then
        server_state=present
    fi
    if ! verify_absent "$(client_pids)"; then
        client_state=present
    fi
    parent_pid="$(read_file "$state_dir/server-parent.pid")"
    if [ -n "$parent_pid" ] && [ "$parent_pid" != "1" ] && [ -e "/proc/$parent_pid" ]; then
        parent_state=present
    fi
    if [ -S "$socket" ]; then
        socket_state=present
    fi
    echo "server_state=$server_state client_state=$client_state server_parent_state=$parent_state socket_state=$socket_state"
    if [ "$server_state" = absent ] && [ "$client_state" = absent ] &&
        [ "$parent_state" = absent ] && [ "$socket_state" = absent ]; then
        return 0
    fi
    return 1
}

if [ "${1:-}" = "verify" ]; then
    shift
    state_dir="${1:-}"
    SERVER_CMDLINE="$(read_file "$state_dir/server-token")"
    CLIENT_TOKEN="$(read_file "$state_dir/client-token")"
    [ -n "$SERVER_CMDLINE" ] || SERVER_CMDLINE=termux-x11
    [ -n "$CLIENT_TOKEN" ] || CLIENT_TOKEN=nova-x11-animate
    verify_mode "$state_dir" "$(read_file "$state_dir/socket.path")"
    exit $?
fi

if [ "${1:-}" != "cleanup" ]; then
    echo "x11_cleanup_error=unknown_mode" >&2
    exit 2
fi
shift

state_dir="${1:-}"
private_helper="${2:-}"
client="$(read_file "$state_dir/client.path")"
capture="$(read_file "$state_dir/capture.path")"
ppm="$(read_file "$state_dir/ppm.path")"
socket="$(read_file "$state_dir/socket.path")"
lock="$(read_file "$state_dir/lock.path")"
SERVER_CMDLINE="$(read_file "$state_dir/server-token")"
CLIENT_TOKEN="$(read_file "$state_dir/client-token")"
[ -n "$SERVER_CMDLINE" ] || SERVER_CMDLINE=termux-x11
[ -n "$CLIENT_TOKEN" ] || CLIENT_TOKEN=nova-x11-animate
if [ -z "$state_dir" ] || [ -z "$private_helper" ]; then
    echo "x11_cleanup_error=missing_arguments" >&2
    exit 2
fi

server_pid="$(read_file "$state_dir/server.pid")"
server_parent_pid=
if [ -n "$server_pid" ] && [ -e "/proc/$server_pid" ]; then
    server_pid_comm="$(process_comm "$server_pid")"
    server_pid_cmdline="$(process_cmdline "$server_pid")"
    if [ "$server_pid_comm" = "main" ] && [ "$server_pid_cmdline" = "$SERVER_CMDLINE" ]; then
        server_parent_pid="$(process_parent "$server_pid")"
    fi
fi
if [ -z "$server_parent_pid" ]; then
    for live_server_pid in $(server_pids); do
        server_parent_pid="$(process_parent "$live_server_pid")"
        break
    done
fi
if [ -n "$server_parent_pid" ] && [ "$server_parent_pid" != "1" ]; then
    echo "$server_parent_pid" >"$state_dir/server-parent.pid"
else
    /system/bin/rm -f "$state_dir/server-parent.pid"
fi

echo "pre_cleanup_server_pids=$(server_pids | tr '\n' ',')"
echo "pre_cleanup_client_pids=$(client_pids | tr '\n' ',')"
if [ -S "$socket" ]; then
    echo "pre_cleanup_socket_state=present" >"$state_dir/cleanup-state"
else
    echo "pre_cleanup_socket_state=absent" >"$state_dir/cleanup-state"
fi

kill_clients
kill_servers
if [ -n "$server_parent_pid" ]; then
    parent_comm="$(process_comm "$server_parent_pid")"
    parent_cmdline=""
    if [ -r "/proc/$server_parent_pid/cmdline" ]; then
        parent_cmdline="$(tr '\000' ' ' <"/proc/$server_parent_pid/cmdline")"
    fi
    case "$parent_cmdline" in
        *"$SERVER_CMDLINE"*)
            if [ "$parent_comm" = "sh" ] || [ "$parent_comm" = "app_process" ]; then
                /system/bin/kill "$server_parent_pid" 2>/dev/null || true
            fi
            ;;
    esac
fi

/system/bin/sleep 0.2
kill_clients -9
kill_servers -9
if [ -n "$server_parent_pid" ] && [ -e "/proc/$server_parent_pid" ]; then
    parent_comm="$(process_comm "$server_parent_pid")"
    if [ "$parent_comm" = "sh" ] || [ "$parent_comm" = "app_process" ]; then
        /system/bin/kill -9 "$server_parent_pid" 2>/dev/null || true
    fi
fi

/system/bin/am broadcast -a com.termux.x11.ACTION_STOP -p com.termux.x11 >/dev/null 2>&1 || true
/system/bin/am force-stop com.termux.x11 >/dev/null 2>&1 || true

namespace_status=0
if [ ! -x "$private_helper" ]; then
    echo "namespace_cleanup=missing_helper" >&2
    namespace_status=1
else
    "$private_helper" remove "$client" "$capture" "$ppm" "$socket" "$lock" || namespace_status=$?
fi

if [ "$namespace_status" -ne 0 ]; then
    echo "namespace_cleanup=fail" >&2
    exit "$namespace_status"
fi
echo "namespace_cleanup=pass"
if verify_mode "$state_dir" "$socket"; then
    echo "nova_x11_cleanup=pass"
    exit 0
fi
echo "nova_x11_cleanup=fail" >&2
exit 1
