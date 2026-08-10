#!/bin/sh

set -u

STEAM_HOME=/opt/nova-steam/home
STEAM_ROOT="$STEAM_HOME/.local/share/Steam"
STEAM_EXECUTABLE="$STEAM_ROOT/steamrtarm64/steam"
CLIENT_LOG=/tmp/nova-steam-client.log
CLIENT_STDOUT=/tmp/nova-steam-client.stdout
CLIENT_STDERR=/tmp/nova-steam-client.stderr
RUNTIME_DIR=/tmp/nova-steam-runtime
STEAM_UID=${NOVA_TERMUX_X11_STEAM_UID:-501}
STEAM_GID=${NOVA_TERMUX_X11_STEAM_GID:-20}
# Android's audio device nodes are normally owned by AID_AUDIO (1005). Keep
# the Linux Steam identity stable while granting only that supplementary
# group; callers can override it for a device with a different audio gid.
STEAM_AUDIO_GID=${NOVA_TERMUX_X11_STEAM_AUDIO_GID:-1005}
CLIENT_TIMEOUT=${NOVA_TERMUX_X11_STEAM_TIMEOUT_SECONDS:-60}
STEAM_FULLSCREEN=${NOVA_TERMUX_X11_STEAM_FULLSCREEN:-0}
STEAM_FULLDESKTOPRES=${NOVA_TERMUX_X11_STEAM_FULLDESKTOPRES:-0}
STEAM_WIDTH=${NOVA_TERMUX_X11_STEAM_WIDTH:-}
STEAM_HEIGHT=${NOVA_TERMUX_X11_STEAM_HEIGHT:-}
STEAM_HARDWARE_ACCEL=${NOVA_TERMUX_X11_STEAM_HARDWARE_ACCEL:-0}
STEAM_VULKAN_ICD=${NOVA_TERMUX_X11_STEAM_VULKAN_ICD:-/opt/nova-kgsl-driver/freedreno-kgsl.icd.json}
CEF_DISABLE_GPU=${NOVA_TERMUX_X11_STEAM_CEF_DISABLE_GPU:-}
AUDIO_BRIDGE=${NOVA_TERMUX_X11_STEAM_AUDIO_BRIDGE:-0}
AUDIO_BRIDGE_PORT=${NOVA_TERMUX_X11_STEAM_AUDIO_BRIDGE_PORT:-29100}
AUDIO_BRIDGE_LOG=${NOVA_TERMUX_X11_STEAM_AUDIO_BRIDGE_LOG:-/tmp/nova-alsa-audiotrack-bridge.log}
DBUS_SESSION_MODE=${NOVA_TERMUX_X11_DBUS_SESSION:-0}
DBUS_SESSION_USER=${NOVA_TERMUX_X11_DBUS_SESSION_USER:-steam}
DBUS_SESSION_UID_RECORD=${NOVA_TERMUX_X11_DBUS_SESSION_UID_RECORD:-0}
DBUS_SYSTEM_MODE=${NOVA_TERMUX_X11_DBUS_SYSTEM:-0}
client_pid=
dbus_session_pid=
dbus_session_dir=
dbus_session_runtime_dir=
dbus_session_socket=
dbus_session_log=
dbus_session_probe_log=
dbus_passwd_backup=
dbus_passwd_changed=0
dbus_system_pid=
dbus_system_dir=
dbus_system_socket=
dbus_system_pid_file=
dbus_system_log=
dbus_system_probe_log=
dbus_system_dir_created=0
dbus_system_started=0

case "$STEAM_UID:$STEAM_GID" in
    ''|*[!0-9:]*|*:*:*)
        echo "invalid Steam uid/gid: $STEAM_UID:$STEAM_GID" >&2
        exit 2
        ;;
esac
case "$STEAM_AUDIO_GID" in
    ''|*[!0-9]*)
        echo "invalid Steam audio gid: $STEAM_AUDIO_GID" >&2
        exit 2
        ;;
