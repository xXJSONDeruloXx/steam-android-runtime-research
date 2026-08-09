#!/bin/sh

set -u

RUN_ID="${1:-}"
DURATION_SECONDS="${2:-45}"
INTERVAL_SECONDS="${3:-5}"
STEAM_ROOT=/opt/nova-steam/home/.local/share/Steam
SELF_PID=$$

case "$RUN_ID" in
    ''|*[!A-Za-z0-9._-]*)
        echo "network_observer=fail reason=invalid_run_id" >&2
        exit 2
        ;;
esac
case "$DURATION_SECONDS:$INTERVAL_SECONDS" in
    ''|*[!0-9:]*|*:*:*)
        echo "network_observer=fail reason=invalid_duration_or_interval" >&2
        exit 2
        ;;
esac
if [ "$DURATION_SECONDS" -lt 1 ] || [ "$INTERVAL_SECONDS" -lt 1 ]; then
    echo "network_observer=fail reason=duration_or_interval_below_one" >&2
    exit 2
fi

timestamp() {
    /bin/date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown
}

section() {
    echo
    echo "[$1]"
}

run_command() {
    label="$1"
    shift
    echo "command=$label"
    "$@" 2>&1
    status=$?
    echo "command_status=$status label=$label"
}

command_path() {
    name="$1"
    if command -v "$name" >/dev/null 2>&1; then
        command -v "$name"
    else
        echo absent
    fi
}

process_snapshot() {
    section process_snapshot
    ps_path=$(command_path ps)
    echo "ps=$ps_path"
    if [ "$ps_path" != absent ]; then
        "$ps_path" -eo pid,ppid,user,stat,comm,args 2>&1 ||
            "$ps_path" auxww 2>&1 || true
    fi

    if [ "$ps_path" = absent ]; then
        return
    fi

    pids=$(
        "$ps_path" -eo pid,args 2>/dev/null |
            /usr/bin/awk -v self="$SELF_PID" '
                NR > 1 && $1 != self &&
                ($0 ~ /steam/ || $0 ~ /webhelper/ || $0 ~ /steamui/) &&
                $0 !~ /awk/ && $0 !~ /network-observer/ { print $1 }
            ' | sort -n -u
    )
    for pid in $pids; do
        case "$pid" in
            ''|*[!0-9]*)
                continue
                ;;
        esac
        echo "process_pid=$pid"
        if [ -r "/proc/$pid/cmdline" ]; then
            printf 'cmdline='
            /bin/cat "/proc/$pid/cmdline" 2>/dev/null | tr '\000' ' '
            echo
        fi
        if command -v readlink >/dev/null 2>&1; then
            echo "cwd=$(readlink "/proc/$pid/cwd" 2>/dev/null || echo unreadable)"
            echo "root=$(readlink "/proc/$pid/root" 2>/dev/null || echo unreadable)"
            echo "exe=$(readlink "/proc/$pid/exe" 2>/dev/null || echo unreadable)"
        fi
        for proc_file in status net/route net/tcp net/tcp6 net/unix; do
            if [ -r "/proc/$pid/$proc_file" ]; then
                echo "proc_file=$proc_file"
                /bin/cat "/proc/$pid/$proc_file" 2>&1 || true
            else
                echo "proc_file=$proc_file status=absent_or_unreadable"
            fi
        done
        if [ -d "/proc/$pid/fd" ]; then
            echo "fd_socket_targets="
            /bin/ls -l "/proc/$pid/fd" 2>/dev/null |
                /usr/bin/grep -E 'socket:|pipe:|steam|webhelper|dbus|NetworkManager' || true
        fi
    done
}

socket_snapshot() {
    section socket_snapshot
    ss_path=$(command_path ss)
    echo "ss=$ss_path"
    if [ "$ss_path" != absent ]; then
        run_command ss_tcp_listeners "$ss_path" -H -lntup
        run_command ss_unix "$ss_path" -x -a
    fi
    netstat_path=$(command_path netstat)
    echo "netstat=$netstat_path"
    if [ "$netstat_path" != absent ]; then
        run_command netstat_tcp "$netstat_path" -anpt
        run_command netstat_unix "$netstat_path" -anxp
    fi
}

