#!/system/bin/sh

set -u

ACTION="${1:-}"
ROOT="${2:-/data/local/tmp/nova-holo-rootfs}"
STATE="${3:-/data/local/tmp/nova-android-launcher}"
TERMUX_APK="${4:-}"
APP_DIR="${5:-}"
DISPLAY_NUMBER="${NOVA_ANDROID_LAUNCHER_DISPLAY:-0}"
DISPLAY_VALUE=":$DISPLAY_NUMBER"
X11_SOCKET="$ROOT/tmp/.X11-unix/X$DISPLAY_NUMBER"
PRIVATE_HELPER="$APP_DIR/nova-x11-private-namespace.sh"
CLEANUP_HELPER="$APP_DIR/nova-termux-x11-cleanup.sh"
RUNTIME_CLEANUP="$APP_DIR/nova-runtime-cleanup.sh"
CLIENT_SOURCE="$APP_DIR/nova-termux-x11-steam-client.sh"
RELAY_LAUNCHER="$APP_DIR/nova-uinput-gamepad-relay-launcher.sh"
MOUNT_PRIVATE="$APP_DIR/nova-mount-private"
NETWORK_COMPAT_SOURCE="$APP_DIR/nova-steam-network-api-compat.sh"
STEAMOS_UPDATE_COMPAT_SOURCE="$APP_DIR/nova-steamos-update-compat.sh"
DRIVER_DIR="$ROOT/opt/nova-kgsl-driver"

if [ ! -x "$MOUNT_PRIVATE" ]; then
    if [ -x /data/local/tmp/nova-mount-private ]; then
        MOUNT_PRIVATE=/data/local/tmp/nova-mount-private
    elif [ -x "$ROOT/opt/nova-kgsl-driver/nova-mount-private" ]; then
        MOUNT_PRIVATE="$ROOT/opt/nova-kgsl-driver/nova-mount-private"
    fi
fi

log() {
    line="$1"
    echo "$line"
    if [ -n "$STATE" ]; then
        mkdir -p "$STATE"
        echo "$line" >>"$STATE/launcher.log"
    fi
}

read_state() {
    path="$STATE/$1"
    if [ -r "$path" ]; then
        /system/bin/cat "$path"
    fi
}

runtime_present() {
    /system/bin/ps -A -o PID,ARGS 2>/dev/null |
        /system/bin/awk -v root="$ROOT" '
            NR > 1 && !index($0, "awk") &&
                (index($0, "/opt/nova-steam") ||
                       index($0, "/opt/nova-kgsl-driver/gamescope-headless") ||
                       index($0, "/opt/nova-kgsl-driver/nova-uinput-gamepad-relay")) {
                found = 1
            }
            END { exit found ? 0 : 1 }
        '
}

stop_session() {
    if [ ! -d "$STATE" ] || [ ! -f "$STATE/server-token" ]; then
        log "nova_launcher_stop=not_running"
        exit 0
    fi

    cleanup_status=0
    if [ -x "$CLEANUP_HELPER" ] && [ -x "$PRIVATE_HELPER" ]; then
        /system/bin/sh "$CLEANUP_HELPER" cleanup "$STATE" "$PRIVATE_HELPER" runtime \
            >>"$STATE/cleanup.log" 2>&1 || cleanup_status=$?
    else
        log "nova_launcher_cleanup=missing_helper"
        cleanup_status=1
    fi
    if [ -x "$RUNTIME_CLEANUP" ]; then
        /system/bin/sh "$RUNTIME_CLEANUP" "$ROOT" >>"$STATE/runtime-cleanup.log" 2>&1 || cleanup_status=$?
    fi

    for path in \
        "$(read_state client.path)" \
        "$(read_state capture.path)" \
        "$(read_state ppm.path)" \
        "$(read_state socket.path)" \
        "$(read_state lock.path)"; do
        if [ -n "$path" ]; then
            /system/bin/rm -f "$path"
        fi
    done
    /system/bin/rm -f "$STATE/server.pid" "$STATE/client.pid" \
        "$STATE/relay.pid" "$STATE/client-active"
    if [ "$cleanup_status" -eq 0 ]; then
        log "nova_launcher_stop=pass"
        exit 0
    fi
    log "nova_launcher_stop=fail status=$cleanup_status"
    exit "$cleanup_status"
}

if [ "$ACTION" = "stop" ]; then
    stop_session
fi
if [ "$ACTION" != "start" ]; then
    log "nova_launcher_error=usage"
    exit 2
fi