esac
case "$CLIENT_TIMEOUT" in
    ''|*[!0-9]*)
        echo "invalid Steam timeout: $CLIENT_TIMEOUT" >&2
        exit 2
        ;;
esac
if [ "$CLIENT_TIMEOUT" -lt 1 ]; then
    echo "Steam timeout must be at least 1 second" >&2
    exit 2
fi
case "$STEAM_FULLSCREEN:$STEAM_FULLDESKTOPRES" in
    0:0|0:1|1:0|1:1)
        ;;
    *)
        echo "invalid Steam fullscreen flags: $STEAM_FULLSCREEN:$STEAM_FULLDESKTOPRES" >&2
        exit 2
        ;;
esac
case "$STEAM_WIDTH:$STEAM_HEIGHT" in
    :)
        ;;
    ''|*[!0-9:]*|*:*:*|0:*|*:0)
        echo "invalid Steam window size: $STEAM_WIDTH:$STEAM_HEIGHT" >&2
        exit 2
        ;;
esac
case "$STEAM_HARDWARE_ACCEL" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_TERMUX_X11_STEAM_HARDWARE_ACCEL: $STEAM_HARDWARE_ACCEL" >&2
        exit 2
        ;;
esac
if [ -z "$CEF_DISABLE_GPU" ]; then
    case "$STEAM_HARDWARE_ACCEL" in
        0) CEF_DISABLE_GPU=1 ;;
        1) CEF_DISABLE_GPU=0 ;;
    esac
fi
case "$CEF_DISABLE_GPU" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_TERMUX_X11_STEAM_CEF_DISABLE_GPU: $CEF_DISABLE_GPU" >&2
        exit 2
        ;;
