#!/system/bin/sh

# App-UID supervisor for the Nova rootless profile. This script deliberately
# has no su/chroot/mount path. PRoot supplies the guest root identity while
# Android owns the real UID, namespaces, and network.

set -eu

ACTION="${1:-}"
PROFILE="${NOVA_ROOTLESS_PROFILE:-}"
ROOTFS="${NOVA_ROOTLESS_ROOTFS:-}"
PROOT_BIN="${NOVA_ROOTLESS_PROOT_BIN:-${NOVA_ROOTLESS_PROOT:-}}"
PROOT_LOADER_PATH="${NOVA_ROOTLESS_PROOT_LOADER:-}"
PROOT_LIB_DIR="${NOVA_ROOTLESS_PROOT_LIB_DIR:-}"
STATE="${NOVA_ROOTLESS_STATE:-}"
APP_HOME="${NOVA_ROOTLESS_HOME:-}"
STEAM_CLIENT="${NOVA_ROOTLESS_STEAM_CLIENT:-}"
PROC_NET="${NOVA_ROOTLESS_PROC_NET:-}"
RUNTIME4_SHADOW="${NOVA_ROOTLESS_RUNTIME4_SHADOW:-}"
DISPLAY_VALUE="${DISPLAY:-:0}"
X11_SOCKET="${NOVA_ROOTLESS_X11_SOCKET:-}"

system_id=/system/bin/id
system_df=/system/bin/df
system_stat=/system/bin/stat
system_mkdir=/system/bin/mkdir
system_rm=/system/bin/rm
system_test=/system/bin/test
system_awk=/system/bin/awk
system_sed=/system/bin/sed
system_tr=/system/bin/tr

usage() {
    echo "usage: $0 preflight|run -- command [args...]" >&2
    exit 2
}

fail() {
    echo "nova_rootless_status=fail reason=$1" >&2
    exit 1
}

log() {
    line="$1"
    echo "$line"
    if [ -n "$STATE" ]; then
        "$system_mkdir" -p "$STATE/logs"
        echo "$line" >>"$STATE/logs/rootless-supervisor.log"
    fi
}

manifest_value() {
    key="$1"
    [ -n "$PROFILE" ] || return 0
    "$system_awk" -F '\t' -v wanted="$key" \
        '$1 == wanted { print $2; exit }' "$PROFILE"
}

numeric() {
    case "$1" in
        ''|*[!0-9]*) return 1 ;;
        *) return 0 ;;
    esac
}

require_path() {
    kind="$1"
    path="$2"
    case "$kind" in
        file)
            "$system_test" -f "$path" || fail "missing_file:$path"
            ;;
        executable)
            "$system_test" -x "$path" || fail "missing_executable:$path"
            ;;
        directory)
            "$system_test" -d "$path" || fail "missing_directory:$path"
            ;;
        *)
            fail "internal_bad_path_kind:$kind"
            ;;
    esac
}

read_free_space() {
    # Android toybox df has a stable POSIX-compatible final line. Avoid
    # parsing human-readable output or the path's parent directory.
    "$system_df" -k "$STATE" 2>/dev/null |
        "$system_awk" 'NR > 1 { value=$4 } END { print value + 0 }'
}

prepare_state() {
    require_path directory "$STATE"
    require_path directory "$APP_HOME"
    require_path directory "$STEAM_CLIENT"
    "$system_mkdir" -p \
        "$STATE/logs" \
        "$STATE/proot-tmp" \
        "$STATE/tmp" \
        "$STATE/run" \
        "$STATE/config" \
        "$APP_HOME" \
        "$STEAM_CLIENT"
    # These paths are app-owned. Refuse a symlink so a bad configuration cannot
    # redirect Steam writes outside the selected rootless state tree.
    for path in "$STATE" "$STATE/logs" "$STATE/proot-tmp" "$STATE/tmp" \
        "$STATE/run" "$STATE/config" "$APP_HOME" "$STEAM_CLIENT"; do
        [ ! -L "$path" ] || fail "symlinked_state_path:$path"
    done
    chmod 700 "$STATE" "$STATE/logs" "$STATE/proot-tmp" "$STATE/tmp" \
        "$STATE/run" "$STATE/config" "$APP_HOME" "$STEAM_CLIENT"
}

validate_proc_net() {
    [ -n "$PROC_NET" ] || return 0
    require_path directory "$PROC_NET"
    require_path file "$PROC_NET/route"
    require_path file "$PROC_NET/ipv6_route"
    [ ! -L "$PROC_NET" ] || fail "symlinked_proc_net:$PROC_NET"
    [ ! -L "$PROC_NET/route" ] || fail "symlinked_proc_net_route:$PROC_NET/route"
    [ ! -L "$PROC_NET/ipv6_route" ] ||
        fail "symlinked_proc_net_ipv6_route:$PROC_NET/ipv6_route"
    "$system_awk" 'NR > 1 && $1 != "" { found = 1 } END { exit(found ? 0 : 1) }' \
        "$PROC_NET/route" || fail "empty_proc_net_route:$PROC_NET/route"
}

