#!/data/data/com.termux/files/usr/bin/bash

# Optional Termux-side PulseAudio endpoint for rootless Steam. This helper is
# deliberately independent of X11: a missing Pulse package must not make the
# display transport look healthy or unhealthy by implication.

set -euo pipefail

base="${1:-${NOVA_ROOTLESS_AUDIO_BASE:-$HOME/.nova-rootless}}"
pulse_server="${NOVA_ROOTLESS_PULSE_SERVER:-tcp:127.0.0.1:4713}"
pulse_runtime="$base/run/pulse"
local_server="unix:$pulse_runtime/native"

fail() {
    printf 'nova_rootless_pulseaudio=fail reason=%s\n' "$1" >&2
    exit 1
}

command -v pactl >/dev/null 2>&1 || fail pactl_unavailable
command -v pulseaudio >/dev/null 2>&1 || fail pulseaudio_unavailable

if pactl --server="$pulse_server" info >/dev/null 2>&1; then
    printf 'nova_rootless_pulseaudio=pass server=%s existing=1\n' "$pulse_server"
    exit 0
fi

if [[ -L "$pulse_runtime" ]]; then
    fail symlinked_runtime_directory
fi
mkdir -p "$pulse_runtime"
[[ -d "$pulse_runtime" ]] || fail runtime_not_directory
chmod 700 "$pulse_runtime"

if ! pactl --server="$local_server" info >/dev/null 2>&1; then
    PULSE_RUNTIME_PATH="$pulse_runtime" \
        pulseaudio --start --exit-idle-time=-1 >/dev/null 2>&1 ||
        fail pulseaudio_start_failed
fi
if ! pactl --server="$local_server" info >/dev/null 2>&1; then
    fail local_server_unreachable
fi

module_list="$(pactl --server="$local_server" list short modules)" ||
    fail module_list_failed
has_loopback_tcp=0
while IFS=$'\t' read -r _ module_name module_args _; do
    [[ "$module_name" == module-native-protocol-tcp ]] || continue
    has_listen=0
    has_port=0
    read -r -a arguments <<<"$module_args"
    for argument in "${arguments[@]}"; do
        case "$argument" in
            listen=127.0.0.1) has_listen=1 ;;
            port=4713) has_port=1 ;;
        esac
    done
    if ((has_listen && has_port)); then
        has_loopback_tcp=1
        break
    fi
done <<<"$module_list"

if (( !has_loopback_tcp )); then
    module_id="$(pactl --server="$local_server" load-module \
        module-native-protocol-tcp listen=127.0.0.1 port=4713 \
        auth-ip-acl=127.0.0.1 auth-anonymous=1)" ||
        fail tcp_module_load_failed
    [[ "$module_id" =~ ^[0-9]+$ ]] || fail invalid_module_id
fi

pactl --server="$pulse_server" info >/dev/null 2>&1 ||
    fail tcp_server_unreachable
printf 'nova_rootless_pulseaudio=pass server=%s existing=0\n' "$pulse_server"