esac
case "$STEAM_VULKAN_ICD" in
    /*)
        ;;
    *)
        echo "NOVA_TERMUX_X11_STEAM_VULKAN_ICD must be an absolute path: $STEAM_VULKAN_ICD" >&2
        exit 2
        ;;
esac
case "$AUDIO_BRIDGE" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_TERMUX_X11_STEAM_AUDIO_BRIDGE: $AUDIO_BRIDGE" >&2
        exit 2
        ;;
esac
case "$AUDIO_BRIDGE_PORT" in
    ''|*[!0-9]*)
        echo "invalid NOVA_TERMUX_X11_STEAM_AUDIO_BRIDGE_PORT: $AUDIO_BRIDGE_PORT" >&2
        exit 2
        ;;
esac
if [ "$AUDIO_BRIDGE_PORT" -lt 1024 ] || [ "$AUDIO_BRIDGE_PORT" -gt 65535 ]; then
    echo "NOVA_TERMUX_X11_STEAM_AUDIO_BRIDGE_PORT out of range: $AUDIO_BRIDGE_PORT" >&2
    exit 2
fi
case "$DBUS_SESSION_MODE" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_TERMUX_X11_DBUS_SESSION: $DBUS_SESSION_MODE" >&2
        exit 2
        ;;
esac
case "$DBUS_SESSION_USER" in
    root|steam)
        ;;
    *)
        echo "invalid NOVA_TERMUX_X11_DBUS_SESSION_USER: $DBUS_SESSION_USER" >&2
        exit 2
        ;;
esac
case "$DBUS_SESSION_UID_RECORD" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_TERMUX_X11_DBUS_SESSION_UID_RECORD: $DBUS_SESSION_UID_RECORD" >&2
        exit 2
        ;;
esac
case "$DBUS_SYSTEM_MODE" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_TERMUX_X11_DBUS_SYSTEM: $DBUS_SYSTEM_MODE" >&2
        exit 2
        ;;
esac

log() {
    echo "$1" >>"$CLIENT_LOG"
}

run_as_steam() {
    /usr/bin/setpriv --reuid="$STEAM_UID" --regid="$STEAM_GID" \
        --groups="$STEAM_AUDIO_GID" "$@"
}

stop_dbus_session() {
    if [ -n "${dbus_session_pid:-}" ] && /usr/bin/kill -0 "$dbus_session_pid" 2>/dev/null; then
        /usr/bin/kill "$dbus_session_pid" 2>/dev/null || true
    fi
    ps_path=$(command -v ps 2>/dev/null || true)
    if [ -n "$ps_path" ] && [ -n "${dbus_session_socket:-}" ]; then
        dbus_session_pids=$(
            "$ps_path" -eo pid,args 2>/dev/null |
                /usr/bin/awk -v socket="$dbus_session_socket" '
                    NR > 1 && $0 ~ /dbus-daemon/ && index($0, socket) { print $1 }
                '
        )
        for pid in $dbus_session_pids; do
            case "$pid" in
                ''|*[!0-9]*|"$$")
                    continue
                    ;;
            esac
            /usr/bin/kill "$pid" 2>/dev/null || true
        done
        /usr/bin/sleep 0.2
        dbus_session_pids=$(
            "$ps_path" -eo pid,args 2>/dev/null |
                /usr/bin/awk -v socket="$dbus_session_socket" '
                    NR > 1 && $0 ~ /dbus-daemon/ && index($0, socket) { print $1 }
                '
        )
        for pid in $dbus_session_pids; do
            case "$pid" in
                ''|*[!0-9]*|"$$")
                    continue
                    ;;
            esac
            /usr/bin/kill -9 "$pid" 2>/dev/null || true
        done
    fi
    if [ -n "${dbus_session_pid:-}" ]; then
        /usr/bin/wait "$dbus_session_pid" 2>/dev/null || true
    fi
}

stop_dbus_system() {
    if [ -n "${dbus_system_pid:-}" ] && /usr/bin/kill -0 "$dbus_system_pid" 2>/dev/null; then
        /usr/bin/kill "$dbus_system_pid" 2>/dev/null || true
    fi
    if [ -n "${dbus_system_pid:-}" ]; then
        /usr/bin/wait "$dbus_system_pid" 2>/dev/null || true
    fi
    if [ "$dbus_system_started" -eq 1 ]; then
        if [ -n "${dbus_system_socket:-}" ]; then
            /bin/rm -f "$dbus_system_socket"
        fi
        if [ -n "${dbus_system_pid_file:-}" ]; then
            /bin/rm -f "$dbus_system_pid_file"
        fi
        if [ "$dbus_system_dir_created" -eq 1 ] && [ -n "${dbus_system_dir:-}" ]; then
            /bin/rmdir "$dbus_system_dir" 2>/dev/null || true
        fi
        log "dbus_system_cleanup=pass socket=${dbus_system_socket:-unset}"
    fi
}

restore_dbus_passwd_record() {
    if [ "$dbus_passwd_changed" -ne 1 ] || [ -z "$dbus_passwd_backup" ]; then
        return 0
    fi
    if /usr/bin/cp -p "$dbus_passwd_backup" /etc/passwd; then
        if /bin/rm -f "$dbus_passwd_backup"; then
            log "dbus_session_passwd_restore=pass"
        else
            log "dbus_session_passwd_restore=fail reason=backup_cleanup"
            return 1
        fi
    else
        log "dbus_session_passwd_restore=fail"
        return 1
    fi
}

finish() {
    status=$?
    trap - EXIT INT TERM
    if [ -n "${client_pid:-}" ] && /usr/bin/kill -0 "$client_pid" 2>/dev/null; then
        /usr/bin/kill "$client_pid" 2>/dev/null || true
        /usr/bin/sleep 0.2
        /usr/bin/kill -9 "$client_pid" 2>/dev/null || true
    fi
    stop_dbus_system
    if [ -n "${dbus_system_log:-}" ] && [ -f "$dbus_system_log" ]; then
        log "dbus_system_daemon_output_begin"
        /bin/cat "$dbus_system_log" >>"$CLIENT_LOG"
        log "dbus_system_daemon_output_end"
    fi
    stop_dbus_session
    if [ -n "${dbus_session_log:-}" ] && [ -f "$dbus_session_log" ]; then
        log "dbus_session_daemon_output_begin"
        /bin/cat "$dbus_session_log" >>"$CLIENT_LOG"
        log "dbus_session_daemon_output_end"
    fi
    if [ -n "${dbus_session_runtime_dir:-}" ]; then
        /bin/rm -rf "$dbus_session_runtime_dir"
        log "dbus_session_cleanup=pass path=$dbus_session_runtime_dir"
    fi
    if [ -n "${dbus_session_dir:-}" ]; then
        /bin/rm -rf "$dbus_session_dir"
        log "dbus_session_dir_cleanup=pass path=$dbus_session_dir"
    fi
    if ! restore_dbus_passwd_record; then
        status=1
    fi
    if [ -f "$CLIENT_LOG" ]; then
        cat "$CLIENT_LOG"
    fi
    exit "$status"
}
trap finish EXIT INT TERM

: >"$CLIENT_LOG"
log "client_begin $(date +%s)"
log "client_kind=steam_arm64_direct_termux_x11"
log "client_display=${DISPLAY:-unset}"
log "client_home=$STEAM_HOME"
log "client_root=$STEAM_ROOT"
log "client_executable=$STEAM_EXECUTABLE"
if [ "$CEF_DISABLE_GPU" -eq 0 ]; then
    log "client_flags_base=-gamepadui -steamos3 -steampal -steamdeck -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox"
else
    log "client_flags_base=-gamepadui -steamos3 -steampal -steamdeck -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox -cef-disable-gpu"
fi
log "client_fullscreen=$STEAM_FULLSCREEN"
log "client_fulldesktopres=$STEAM_FULLDESKTOPRES"
log "client_width=${STEAM_WIDTH:-unset}"
log "client_height=${STEAM_HEIGHT:-unset}"
log "client_hardware_accel=$STEAM_HARDWARE_ACCEL"
log "client_vulkan_icd=$STEAM_VULKAN_ICD"
log "client_cef_disable_gpu=$CEF_DISABLE_GPU"
log "client_audio_bridge=$AUDIO_BRIDGE"
log "client_audio_bridge_port=$AUDIO_BRIDGE_PORT"
log "client_audio_bridge_log=$AUDIO_BRIDGE_LOG"
log "client_uid=$STEAM_UID"
log "client_gid=$STEAM_GID"
log "client_audio_gid=$STEAM_AUDIO_GID"
log "client_timeout_seconds=$CLIENT_TIMEOUT"
log "client_xauthority=${XAUTHORITY:-unset}"
log "client_runtime_dir=$RUNTIME_DIR"
log "client_dbus_session_mode=$DBUS_SESSION_MODE"
log "client_dbus_session_user=$DBUS_SESSION_USER"
log "client_dbus_session_uid_record=$DBUS_SESSION_UID_RECORD"
log "client_dbus_system_mode=$DBUS_SYSTEM_MODE"

if [ ! -x "$STEAM_EXECUTABLE" ]; then
    log "client_started=fail"
    log "client_error=missing_or_nonexecutable_executable"
    exit 1
fi
if [ ! -x /usr/bin/setpriv ]; then
    log "client_started=fail"
    log "client_error=missing_setpriv"
    exit 1
fi
if [ "$STEAM_HARDWARE_ACCEL" -eq 1 ] && [ ! -r "$STEAM_VULKAN_ICD" ]; then
    log "client_started=fail"
    log "client_error=missing_vulkan_icd path=$STEAM_VULKAN_ICD"
    exit 1
fi

mkdir -p "$STEAM_HOME" "$RUNTIME_DIR"
if ! /usr/bin/chown "$STEAM_UID:$STEAM_GID" "$RUNTIME_DIR" ||
    ! /usr/bin/chmod 700 "$RUNTIME_DIR"; then
    log "client_runtime_owner_status=fail"
    exit 1
fi
log "client_runtime_owner_status=pass"

# The seeded rootfs may carry a root-owned HOME cache even though Steam runs
# under the stable non-root uid below.  CEF/Mesa disables its shader cache when
# this directory is inaccessible; repair only this disposable cache boundary
# before launching Steam and make the result explicit in the run log.
MESA_SHADER_CACHE_DIR="$STEAM_HOME/.cache/mesa_shader_cache"
if ! /bin/mkdir -p "$MESA_SHADER_CACHE_DIR" ||
    ! /usr/bin/chown "$STEAM_UID:$STEAM_GID" "$STEAM_HOME/.cache" \
        "$MESA_SHADER_CACHE_DIR" ||
    ! /usr/bin/chmod 700 "$STEAM_HOME/.cache" "$MESA_SHADER_CACHE_DIR"; then
    log "client_mesa_shader_cache_owner_status=fail"
    exit 1
fi
export MESA_SHADER_CACHE_DIR
log "client_mesa_shader_cache_owner_status=pass"
log "client_mesa_shader_cache_dir=$MESA_SHADER_CACHE_DIR"

if [ -x /opt/nova-kgsl-driver/nova-steam-network-api-compat.sh ]; then
    /opt/nova-kgsl-driver/nova-steam-network-api-compat.sh "$STEAM_ROOT" \
        >>"$CLIENT_LOG" 2>&1
    network_status=$?
    log "client_network_api_compat_status=$network_status"
    if [ "$network_status" -ne 0 ]; then
        exit 1
    fi
else
    log "client_network_api_compat_status=missing_helper"
    exit 1
fi

if [ -x /usr/bin/xhost ]; then
    env -u LD_PRELOAD DISPLAY=:0 /usr/bin/xhost +local: >>"$CLIENT_LOG" 2>&1
    log "client_xhost_local_status=$?"
fi

export HOME="$STEAM_HOME"
export USER=steam
export LOGNAME=steam
export DISPLAY=:0
export XDG_RUNTIME_DIR="$RUNTIME_DIR"
export LANG=C
export LC_ALL=C
steam_runtime_files_bin=
for candidate in "$STEAM_ROOT"/steam-runtime-steamrt-arm64/*/files/bin; do
    if [ -d "$candidate" ]; then
        steam_runtime_files_bin=$candidate
        break
    fi