service_snapshot() {
    section local_service_endpoints
    for path in \
        /run/dbus/system_bus_socket \
        /var/run/dbus/system_bus_socket \
        /run/dbus/user_bus_socket \
        /var/run/dbus/user_bus_socket \
        /run/NetworkManager/private \
        /var/run/NetworkManager/private \
        /run/systemd/resolve/stub-resolv.conf \
        /var/run/nscd/socket; do
        if [ -e "$path" ]; then
            ls -ld "$path" 2>&1 || true
        else
            echo "absent=$path"
        fi
    done
    for service in dbus-daemon NetworkManager nmcli; do
        echo "command=$service path=$(command_path "$service")"
    done
    nmcli_path=$(command_path nmcli)
    if [ "$nmcli_path" != absent ]; then
        run_command nmcli_general "$nmcli_path" general status
    fi
}

network_snapshot() {
    sample="$1"
    echo "network_sample=$sample"
    echo "network_sample_timestamp=$(timestamp)"
    section identity
    run_command id /usr/bin/id
    echo "hostname=$(hostname 2>/dev/null || echo unknown)"

    section resolver_files
    run_command resolv_conf /bin/cat /etc/resolv.conf
    run_command nsswitch_conf /bin/cat /etc/nsswitch.conf

    section interface_and_routes
    ip_path=$(command_path ip)
    echo "ip=$ip_path"
    if [ "$ip_path" != absent ]; then
        run_command ip_addr "$ip_path" addr
        run_command ip_route "$ip_path" route
        run_command ip_rule "$ip_path" rule
    fi
    run_command proc_route /bin/cat /proc/net/route
    run_command proc_tcp /bin/cat /proc/net/tcp
    run_command proc_tcp6 /bin/cat /proc/net/tcp6
    run_command proc_unix /bin/cat /proc/net/unix

    section resolver_and_https
    getent_path=$(command_path getent)
    echo "getent=$getent_path"
    if [ "$getent_path" != absent ]; then
        run_command getent_client_update "$getent_path" ahosts client-update.steamstatic.com
        run_command getent_steam_api "$getent_path" ahosts api.steampowered.com
    fi
    curl_path=$(command_path curl)
    echo "curl=$curl_path"
    if [ "$curl_path" != absent ] && [ "$sample" -eq 0 ]; then
        run_command curl_client_update "$curl_path" --connect-timeout 5 --max-time 10 --head https://client-update.steamstatic.com/
        run_command curl_steam_api "$curl_path" --connect-timeout 5 --max-time 10 --head https://api.steampowered.com/
    elif [ "$curl_path" != absent ]; then
        echo "curl_requests=first_sample_only"
    fi

    socket_snapshot
    service_snapshot
    process_snapshot

    section steam_log_tail
    if [ -d "$STEAM_ROOT/logs" ]; then
        for log_path in \
            "$STEAM_ROOT/logs/bootstrap_log.txt" \
            "$STEAM_ROOT/logs/connection_log.txt" \
            "$STEAM_ROOT/logs/console_log.txt" \
            "$STEAM_ROOT/logs/steamui.txt" \
            "$STEAM_ROOT/logs/webhelper.txt" \
            "$STEAM_ROOT/logs/client_networkmanager.txt"; do
            if [ -f "$log_path" ]; then
                echo "log_path=$log_path"
                /usr/bin/tail -n 80 "$log_path" 2>&1 || true
            fi
        done
    else
        echo "steam_logs=absent path=$STEAM_ROOT/logs"
    fi
}

echo "network_observer_begin run_id=$RUN_ID timestamp=$(timestamp)"
echo "network_observer_duration_seconds=$DURATION_SECONDS"
echo "network_observer_interval_seconds=$INTERVAL_SECONDS"
echo "network_observer_root=$STEAM_ROOT"

elapsed=0
sample=0
while [ "$elapsed" -lt "$DURATION_SECONDS" ]; do
    network_snapshot "$sample"
    sample=$((sample + 1))
    remaining=$((DURATION_SECONDS - elapsed))
    if [ "$remaining" -le "$INTERVAL_SECONDS" ]; then
        /bin/sleep "$remaining"
        elapsed=$DURATION_SECONDS
    else
        /bin/sleep "$INTERVAL_SECONDS"
        elapsed=$((elapsed + INTERVAL_SECONDS))
    fi
done

echo "network_observer_end run_id=$RUN_ID timestamp=$(timestamp) samples=$sample"
echo "network_observer=pass run_id=$RUN_ID samples=$sample"
