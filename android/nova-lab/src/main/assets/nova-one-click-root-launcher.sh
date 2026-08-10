#!/system/bin/sh

set -u

ACTION="${1:-}"
ROOT_ARGUMENT="${2:-/data/local/tmp/nova-holo-rootfs}"
ROOT="$ROOT_ARGUMENT"
VERSIONED_RUNTIME=0
if [ "$ROOT_ARGUMENT" = "/data/local/tmp/nova-active-runtime" ]; then
    if [ -f "$ROOT_ARGUMENT" ]; then
        active_root=$(/system/bin/tr -d '\r\n' <"$ROOT_ARGUMENT")
        case "$active_root" in
            /data/local/tmp/nova-runtimes/*/rootfs)
                ROOT="$active_root"
                VERSIONED_RUNTIME=1
                ;;
            *)
                ROOT=/data/local/tmp/nova-holo-rootfs
                ;;
        esac
    else
        ROOT=/data/local/tmp/nova-holo-rootfs
    fi
fi
STATE="${3:-/data/local/tmp/nova-android-launcher}"
TERMUX_APK="${4:-}"
APP_DIR="${5:-}"
DISPLAY_NUMBER="${NOVA_ANDROID_LAUNCHER_DISPLAY:-0}"
DISPLAY_VALUE=":$DISPLAY_NUMBER"
HARDWARE_ACCEL="${NOVA_ANDROID_LAUNCHER_HARDWARE_ACCEL:-0}"
VULKAN_ICD="${NOVA_ANDROID_LAUNCHER_VULKAN_ICD:-/opt/nova-kgsl-driver/freedreno-kgsl.icd.json}"
CEF_DISABLE_GPU="${NOVA_ANDROID_LAUNCHER_CEF_DISABLE_GPU:-}"
STEAM_UI_MODE="${NOVA_ANDROID_LAUNCHER_STEAM_UI_MODE:-gamepadui}"
STEAM_DISABLE_PRELOAD="${NOVA_ANDROID_LAUNCHER_STEAM_DISABLE_PRELOAD:-0}"
STEAM_DISABLE_SYSTEM_DBUS="${NOVA_ANDROID_LAUNCHER_STEAM_DISABLE_SYSTEM_DBUS:-0}"
STEAM_HOLO_MESA_FIRST="${NOVA_ANDROID_LAUNCHER_STEAM_HOLO_MESA_FIRST:-0}"
STEAM_FORCE_SOFTWARE_GL="${NOVA_ANDROID_LAUNCHER_STEAM_FORCE_SOFTWARE_GL:-0}"
STEAM_CEF_ENV_SPLIT="${NOVA_ANDROID_LAUNCHER_STEAM_CEF_ENV_SPLIT:-0}"
STEAMOS_UPDATE_COMPAT="${NOVA_ANDROID_LAUNCHER_STEAMOS_UPDATE_COMPAT:-1}"
STEAM_RESTART_LIMIT="${NOVA_ANDROID_LAUNCHER_STEAM_RESTART_LIMIT:-1}"
AUDIO_BRIDGE="${NOVA_ANDROID_LAUNCHER_AUDIO_BRIDGE:-0}"
AUDIO_BRIDGE_PORT="${NOVA_ANDROID_LAUNCHER_AUDIO_BRIDGE_PORT:-29100}"
X11_STRETCH="${NOVA_ANDROID_LAUNCHER_X11_STRETCH:-1}"
X11_STRETCH_RESOLUTION="${NOVA_ANDROID_LAUNCHER_X11_STRETCH_RESOLUTION:-1280x800}"
X11_HIDE_EXTRA_KEYBAR="${NOVA_ANDROID_LAUNCHER_X11_HIDE_EXTRA_KEYBAR:-1}"
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
TERMUX_PREFS=/data/user/0/com.termux.x11/shared_prefs/com.termux.x11_preferences.xml
TERMUX_PREFS_BACKUP="$STATE/termux-x11-preferences.before.xml"
TERMUX_PREFS_META="$STATE/termux-x11-preferences.meta"
TERMUX_PREFS_TEMP="$STATE/termux-x11-preferences.tmp.xml"

case "$HARDWARE_ACCEL" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_ANDROID_LAUNCHER_HARDWARE_ACCEL: $HARDWARE_ACCEL" >&2
        exit 2
        ;;
esac
if [ -z "$CEF_DISABLE_GPU" ]; then
    case "$HARDWARE_ACCEL" in
        0) CEF_DISABLE_GPU=1 ;;
        1) CEF_DISABLE_GPU=0 ;;
    esac
fi
case "$CEF_DISABLE_GPU" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_ANDROID_LAUNCHER_CEF_DISABLE_GPU: $CEF_DISABLE_GPU" >&2
        exit 2
        ;;
esac
case "$STEAM_UI_MODE" in
    gamepadui|minimal)
        ;;
    *)
        echo "invalid NOVA_ANDROID_LAUNCHER_STEAM_UI_MODE: $STEAM_UI_MODE" >&2
        exit 2
        ;;
esac
case "$STEAM_DISABLE_PRELOAD" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_ANDROID_LAUNCHER_STEAM_DISABLE_PRELOAD: $STEAM_DISABLE_PRELOAD" >&2
        exit 2
        ;;
esac
case "$STEAM_DISABLE_SYSTEM_DBUS" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_ANDROID_LAUNCHER_STEAM_DISABLE_SYSTEM_DBUS: $STEAM_DISABLE_SYSTEM_DBUS" >&2
        exit 2
        ;;
esac
case "$STEAM_HOLO_MESA_FIRST" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_ANDROID_LAUNCHER_STEAM_HOLO_MESA_FIRST: $STEAM_HOLO_MESA_FIRST" >&2
        exit 2
        ;;
esac
case "$STEAM_FORCE_SOFTWARE_GL" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_ANDROID_LAUNCHER_STEAM_FORCE_SOFTWARE_GL: $STEAM_FORCE_SOFTWARE_GL" >&2
        exit 2
        ;;
esac
case "$STEAM_CEF_ENV_SPLIT" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_ANDROID_LAUNCHER_STEAM_CEF_ENV_SPLIT: $STEAM_CEF_ENV_SPLIT" >&2
        exit 2
        ;;
esac
case "$STEAMOS_UPDATE_COMPAT" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_ANDROID_LAUNCHER_STEAMOS_UPDATE_COMPAT: $STEAMOS_UPDATE_COMPAT" >&2
        exit 2
        ;;
esac
case "$STEAM_RESTART_LIMIT" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_ANDROID_LAUNCHER_STEAM_RESTART_LIMIT: $STEAM_RESTART_LIMIT (expected 0 or 1)" >&2
        exit 2
        ;;
esac
DBUS_SYSTEM_MODE=1
if [ "$STEAM_DISABLE_SYSTEM_DBUS" -eq 1 ]; then
    DBUS_SYSTEM_MODE=0
fi
case "$VULKAN_ICD" in
    /*)
        ;;
    *)
        echo "NOVA_ANDROID_LAUNCHER_VULKAN_ICD must be an absolute path: $VULKAN_ICD" >&2
        exit 2
        ;;
esac
case "$AUDIO_BRIDGE" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_ANDROID_LAUNCHER_AUDIO_BRIDGE: $AUDIO_BRIDGE" >&2
        exit 2
        ;;
esac
case "$AUDIO_BRIDGE_PORT" in
    ''|*[!0-9]*)
        echo "invalid NOVA_ANDROID_LAUNCHER_AUDIO_BRIDGE_PORT: $AUDIO_BRIDGE_PORT" >&2
        exit 2
        ;;
esac
if [ "$AUDIO_BRIDGE_PORT" -lt 1024 ] || [ "$AUDIO_BRIDGE_PORT" -gt 65535 ]; then
    echo "NOVA_ANDROID_LAUNCHER_AUDIO_BRIDGE_PORT out of range: $AUDIO_BRIDGE_PORT" >&2
    exit 2
fi
case "$X11_STRETCH" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_ANDROID_LAUNCHER_X11_STRETCH: $X11_STRETCH" >&2
        exit 2
        ;;
esac
case "$X11_STRETCH_RESOLUTION" in
    1280x800)
        ;;
    *)
        echo "unsupported NOVA_ANDROID_LAUNCHER_X11_STRETCH_RESOLUTION: $X11_STRETCH_RESOLUTION" >&2
        exit 2
        ;;
esac
case "$X11_HIDE_EXTRA_KEYBAR" in
    0|1)
        ;;
    *)
        echo "invalid NOVA_ANDROID_LAUNCHER_X11_HIDE_EXTRA_KEYBAR: $X11_HIDE_EXTRA_KEYBAR" >&2
        exit 2
        ;;
esac
X11_EXTRA_KBD_VALUE=true
if [ "$X11_HIDE_EXTRA_KEYBAR" -eq 1 ]; then
    X11_EXTRA_KBD_VALUE=false
fi

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

prepare_versioned_runtime_resolver() {
    if [ "$VERSIONED_RUNTIME" -ne 1 ]; then
        log "nova_launcher_resolver=legacy-preserved"
        return 0
    fi

    if [ ! -x /system/bin/dumpsys ]; then
        log "nova_launcher_resolver=unavailable reason=missing_dumpsys"
        return 0
    fi

    dns_addresses=$(
        /system/bin/dumpsys connectivity 2>/dev/null |
            /system/bin/grep -m 1 'DnsAddresses:' |
            /system/bin/sed 's/.*DnsAddresses: \[//; s/\] Domains.*//' |
            /system/bin/tr ',' '\n' |
            /system/bin/sed 's#^[[:space:]/]*##; s#[[:space:]/]*$##'
    )
    resolver_tmp="$ROOT/etc/resolv.conf.nova.$$"
    /system/bin/mkdir -p "$ROOT/etc"
    /system/bin/rm -f "$resolver_tmp"
    for dns in $dns_addresses; do
        case "$dns" in
            ''|*[!0-9A-Fa-f:.-]*)
                continue
                ;;
        esac
        /system/bin/printf 'nameserver %s\n' "$dns" >>"$resolver_tmp"
    done
    if [ -s "$resolver_tmp" ]; then
        /system/bin/chmod 644 "$resolver_tmp"
        /system/bin/mv -f "$resolver_tmp" "$ROOT/etc/resolv.conf"
        log "nova_launcher_resolver=pass dns=$(/system/bin/tr '\n' ',' <"$ROOT/etc/resolv.conf" | /system/bin/sed 's/,*$//')"
    else
        /system/bin/rm -f "$resolver_tmp"
        log "nova_launcher_resolver=unavailable reason=no_android_dns"
    fi
}