if [ -z "$TERMUX_APK" ] || [ ! -f "$TERMUX_APK" ]; then
    log "nova_launcher_start=fail reason=missing_termux_x11_apk"
    exit 1
fi
if [ ! -d "$ROOT" ]; then
    log "nova_launcher_start=fail reason=missing_rootfs path=$ROOT"
    exit 1
fi
if [ ! -x "$PRIVATE_HELPER" ] || [ ! -x "$CLEANUP_HELPER" ] || \
    [ ! -x "$CLIENT_SOURCE" ] || [ ! -x "$RELAY_LAUNCHER" ] || \
    [ ! -x "$NETWORK_COMPAT_SOURCE" ] || [ ! -x "$STEAMOS_UPDATE_COMPAT_SOURCE" ]; then
    log "nova_launcher_start=fail reason=missing_launcher_asset"
    exit 1
fi
if [ ! -x "$MOUNT_PRIVATE" ]; then
    log "nova_launcher_start=fail reason=missing_mount_private_helper"
    exit 1
fi
if [ -S "$X11_SOCKET" ]; then
    log "nova_launcher_start=fail reason=existing_x11_socket path=$X11_SOCKET"
    exit 1
fi
if runtime_present; then
    log "nova_launcher_start=fail reason=existing_nova_runtime"
    exit 1
fi

mkdir -p "$STATE" "$ROOT/tmp/.X11-unix"
mkdir -p "$DRIVER_DIR" "$ROOT/usr/bin/steamos-polkit-helpers"
/system/bin/cp "$NETWORK_COMPAT_SOURCE" "$DRIVER_DIR/nova-steam-network-api-compat.sh"
/system/bin/cp "$STEAMOS_UPDATE_COMPAT_SOURCE" \
    "$ROOT/usr/bin/steamos-polkit-helpers/steamos-update"
/system/bin/chmod 755 "$DRIVER_DIR/nova-steam-network-api-compat.sh" \
    "$ROOT/usr/bin/steamos-polkit-helpers/steamos-update"
for driver_asset in \
    nova-uinput-gamepad-relay \
    libsysv-sem-shim.so \
    libffmpeg-avutil-compat.so \
    libsdl3-compat.so \
    libposix-sync-trace.so; do
    if [ -f "$APP_DIR/$driver_asset" ]; then
        /system/bin/cp "$APP_DIR/$driver_asset" "$DRIVER_DIR/$driver_asset"
        /system/bin/chmod 755 "$DRIVER_DIR/$driver_asset"
    fi
done
/system/bin/rm -f "$STATE/launcher.log" "$STATE/cleanup.log" \
    "$STATE/runtime-cleanup.log" "$STATE/server.log" "$STATE/client.log" \
    "$STATE/relay.log" "$STATE/activity.log" "$STATE/ready"

session="$(date -u '+%Y%m%dT%H%M%SZ')-$$"
CLIENT_STAGE="$ROOT/tmp/nova-android-launcher-steam-$session.sh"
RELAY_STAGE="$ROOT/tmp/nova-android-launcher-relay-$session.sh"
CAPTURE_STAGE="$ROOT/tmp/nova-android-launcher-capture-$session"
PPM_STAGE="$ROOT/tmp/nova-android-launcher-$session.ppm"
LOCK_STAGE="$ROOT/tmp/.nova-android-launcher-$session-lock"
CLIENT_STAGE_NAME="${CLIENT_STAGE##*/}"
RELAY_BINARY="$ROOT/opt/nova-kgsl-driver/nova-uinput-gamepad-relay"
if [ ! -x "$RELAY_BINARY" ] && [ -x "$APP_DIR/nova-uinput-gamepad-relay" ]; then
    mkdir -p "$ROOT/opt/nova-kgsl-driver"
    /system/bin/cp "$APP_DIR/nova-uinput-gamepad-relay" "$RELAY_BINARY"
    /system/bin/chmod 755 "$RELAY_BINARY"
fi

/system/bin/cp "$CLIENT_SOURCE" "$CLIENT_STAGE"
/system/bin/cp "$RELAY_LAUNCHER" "$RELAY_STAGE"
/system/bin/chmod 755 "$CLIENT_STAGE" "$RELAY_STAGE"