done
export PATH="$STEAM_ROOT/steam-runtime-steamrt-arm64/bin${steam_runtime_files_bin:+:$steam_runtime_files_bin}:/usr/bin:/bin"
log "client_runtime_files_bin=${steam_runtime_files_bin:-unset}"
if [ "$STEAM_HARDWARE_ACCEL" -eq 1 ]; then
    unset MESA_LOADER_DRIVER_OVERRIDE
    unset GALLIUM_DRIVER
    unset LIBGL_ALWAYS_SOFTWARE
    export VK_ICD_FILENAMES="$STEAM_VULKAN_ICD"
    log "client_mesa_driver=unset"
    log "client_gallium_driver=unset"
    log "client_libgl_always_software=unset"
    log "client_vk_icd=$VK_ICD_FILENAMES"
else
    unset VK_ICD_FILENAMES
    export MESA_LOADER_DRIVER_OVERRIDE=swrast
    export GALLIUM_DRIVER=softpipe
    export LIBGL_ALWAYS_SOFTWARE=1
    log "client_mesa_driver=$MESA_LOADER_DRIVER_OVERRIDE"
    log "client_gallium_driver=$GALLIUM_DRIVER"
    log "client_libgl_always_software=1"
    log "client_vk_icd=unset"
fi
export LD_LIBRARY_PATH="$STEAM_ROOT/steamrtarm64:$STEAM_ROOT/lib/aarch64-linux-gnu:/usr/lib${steam_runtime_files_bin:+:${steam_runtime_files_bin%/bin}/lib/aarch64-linux-gnu}${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
preload_paths=
if [ "$AUDIO_BRIDGE" -eq 1 ]; then
    if [ ! -f /opt/nova-kgsl-driver/libnova-alsa-audiotrack-bridge.so ]; then
        log "client_started=fail"
        log "client_error=missing_audio_bridge_library"
        exit 1
    fi
    preload_paths=/opt/nova-kgsl-driver/libnova-alsa-audiotrack-bridge.so
    export NOVA_TERMUX_X11_STEAM_AUDIO_BRIDGE_LOG="$AUDIO_BRIDGE_LOG"