log "nova_launcher_root=$ROOT"

read_state() {
    path="$STATE/$1"
    if [ -r "$path" ]; then
        /system/bin/cat "$path"
    fi
}

clear_stale_dbus_state() {
    dbus_socket="$ROOT/run/dbus/system_bus_socket"
    dbus_pid="$ROOT/run/dbus/pid"
    if [ ! -e "$dbus_socket" ] && [ ! -e "$dbus_pid" ]; then
        log "nova_launcher_dbus_state=absent"
        return 0
    fi
    if ! /system/bin/rm -f "$dbus_socket" "$dbus_pid" ||
        [ -e "$dbus_socket" ] || [ -e "$dbus_pid" ]; then
        log "nova_launcher_dbus_state=fail"
        return 1
    fi
    log "nova_launcher_dbus_state=cleared"
    return 0
}

parent_pid() {
    target_pid="$1"
    /system/bin/ps -A -o PID,PPID 2>/dev/null |
        /system/bin/awk -v target="$target_pid" \
            'NR > 1 && $1 == target { print $2; exit }' |
        /system/bin/tr -d '\r'
}

append_cleanup_ancestors() {
    ancestor_pid="${PPID:-}"
    depth=0
    while [ "$depth" -lt 16 ]; do
        case "$ancestor_pid" in
            ''|*[!0-9]*|0|1)
                break
                ;;
        esac
        cleanup_exclude_pids="$cleanup_exclude_pids $ancestor_pid"
        next_pid="$(parent_pid "$ancestor_pid")"
        if [ "$next_pid" = "$ancestor_pid" ]; then
            break
        fi
        ancestor_pid="$next_pid"
        depth=$((depth + 1))
    done
}