validate_runtime4_shadow() {
    [ -n "$RUNTIME4_SHADOW" ] || return 0
    require_path directory "$RUNTIME4_SHADOW"
    require_path file "$RUNTIME4_SHADOW/_v2-entry-point"
    require_path executable "$RUNTIME4_SHADOW/pressure-vessel/bin/pressure-vessel-wrap"
    [ ! -L "$RUNTIME4_SHADOW" ] || fail "symlinked_runtime4_shadow:$RUNTIME4_SHADOW"
    [ ! -L "$RUNTIME4_SHADOW/_v2-entry-point" ] ||
        fail "symlinked_runtime4_entry:$RUNTIME4_SHADOW/_v2-entry-point"
    [ ! -L "$RUNTIME4_SHADOW/pressure-vessel/bin/pressure-vessel-wrap" ] ||
        fail "symlinked_runtime4_pressure_vessel:$RUNTIME4_SHADOW/pressure-vessel/bin/pressure-vessel-wrap"
}

preflight() {
    [ -n "$ROOTFS" ] || fail missing_rootfs_argument
    [ -n "$PROOT_BIN" ] || fail missing_proot_argument
    [ -n "$PROOT_LOADER_PATH" ] || fail missing_proot_loader_argument
    [ -n "$PROOT_LIB_DIR" ] || fail missing_proot_lib_argument
    [ -n "$STATE" ] || fail missing_state_argument
    [ -n "$APP_HOME" ] || fail missing_app_home_argument
    [ -n "$STEAM_CLIENT" ] || fail missing_steam_client_argument

    real_uid="$($system_id -u)"
    numeric "$real_uid" || fail "invalid_real_uid:$real_uid"
    [ "$real_uid" -ne 0 ] || fail root_detected

    require_path directory "$ROOTFS"
    require_path executable "$PROOT_BIN"
    require_path directory "$PROOT_LIB_DIR"
    require_path file "$PROOT_LOADER_PATH"
    require_path file "$ROOTFS/usr/lib/ld-linux-aarch64.so.1"
    require_path executable "$ROOTFS/usr/bin/id"
    prepare_state

    free_kib="$(read_free_space)"
    numeric "$free_kib" || fail "invalid_free_space:$free_kib"
    minimum_free_bytes="$(manifest_value minimum_free_bytes)"
    [ -n "$minimum_free_bytes" ] || minimum_free_bytes=1073741824
    numeric "$minimum_free_bytes" || fail "invalid_minimum_free_bytes:$minimum_free_bytes"
    minimum_free_kib=$((minimum_free_bytes / 1024))
    [ "$free_kib" -ge "$minimum_free_kib" ] ||
        fail "insufficient_free_space:${free_kib}KiB<${minimum_free_kib}KiB"

    expected_runtime="$(manifest_value rootfs_runtime_version)"
    if [ -n "$expected_runtime" ] && [ "${NOVA_ROOTLESS_RUNTIME_VERSION:-$expected_runtime}" != "$expected_runtime" ]; then
        fail "runtime_version_mismatch"
    fi
    [ -z "$X11_SOCKET" ] || {
        [ -S "$X11_SOCKET" ] || fail "x11_socket_not_socket:$X11_SOCKET"
        [ -r "$X11_SOCKET" ] || fail "x11_socket_not_readable:$X11_SOCKET"
    }
    validate_proc_net
    validate_runtime4_shadow
    log "nova_rootless_preflight=pass uid=$real_uid rootfs=$ROOTFS proot=$PROOT_BIN"
    log "nova_rootless_state=$STATE home=$APP_HOME steam_client=$STEAM_CLIENT"
    log "nova_rootless_free_kib=$free_kib"
    [ -z "$PROC_NET" ] || log "nova_rootless_proc_net=$PROC_NET"
    [ -z "$RUNTIME4_SHADOW" ] || log "nova_rootless_runtime4_shadow=$RUNTIME4_SHADOW"
}