printf '%s\n' "$CLIENT_STAGE" >"$STATE/client.path"
printf '%s\n' "$CAPTURE_STAGE" >"$STATE/capture.path"
printf '%s\n' "$PPM_STAGE" >"$STATE/ppm.path"
printf '%s\n' "$X11_SOCKET" >"$STATE/socket.path"
printf '%s\n' "$LOCK_STAGE" >"$STATE/lock.path"
printf '%s\n' "termux-x11" >"$STATE/server-token"
printf '%s\n' "$CLIENT_STAGE_NAME" >"$STATE/client-token"
printf '%s\n' "1" >"$STATE/client-active"
printf '%s\n' "$session" >"$STATE/session"

if [ -x "$RELAY_BINARY" ]; then
    hide_input_events=
    NOVA_RELAY_MOUNT_PRIVATE_HELPER="$MOUNT_PRIVATE" \
        /system/bin/sh "$RELAY_STAGE" "$ROOT" "$RELAY_BINARY" \
        /dev/input/event7 86400000 relay >"$STATE/relay.log" 2>&1 &
    relay_pid=$!
    printf '%s\n' "$relay_pid" >"$STATE/relay.pid"
    relay_ready=0
    attempt=0
    while [ "$attempt" -lt 30 ]; do
        if /system/bin/grep -q 'uinput_device_ready=pass' "$STATE/relay.log" 2>/dev/null; then
            relay_ready=1
            break
        fi
        if /system/bin/grep -q 'uinput_error=' "$STATE/relay.log" 2>/dev/null; then
            break
        fi
        /system/bin/sleep 0.2
        attempt=$((attempt + 1))
    done
    if [ "$relay_ready" -eq 1 ]; then
        log "nova_launcher_gamepad=pass"
        hide_input_events=7
        log "nova_launcher_input_hide=event7"
    else
        log "nova_launcher_gamepad=not_ready"
    fi
else
    hide_input_events=
    log "nova_launcher_gamepad=skipped reason=missing_relay_binary"
fi

: >"$STATE/server.log"
/system/bin/env TMPDIR="$ROOT/tmp" \
    XKB_CONFIG_ROOT="$ROOT/usr/share/xkeyboard-config-2" \
    CLASSPATH="$TERMUX_APK" TERMUX_X11_DEBUG=1 \
    /system/bin/app_process / --nice-name=termux-x11 \
    com.termux.x11.CmdEntryPoint "$DISPLAY_VALUE" \
    >"$STATE/server.log" 2>&1 &
server_pid=$!
printf '%s\n' "$server_pid" >"$STATE/server.pid"
log "nova_launcher_x11_pid=$server_pid"

socket_ready=0
attempt=0
while [ "$attempt" -lt 80 ]; do
    if [ -S "$X11_SOCKET" ]; then
        socket_ready=1
        break
    fi
    if ! /system/bin/kill -0 "$server_pid" 2>/dev/null; then
        break
    fi
    /system/bin/sleep 0.25
    attempt=$((attempt + 1))
done
if [ "$socket_ready" -ne 1 ]; then
    log "nova_launcher_start=fail reason=x11_socket_not_ready"
    stop_session
fi

/system/bin/am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity \
    >"$STATE/activity.log" 2>&1 || log "nova_launcher_x11_activity=unknown"

/system/bin/env -i \
    PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp TMPDIR=/tmp \
    DISPLAY="$DISPLAY_VALUE" XKB_CONFIG_ROOT=/usr/share/X11/xkb \
    NOVA_TERMUX_X11_STEAM_TIMEOUT_SECONDS=86400 \
    NOVA_TERMUX_X11_DBUS_SESSION=1 \
    NOVA_TERMUX_X11_DBUS_SESSION_USER=steam \
    NOVA_TERMUX_X11_DBUS_SESSION_UID_RECORD=1 \
    NOVA_TERMUX_X11_DBUS_SYSTEM=1 \
    NOVA_TERMUX_X11_STEAM_FULLSCREEN=1 \
    NOVA_TERMUX_X11_STEAM_FULLDESKTOPRES=1 \
    NOVA_X11_HIDE_INPUT_EVENTS="$hide_input_events" \
    "$PRIVATE_HELPER" chroot-dev "$MOUNT_PRIVATE" "$ROOT" \
    /tmp/"$CLIENT_STAGE_NAME" >"$STATE/client.log" 2>&1 &
client_pid=$!
printf '%s\n' "$client_pid" >"$STATE/client.pid"
log "nova_launcher_steam_pid=$client_pid"
log "nova_launcher_ready=pass display=$DISPLAY_VALUE geometry=1280x960"
printf '%s\n' "pass" >"$STATE/ready"

wait "$client_pid"
client_status=$?
log "nova_launcher_client_exit=$client_status"
stop_session