restore_x11_preferences() {
    if [ ! -f "$TERMUX_PREFS_BACKUP" ]; then
        return 0
    fi
    /system/bin/am force-stop com.termux.x11 >/dev/null 2>&1 || true
    if ! /system/bin/cp "$TERMUX_PREFS_BACKUP" "$TERMUX_PREFS"; then
        log "nova_launcher_x11_stretch_restore=fail reason=copy"
        return 1
    fi
    if [ -r "$TERMUX_PREFS_META" ]; then
        owner=$(/system/bin/sed -n '1p' "$TERMUX_PREFS_META")
        group=$(/system/bin/sed -n '2p' "$TERMUX_PREFS_META")
        mode=$(/system/bin/sed -n '3p' "$TERMUX_PREFS_META")
        if [ -n "$owner" ] && [ -n "$group" ] && [ -n "$mode" ]; then
            /system/bin/chown "$owner:$group" "$TERMUX_PREFS" || return 1
            /system/bin/chmod "$mode" "$TERMUX_PREFS" || return 1
        fi
    fi
    /system/bin/rm -f "$TERMUX_PREFS_BACKUP" "$TERMUX_PREFS_META" "$TERMUX_PREFS_TEMP"
    /system/bin/rm -f "$STATE/termux-x11-preferences.changed"
    log "nova_launcher_x11_stretch_restore=pass"
    return 0
}