run_guest() {
    shift
    [ "${1:-}" = "--" ] || usage
    shift
    [ "$#" -gt 0 ] || usage

    preflight

    # The outer LD_LIBRARY_PATH is for the Termux PRoot package. PRoot's loader
    # then resolves the guest executable against the Holo glibc tree.
    export LD_LIBRARY_PATH="$PROOT_LIB_DIR${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    export PROOT_LOADER="$PROOT_LOADER_PATH"
    export PROOT_TMP_DIR="$STATE/proot-tmp"
    export TMPDIR="$STATE/tmp"
    export NOVA_ROOTLESS_NO_SU=1

    log "nova_rootless_exec=proot display=$DISPLAY_VALUE"
    exec_proot() {
        # Keep the command after -- as argv, not an interpolated shell string.
        # This prevents Steam URLs or paths from becoming shell syntax.
        if [ -n "$PROC_NET" ] && [ -n "$RUNTIME4_SHADOW" ]; then
            exec "$PROOT_BIN" \
                --kill-on-exit \
                --sysvipc \
                -0 \
                -r "$ROOTFS" \
                -b /proc:/proc \
                -b "$APP_HOME:/home/nova" \
                -b "$STEAM_CLIENT:/opt/nova-steam" \
                -b "$STATE/tmp:/tmp" \
                -b "$STATE/run:/run" \
                -b "$PROC_NET:/proc/net" \
                -b "$RUNTIME4_SHADOW:/opt/nova-steam/steamapps/common/SteamLinuxRuntime_4-arm64" \
                -w /home/nova \
                /usr/bin/env \
                "PATH=/usr/bin:/bin:/usr/sbin:/sbin" \
                "HOME=/home/nova" \
                "USER=nova" \
                "LOGNAME=nova" \
                "DISPLAY=$DISPLAY_VALUE" \
                "XDG_RUNTIME_DIR=/run/nova" \
                "PULSE_SERVER=${NOVA_ROOTLESS_PULSE_SERVER:-}" \
                "NOVA_ROOTLESS_NO_SU=1" \
                "NOVA_ROOTLESS_X11_SOCKET=$X11_SOCKET" \
                "$@"
        elif [ -n "$PROC_NET" ]; then
            exec "$PROOT_BIN" \
                --kill-on-exit \
                --sysvipc \
                -0 \
                -r "$ROOTFS" \
                -b /proc:/proc \
                -b "$APP_HOME:/home/nova" \
                -b "$STEAM_CLIENT:/opt/nova-steam" \
                -b "$STATE/tmp:/tmp" \
                -b "$STATE/run:/run" \
                -b "$PROC_NET:/proc/net" \
                -w /home/nova \
                /usr/bin/env \
                "PATH=/usr/bin:/bin:/usr/sbin:/sbin" \
                "HOME=/home/nova" \
                "USER=nova" \
                "LOGNAME=nova" \
                "DISPLAY=$DISPLAY_VALUE" \
                "XDG_RUNTIME_DIR=/run/nova" \
                "PULSE_SERVER=${NOVA_ROOTLESS_PULSE_SERVER:-}" \
                "NOVA_ROOTLESS_NO_SU=1" \
                "NOVA_ROOTLESS_X11_SOCKET=$X11_SOCKET" \
                "$@"
        elif [ -n "$RUNTIME4_SHADOW" ]; then
            exec "$PROOT_BIN" \
                --kill-on-exit \
                --sysvipc \
                -0 \
                -r "$ROOTFS" \
                -b /proc:/proc \
                -b "$APP_HOME:/home/nova" \
                -b "$STEAM_CLIENT:/opt/nova-steam" \
                -b "$STATE/tmp:/tmp" \
                -b "$STATE/run:/run" \
                -b "$RUNTIME4_SHADOW:/opt/nova-steam/steamapps/common/SteamLinuxRuntime_4-arm64" \
                -w /home/nova \
                /usr/bin/env \
                "PATH=/usr/bin:/bin:/usr/sbin:/sbin" \
                "HOME=/home/nova" \
                "USER=nova" \
                "LOGNAME=nova" \
                "DISPLAY=$DISPLAY_VALUE" \
                "XDG_RUNTIME_DIR=/run/nova" \
                "PULSE_SERVER=${NOVA_ROOTLESS_PULSE_SERVER:-}" \
                "NOVA_ROOTLESS_NO_SU=1" \
                "NOVA_ROOTLESS_X11_SOCKET=$X11_SOCKET" \
                "$@"
        else
            exec "$PROOT_BIN" \
                --kill-on-exit \
                --sysvipc \
                -0 \
                -r "$ROOTFS" \
                -b /proc:/proc \
                -b "$APP_HOME:/home/nova" \
                -b "$STEAM_CLIENT:/opt/nova-steam" \
                -b "$STATE/tmp:/tmp" \
                -b "$STATE/run:/run" \
                -w /home/nova \
                /usr/bin/env \
                "PATH=/usr/bin:/bin:/usr/sbin:/sbin" \
                "HOME=/home/nova" \
                "USER=nova" \
                "LOGNAME=nova" \
                "DISPLAY=$DISPLAY_VALUE" \
                "XDG_RUNTIME_DIR=/run/nova" \
                "PULSE_SERVER=${NOVA_ROOTLESS_PULSE_SERVER:-}" \
                "NOVA_ROOTLESS_NO_SU=1" \
                "NOVA_ROOTLESS_X11_SOCKET=$X11_SOCKET" \
                "$@"
        fi
    }
    exec_proot "$@"
}

case "$ACTION" in
    preflight)
        [ "$#" -eq 1 ] || usage
        preflight
        ;;
    run)
        run_guest "$@"
        ;;
    *)
        usage
        ;;
esac