else
    unset NOVA_TERMUX_X11_STEAM_AUDIO_BRIDGE_LOG
fi
if [ -f /opt/nova-kgsl-driver/libsysv-sem-shim.so ]; then
    if [ -n "$preload_paths" ]; then
        preload_paths="$preload_paths:/opt/nova-kgsl-driver/libsysv-sem-shim.so"
    else
        preload_paths=/opt/nova-kgsl-driver/libsysv-sem-shim.so
    fi
fi
if [ -n "$preload_paths" ]; then
    export LD_PRELOAD="$preload_paths"
    log "client_preload=$LD_PRELOAD"
else
    unset LD_PRELOAD
    log "client_preload=missing_libsysv_sem_shim"
fi

start_dbus_session() {
    if [ "$DBUS_SESSION_MODE" -eq 0 ]; then
        log "client_dbus_session=disabled"
        return 0
    fi

    log "client_dbus_session=enabled"
    if [ ! -x /usr/bin/dbus-daemon ]; then
        log "client_dbus_session_status=fail reason=missing_dbus_daemon"
        return 1
    fi

    DBUS_SESSION_CONFIG=
    for candidate in /usr/share/dbus-1/session.conf /etc/dbus-1/session.conf; do
        if [ -r "$candidate" ]; then
            DBUS_SESSION_CONFIG=$candidate
            break
        fi
    done
    if [ -z "$DBUS_SESSION_CONFIG" ]; then
        log "client_dbus_session_status=fail reason=missing_session_config"
        return 1
    fi

    if [ "$DBUS_SESSION_USER" = steam ] && [ "$DBUS_SESSION_UID_RECORD" -eq 1 ]; then
        if /usr/bin/awk -F: -v uid="$STEAM_UID" '$3 == uid { found=1 } END { exit(found ? 0 : 1) }' /etc/passwd; then
            log "client_dbus_session_passwd_record=existing uid=$STEAM_UID"
        else
            dbus_passwd_backup="$RUNTIME_DIR/passwd.nova-original"
            if ! /usr/bin/cp -p /etc/passwd "$dbus_passwd_backup"; then
                log "client_dbus_session_passwd_record=fail reason=passwd_update"
                return 1
            fi
            dbus_passwd_changed=1
            if ! /bin/printf 'steam:x:%s:%s:Steam:/opt/nova-steam/home:/usr/bin/bash\n' "$STEAM_UID" "$STEAM_GID" >>/etc/passwd; then
                log "client_dbus_session_passwd_record=fail reason=passwd_update"
                return 1
            fi
            log "client_dbus_session_passwd_record=added uid=$STEAM_UID gid=$STEAM_GID"
        fi
    else
        log "client_dbus_session_passwd_record=disabled"
    fi

    dbus_session_runtime_dir="$RUNTIME_DIR/dbus-1"
    dbus_session_dir="$RUNTIME_DIR/dbus-session-$$"
    dbus_session_socket="$dbus_session_dir/bus"
    dbus_session_log="$dbus_session_dir/daemon.log"
    /bin/rm -rf "$dbus_session_runtime_dir"
    /bin/rm -rf "$dbus_session_dir"
    if ! /bin/mkdir -p "$dbus_session_dir" ||
        ! /usr/bin/chown "$STEAM_UID:$STEAM_GID" "$dbus_session_dir" ||
        ! /usr/bin/chmod 700 "$dbus_session_dir"; then
        log "client_dbus_session_status=fail reason=session_dir_setup"
        return 1
    fi
    if [ "$DBUS_SESSION_USER" = steam ]; then
        if ! /bin/mkdir -p "$dbus_session_runtime_dir" ||
            ! /usr/bin/chown "$STEAM_UID:$STEAM_GID" "$dbus_session_runtime_dir" ||
            ! /usr/bin/chmod 700 "$dbus_session_runtime_dir"; then
            log "client_dbus_session_status=fail reason=runtime_dir_setup"
            return 1
        fi
    fi
    log "client_dbus_session_config=$DBUS_SESSION_CONFIG"
    log "client_dbus_session_user=$DBUS_SESSION_USER"
    log "client_dbus_session_socket=$dbus_session_socket"

    if [ "$DBUS_SESSION_USER" = steam ]; then
        run_as_steam /usr/bin/env -u LD_PRELOAD /usr/bin/dbus-daemon \
            --config-file="$DBUS_SESSION_CONFIG" --nofork \
            --address="unix:path=$dbus_session_socket" \
            >"$dbus_session_log" 2>&1 &
    else
        /usr/bin/env -u LD_PRELOAD /usr/bin/dbus-daemon \
            --config-file="$DBUS_SESSION_CONFIG" --nofork \
            --address="unix:path=$dbus_session_socket" \
            >"$dbus_session_log" 2>&1 &
    fi
    dbus_session_pid=$!
    log "client_dbus_session_pid=$dbus_session_pid"

    dbus_session_ready=0
    dbus_session_attempt=0
    while [ "$dbus_session_attempt" -lt 50 ]; do
        if [ -S "$dbus_session_socket" ]; then
            dbus_session_ready=1
            break
        fi
        if ! /usr/bin/kill -0 "$dbus_session_pid" 2>/dev/null; then
            break
        fi
        /usr/bin/sleep 0.1
        dbus_session_attempt=$((dbus_session_attempt + 1))
    done
    if [ "$dbus_session_ready" -ne 1 ]; then
        log "client_dbus_session_status=fail reason=socket_not_ready"
        return 1
    fi

    export DBUS_SESSION_BUS_ADDRESS="unix:path=$dbus_session_socket"
    log "client_dbus_session_status=pass"
    log "client_dbus_session_address=$DBUS_SESSION_BUS_ADDRESS"
    dbus_session_probe_log="$dbus_session_dir/client-probe.log"
    if run_as_steam /usr/bin/env -u LD_PRELOAD /usr/bin/dbus-send \
        --session --print-reply --dest=org.freedesktop.DBus \
        /org/freedesktop/DBus org.freedesktop.DBus.ListNames \
        >"$dbus_session_probe_log" 2>&1; then
        log "client_dbus_session_client_probe=pass"
    else
        log "client_dbus_session_client_probe=fail"
    fi
    if [ -f "$dbus_session_probe_log" ]; then
        log "dbus_session_client_probe_output_begin"
        /bin/cat "$dbus_session_probe_log" >>"$CLIENT_LOG"
        log "dbus_session_client_probe_output_end"
    fi
    return 0
}