apply_x11_stretch() {
    if [ "$X11_STRETCH" -eq 0 ]; then
        log "nova_launcher_x11_stretch=0"
        return 0
    fi
    if [ ! -f "$TERMUX_PREFS" ]; then
        log "nova_launcher_x11_stretch=fail reason=missing_preferences"
        return 1
    fi
    if [ -f "$TERMUX_PREFS_BACKUP" ]; then
        if ! restore_x11_preferences; then
            return 1
        fi
    fi
    if ! /system/bin/stat -c '%u\n%g\n%a\n' "$TERMUX_PREFS" >"$TERMUX_PREFS_META" ||
        ! /system/bin/cp "$TERMUX_PREFS" "$TERMUX_PREFS_BACKUP" ||
        ! /system/bin/cp "$TERMUX_PREFS" "$TERMUX_PREFS_TEMP"; then
        log "nova_launcher_x11_stretch=fail reason=backup"
        /system/bin/rm -f "$TERMUX_PREFS_BACKUP" "$TERMUX_PREFS_META" "$TERMUX_PREFS_TEMP"
        return 1
    fi
    /system/bin/sed -i \
        -e 's#<string name="displayResolutionMode">[^<]*</string>#<string name="displayResolutionMode">custom</string>#' \
        -e "s#<string name=\"displayResolutionExact\">[^<]*</string>#<string name=\"displayResolutionExact\">$X11_STRETCH_RESOLUTION</string>#" \
        -e "s#<string name=\"displayResolutionCustom\">[^<]*</string>#<string name=\"displayResolutionCustom\">$X11_STRETCH_RESOLUTION</string>#" \
        -e 's#<boolean name="displayStretch" value="[^"]*" />#<boolean name="displayStretch" value="true" />#' \
        -e "s#<boolean name=\"showAdditionalKbd\" value=\"[^\"]*\" />#<boolean name=\"showAdditionalKbd\" value=\"$X11_EXTRA_KBD_VALUE\" />#" \
        -e "s#<boolean name=\"additionalKbdVisible\" value=\"[^\"]*\" />#<boolean name=\"additionalKbdVisible\" value=\"$X11_EXTRA_KBD_VALUE\" />#" \
        "$TERMUX_PREFS_TEMP" || {
        log "nova_launcher_x11_stretch=fail reason=rewrite"
        restore_x11_preferences
        return 1
    }
    if ! /system/bin/grep -q 'name="displayResolutionMode">custom' "$TERMUX_PREFS_TEMP" ||
        ! /system/bin/grep -q "name=\"displayResolutionExact\">$X11_STRETCH_RESOLUTION" "$TERMUX_PREFS_TEMP" ||
        ! /system/bin/grep -q "name=\"displayResolutionCustom\">$X11_STRETCH_RESOLUTION" "$TERMUX_PREFS_TEMP" ||
        ! /system/bin/grep -q 'name="displayStretch" value="true"' "$TERMUX_PREFS_TEMP" ||
        ! /system/bin/grep -q "name=\"showAdditionalKbd\" value=\"$X11_EXTRA_KBD_VALUE\"" "$TERMUX_PREFS_TEMP" ||
        ! /system/bin/grep -q "name=\"additionalKbdVisible\" value=\"$X11_EXTRA_KBD_VALUE\"" "$TERMUX_PREFS_TEMP" ||
        ! /system/bin/cp "$TERMUX_PREFS_TEMP" "$TERMUX_PREFS"; then
        log "nova_launcher_x11_stretch=fail reason=verify"
        restore_x11_preferences
        return 1
    fi
    owner=$(/system/bin/sed -n '1p' "$TERMUX_PREFS_META")
    group=$(/system/bin/sed -n '2p' "$TERMUX_PREFS_META")
    mode=$(/system/bin/sed -n '3p' "$TERMUX_PREFS_META")
    if [ -n "$owner" ] && [ -n "$group" ] && [ -n "$mode" ]; then
        /system/bin/chown "$owner:$group" "$TERMUX_PREFS" || {
            restore_x11_preferences
            return 1
        }
        /system/bin/chmod "$mode" "$TERMUX_PREFS" || {
            restore_x11_preferences
            return 1
        }
    fi
    /system/bin/rm -f "$TERMUX_PREFS_TEMP"
    /system/bin/am force-stop com.termux.x11 >/dev/null 2>&1 || true
    : >"$STATE/termux-x11-preferences.changed"
    log "nova_launcher_x11_stretch=1 resolution=$X11_STRETCH_RESOLUTION"
    return 0
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
        if [ -f "$TERMUX_PREFS_BACKUP" ]; then
            restore_x11_preferences || exit 1
        fi
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
    if ! restore_x11_preferences; then
        cleanup_status=1
    fi
    cleanup_exclude_pids="$$"
    append_cleanup_ancestors
    log "nova_launcher_cleanup_exclude_pids=$cleanup_exclude_pids"
    if [ -x "$RUNTIME_CLEANUP" ]; then
        runtime_cleanup_status=0
        NOVA_RUNTIME_CLEANUP_EXCLUDE_PIDS="$cleanup_exclude_pids" \
            /system/bin/sh "$RUNTIME_CLEANUP" "$ROOT" \
            >>"$STATE/runtime-cleanup.log" 2>&1 || runtime_cleanup_status=$?
        if [ "$runtime_cleanup_status" -ne 0 ]; then
            cleanup_status=$runtime_cleanup_status
        fi
        if [ "$runtime_cleanup_status" -eq 0 ]; then
            if ! clear_stale_dbus_state; then
                cleanup_status=1
            fi
        else
            log "nova_launcher_dbus_state=skipped reason=runtime_cleanup"
        fi
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
if ! clear_stale_dbus_state; then
    log "nova_launcher_start=fail reason=stale_dbus_state"
    exit 1
fi

prepare_versioned_runtime_resolver

mkdir -p "$STATE" "$ROOT/tmp/.X11-unix"
mkdir -p "$DRIVER_DIR" "$ROOT/usr/bin/steamos-polkit-helpers"
/system/bin/cp "$NETWORK_COMPAT_SOURCE" "$DRIVER_DIR/nova-steam-network-api-compat.sh"
/system/bin/chmod 755 "$DRIVER_DIR/nova-steam-network-api-compat.sh"
if [ "$STEAMOS_UPDATE_COMPAT" -eq 1 ]; then
    /system/bin/cp "$STEAMOS_UPDATE_COMPAT_SOURCE" \
        "$ROOT/usr/bin/steamos-polkit-helpers/steamos-update"
    /system/bin/chmod 755 "$ROOT/usr/bin/steamos-polkit-helpers/steamos-update"
    log "nova_launcher_steamos_update_compat=enabled"
else
    /system/bin/rm -f "$ROOT/usr/bin/steamos-polkit-helpers/steamos-update"
    log "nova_launcher_steamos_update_compat=disabled"
fi
for driver_asset in \
    nova-uinput-gamepad-relay \
    libsysv-sem-shim.so \
    libnova-cef-env-split.so \
    libffmpeg-avutil-compat.so \
    libsdl3-compat.so \
    libposix-sync-trace.so \
    libnova-alsa-audiotrack-bridge.so; do
    if [ -f "$APP_DIR/$driver_asset" ]; then
        /system/bin/cp "$APP_DIR/$driver_asset" "$DRIVER_DIR/$driver_asset"
        /system/bin/chmod 755 "$DRIVER_DIR/$driver_asset"
    fi
done
/system/bin/rm -f "$STATE/launcher.log" "$STATE/cleanup.log" \
    "$STATE/runtime-cleanup.log" "$STATE/server.log" "$STATE/client.log" \
    "$STATE/relay.log" "$STATE/activity.log" "$STATE/ready"

if [ -f "$TERMUX_PREFS_BACKUP" ]; then
    if ! restore_x11_preferences; then
        log "nova_launcher_start=fail reason=stale_x11_preferences_backup"
        exit 1
    fi
fi
/system/bin/rm -f "$STATE/server-token" "$STATE/client-active" \
    "$STATE/server.pid" "$STATE/client.pid" "$STATE/relay.pid"

if ! apply_x11_stretch; then
    log "nova_launcher_start=fail reason=x11_stretch_preferences"
    exit 1
fi

session="$(date -u '+%Y%m%dT%H%M%SZ')-$$"
printf '%s\n' "$session" >"$STATE/session"
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
log "nova_launcher_hardware_accel=$HARDWARE_ACCEL"
log "nova_launcher_vulkan_icd=$VULKAN_ICD"
log "nova_launcher_cef_disable_gpu=$CEF_DISABLE_GPU"
log "nova_launcher_steam_ui_mode=$STEAM_UI_MODE"
log "nova_launcher_steam_disable_preload=$STEAM_DISABLE_PRELOAD"
log "nova_launcher_steam_disable_system_dbus=$STEAM_DISABLE_SYSTEM_DBUS"
log "nova_launcher_steam_holo_mesa_first=$STEAM_HOLO_MESA_FIRST"
log "nova_launcher_steam_force_software_gl=$STEAM_FORCE_SOFTWARE_GL"
log "nova_launcher_steam_cef_env_split=$STEAM_CEF_ENV_SPLIT"
log "nova_launcher_steam_restart_limit=$STEAM_RESTART_LIMIT"
log "nova_launcher_audio_bridge=$AUDIO_BRIDGE"
log "nova_launcher_audio_bridge_port=$AUDIO_BRIDGE_PORT"
log "nova_launcher_x11_hide_extra_keybar=$X11_HIDE_EXTRA_KEYBAR"

if [ -x "$RELAY_BINARY" ]; then
    allow_input_events=
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
        relay_event_name=$(
            /system/bin/sed -n \
                's#^uinput_device=/dev/input/\(event[0-9][0-9]*\)$#\1#p' \
                "$STATE/relay.log" | /system/bin/sed -n '1p'
        )
        case "$relay_event_name" in
            event[0-9]*)
                allow_input_events="${relay_event_name#event}"
                log "nova_launcher_gamepad=pass"
                log "nova_launcher_input_allow=$relay_event_name"
                ;;
            *)
                log "nova_launcher_gamepad=not_ready reason=missing_event_path"
                ;;
        esac
    else
        log "nova_launcher_gamepad=not_ready"
    fi
