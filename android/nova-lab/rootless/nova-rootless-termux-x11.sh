#!/data/data/com.termux/files/usr/bin/bash

# Termux-side half of the experimental rootless display contract. It is
# intended to be invoked through Termux RUN_COMMAND, not through su or
# app_process from Nova. The TCP listener is deliberately opt-in and bound by
# the X server's normal Android/Termux network context; this is not yet the
# final embedded bridge.

set -euo pipefail

action="${1:-}"
display_number="${2:-77}"
state_dir="${NOVA_ROOTLESS_TERMUX_STATE:-$HOME/.nova-rootless}"
log_file="${3:-$state_dir/termux-x11-$display_number.log}"
pid_file="$state_dir/termux-x11-$display_number.pid"

fail() {
    echo "nova_rootless_termux_x11=fail reason=$1" >&2
    exit 1
}

case "$display_number" in
    ''|*[!0-9]*) fail invalid_display_number ;;
esac
if ((display_number < 1 || display_number > 99)); then
    fail display_number_out_of_range
fi

pid_is_ours() {
    local pid="$1"
    [[ "$pid" =~ ^[0-9]+$ ]] || return 1
    kill -0 "$pid" 2>/dev/null || return 1
    [[ -r "/proc/$pid/cmdline" ]] || return 1
    tr '\0' ' ' <"/proc/$pid/cmdline" | grep -Fq 'termux-x11'
}

read_pid() {
    [[ -f "$pid_file" ]] || return 1
    local pid
    pid="$(<"$pid_file")"
    pid_is_ours "$pid" || return 1
    printf '%s\n' "$pid"
}

case "$action" in
    start)
        [[ "$(id -u)" != 0 ]] || fail root_uid_detected
        command -v termux-x11 >/dev/null 2>&1 || fail missing_termux_x11_command
        mkdir -p "$state_dir"
        chmod 700 "$state_dir"
        if pid="$(read_pid 2>/dev/null)"; then
            echo "nova_rootless_termux_x11=already_running display=:$display_number pid=$pid"
            exit 0
        fi
        rm -f -- "$pid_file"
        # TCP is used only for this first rootless transport experiment because
        # Nova and Termux have different private data directories. -ac avoids
        # an inaccessible MIT-MAGIC-COOKIE during the boundary test. Do not
        # promote this to the product default without a loopback/auth bridge.
        TERMUX_X11_DEBUG=1 TMPDIR="$PREFIX/tmp" \
            termux-x11 ":$display_number" -listen tcp -ac \
            >"$log_file" 2>&1 &
        pid=$!
        printf '%s\n' "$pid" >"$pid_file"
        chmod 600 "$pid_file" "$log_file"
        echo "nova_rootless_termux_x11=started display=:$display_number pid=$pid log=$log_file"
        ;;
    status)
        if pid="$(read_pid 2>/dev/null)"; then
            echo "nova_rootless_termux_x11=running display=:$display_number pid=$pid log=$log_file"
        else
            echo "nova_rootless_termux_x11=stopped display=:$display_number"
            exit 1
        fi
        ;;
    stop)
        if pid="$(read_pid 2>/dev/null)"; then
            kill "$pid"
            rm -f -- "$pid_file"
            echo "nova_rootless_termux_x11=stopped display=:$display_number pid=$pid"
        else
            rm -f -- "$pid_file"
            echo "nova_rootless_termux_x11=already_stopped display=:$display_number"
        fi
        ;;
    *)
        echo "usage: $0 start|status|stop [display_number] [log_file]" >&2
        exit 2
        ;;
esac