start_dbus_system() {
    if [ "$DBUS_SYSTEM_MODE" -eq 0 ]; then
        log "client_dbus_system=disabled"
        return 0
    fi

    log "client_dbus_system=enabled"
    if [ ! -x /usr/bin/dbus-daemon ]; then
        log "client_dbus_system_status=fail reason=missing_dbus_daemon"
        return 1
    fi
    DBUS_SYSTEM_CONFIG=/usr/share/dbus-1/system.conf
    if [ ! -r "$DBUS_SYSTEM_CONFIG" ]; then
        log "client_dbus_system_status=fail reason=missing_system_config"
        return 1
    fi

    dbus_system_dir=/run/dbus
    dbus_system_socket=$dbus_system_dir/system_bus_socket
    dbus_system_pid_file=$dbus_system_dir/pid
    dbus_system_log="$RUNTIME_DIR/dbus-system.log"
    dbus_system_probe_log="$RUNTIME_DIR/dbus-system-probe.log"
    if [ -e "$dbus_system_socket" ]; then
        log "client_dbus_system_status=fail reason=stale_socket"
        return 1
    fi
    if [ ! -d "$dbus_system_dir" ]; then
        if ! /bin/mkdir -p "$dbus_system_dir"; then
            log "client_dbus_system_status=fail reason=system_dir_setup"
            return 1
        fi
        dbus_system_dir_created=1
    fi
    /bin/rm -f "$dbus_system_pid_file"
    : >"$dbus_system_log"
    dbus_system_started=1
    /usr/bin/env -u LD_PRELOAD /usr/bin/dbus-daemon \
        --config-file="$DBUS_SYSTEM_CONFIG" --nofork \
        >"$dbus_system_log" 2>&1 &
    dbus_system_pid=$!
    log "client_dbus_system_config=$DBUS_SYSTEM_CONFIG"
    log "client_dbus_system_pid=$dbus_system_pid"
    log "client_dbus_system_socket=$dbus_system_socket"

    dbus_system_ready=0
    dbus_system_attempt=0
    while [ "$dbus_system_attempt" -lt 50 ]; do
        if [ -S "$dbus_system_socket" ]; then
            dbus_system_ready=1
            break
        fi
        if ! /usr/bin/kill -0 "$dbus_system_pid" 2>/dev/null; then
            break
        fi
        /usr/bin/sleep 0.1
        dbus_system_attempt=$((dbus_system_attempt + 1))
    done
    if [ "$dbus_system_ready" -ne 1 ]; then
        log "client_dbus_system_status=fail reason=socket_not_ready"
        return 1
    fi
    log "client_dbus_system_status=pass"
    if run_as_steam /usr/bin/env -u LD_PRELOAD /usr/bin/dbus-send \
        --system --print-reply --dest=org.freedesktop.DBus \
        /org/freedesktop/DBus org.freedesktop.DBus.ListNames \
        >"$dbus_system_probe_log" 2>&1; then
        log "client_dbus_system_client_probe=pass"
    else
        log "client_dbus_system_client_probe=fail"
    fi
    log "dbus_system_client_probe_output_begin"
    /bin/cat "$dbus_system_probe_log" >>"$CLIENT_LOG"
    log "dbus_system_client_probe_output_end"
    return 0
}