else
    hide_input_events=
    log "nova_launcher_gamepad=skipped reason=missing_relay_binary"
fi

: >"$STATE/server.log"
/system/bin/am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity \
    >"$STATE/activity.log" 2>&1 || log "nova_launcher_x11_activity=unknown"
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

/system/bin/env -i \
    PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp TMPDIR=/tmp \
    DISPLAY="$DISPLAY_VALUE" XKB_CONFIG_ROOT=/usr/share/X11/xkb \
    NOVA_TERMUX_X11_STEAM_TIMEOUT_SECONDS=86400 \
    NOVA_TERMUX_X11_DBUS_SESSION=1 \
    NOVA_TERMUX_X11_DBUS_SESSION_USER=steam \
    NOVA_TERMUX_X11_DBUS_SESSION_UID_RECORD=1 \
    NOVA_TERMUX_X11_DBUS_SYSTEM="$DBUS_SYSTEM_MODE" \
    NOVA_TERMUX_X11_STEAM_FULLSCREEN=1 \
    NOVA_TERMUX_X11_STEAM_FULLDESKTOPRES=1 \
    NOVA_TERMUX_X11_STEAM_HARDWARE_ACCEL="$HARDWARE_ACCEL" \
    NOVA_TERMUX_X11_STEAM_VULKAN_ICD="$VULKAN_ICD" \
    NOVA_TERMUX_X11_STEAM_CEF_DISABLE_GPU="$CEF_DISABLE_GPU" \
    NOVA_TERMUX_X11_STEAM_UI_MODE="$STEAM_UI_MODE" \
    NOVA_TERMUX_X11_STEAM_DISABLE_PRELOAD="$STEAM_DISABLE_PRELOAD" \
    NOVA_TERMUX_X11_STEAM_HOLO_MESA_FIRST="$STEAM_HOLO_MESA_FIRST" \
    NOVA_TERMUX_X11_STEAM_FORCE_SOFTWARE_GL="$STEAM_FORCE_SOFTWARE_GL" \
    NOVA_TERMUX_X11_STEAM_CEF_ENV_SPLIT="$STEAM_CEF_ENV_SPLIT" \
    NOVA_TERMUX_X11_STEAM_RESTART_LIMIT="$STEAM_RESTART_LIMIT" \
    NOVA_TERMUX_X11_STEAM_AUDIO_BRIDGE="$AUDIO_BRIDGE" \
    NOVA_TERMUX_X11_STEAM_AUDIO_BRIDGE_PORT="$AUDIO_BRIDGE_PORT" \
    NOVA_X11_ALLOW_INPUT_EVENTS="$allow_input_events" \
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