if ! start_dbus_system; then
    exit 1
fi
if ! start_dbus_session; then
    exit 1
fi

set -- "$STEAM_EXECUTABLE" \
    -gamepadui -steamos3 -steampal -steamdeck \
    -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui \
    -no-cef-sandbox
if [ "$CEF_DISABLE_GPU" -eq 1 ]; then
    set -- "$@" -cef-disable-gpu
fi
if [ "$STEAM_FULLSCREEN" -eq 1 ]; then
    set -- "$@" -fullscreen
fi
if [ "$STEAM_FULLDESKTOPRES" -eq 1 ]; then
    set -- "$@" -fulldesktopres
fi
if [ -n "$STEAM_WIDTH" ]; then
    set -- "$@" -w "$STEAM_WIDTH" -h "$STEAM_HEIGHT"
fi
log "client_flags_final=$*"
run_as_steam /usr/bin/timeout "$CLIENT_TIMEOUT" "$@" \
    >"$CLIENT_STDOUT" 2>"$CLIENT_STDERR" &
client_pid=$!
log "client_pid=$client_pid"
if /usr/bin/kill -0 "$client_pid" 2>/dev/null; then
    log "client_started=pass"
else
    log "client_started=fail"
fi
wait "$client_pid" 2>/dev/null
client_status=$?
log "client_status=$client_status"
if [ "$client_status" -eq 124 ]; then
    log "client_timeout=expected"
fi
if [ -f "$STEAM_ROOT/package/steam_client_steamdeck_publicbeta_linuxarm64.installed" ]; then
    log "client_installed=pass"
else
    log "client_installed=absent"
fi
log "client_stdout=$(wc -c <"$CLIENT_STDOUT")"
log "client_stderr=$(wc -c <"$CLIENT_STDERR")"
log "client_end $(date +%s)"
exit 0
