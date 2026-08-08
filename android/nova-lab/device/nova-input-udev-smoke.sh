#!/system/bin/sh

set -u

ROOT="${1:-/data/local/tmp/nova-holo-rootfs}"
HELPER="${2:-/opt/nova-kgsl-driver/nova-uinput-gamepad-relay}"
PROBE="${3:-/opt/nova-kgsl-driver/nova-input-udev-probe}"
SOURCE="${4:-/dev/input/event7}"
RELAY_TIMEOUT="${5:-10000}"
OUT="${6:-/data/local/tmp/nova-input-udev-report.txt}"
WORK="${7:-/data/local/tmp/nova-input-udev-work}"
UDEVD_MODE="${8:-disabled}"
SDL_PROBE="${9:-}"
SDL_LIBRARY="${10:-/opt/nova-steam/home/.local/share/Steam/steamrtarm64/libSDL3.so.0}"
SDL_EVENT_MODE="${11:-0}"
SDL_EVENT_CODE="${12:-545}"
SDL_EVENT_TIMEOUT="${13:-10000}"
SDL_GAMEPAD_PROBE="${14:-}"
SDL_GAMEPAD_EVENT_MODE="${15:-0}"
if [ "$SDL_PROBE" = "none" ]; then
    SDL_PROBE=
fi
if [ "$SDL_GAMEPAD_PROBE" = "none" ]; then
    SDL_GAMEPAD_PROBE=
fi
helper_pid=
sdl_pid=
gamepad_pid=
udevd_pid=
udevd_started=0
status=0

mkdir -p "${OUT%/*}" "$WORK" "$ROOT/tmp"

cleanup() {
    if [ -n "$helper_pid" ]; then
        /system/bin/kill "$helper_pid" >/dev/null 2>&1 || true
        wait "$helper_pid" >/dev/null 2>&1 || true
    fi
    if [ -n "$sdl_pid" ]; then
        /system/bin/kill "$sdl_pid" >/dev/null 2>&1 || true
        wait "$sdl_pid" >/dev/null 2>&1 || true
    fi
    if [ -n "$gamepad_pid" ]; then
        /system/bin/kill "$gamepad_pid" >/dev/null 2>&1 || true
        wait "$gamepad_pid" >/dev/null 2>&1 || true
    fi
    if [ "$udevd_started" -eq 1 ]; then
        /system/bin/chroot "$ROOT" /usr/bin/udevadm control --exit >/dev/null 2>&1 || true
    fi
    if [ -n "$udevd_pid" ]; then
        /system/bin/kill "$udevd_pid" >/dev/null 2>&1 || true
        wait "$udevd_pid" >/dev/null 2>&1 || true
    fi
    unmount_target "$ROOT/dev/shm"
    unmount_target "$ROOT/proc"
    unmount_target "$ROOT/sys"
    unmount_target "$ROOT/dev"
}

unmount_target() {
    unmount_path="$1"
    unmount_attempt=0
    while [ "$unmount_attempt" -lt 16 ]; do
        /system/bin/umount -l "$unmount_path" >/dev/null 2>&1 || break
        unmount_attempt=$((unmount_attempt + 1))
    done
}

mount_one() {
    mount_source="$1"
    mount_target="$2"
    if [ "$mount_target" = "$ROOT/dev" ]; then
        unmount_target "$ROOT/dev/shm"
    fi
    unmount_target "$mount_target"
    mkdir -p "$mount_target"
    /system/bin/mount -o bind "$mount_source" "$mount_target" >/dev/null 2>&1 || true
}

trap cleanup EXIT
mount_one /dev "$ROOT/dev"
mount_one /sys "$ROOT/sys"
mount_one /proc "$ROOT/proc"

UDEVD_LOG="$WORK/udevd.log"
if [ "$UDEVD_MODE" = "enabled" ]; then
    mkdir -p "$ROOT/run/udev"
    /system/bin/chroot "$ROOT" /usr/lib/systemd/systemd-udevd \
        --resolve-names=never >"$UDEVD_LOG" 2>&1 &
    udevd_pid=$!
    /system/bin/sleep 0.5
    if /system/bin/kill -0 "$udevd_pid" >/dev/null 2>&1; then
        udevd_started=1
        udevd_status=pass
    else
        udevd_status=fail
        status=1
    fi
else
    udevd_status=disabled
fi

HELPER_LOG="$WORK/helper.log"
PROBE_LOG="$WORK/probe.log"
if [ "$SDL_EVENT_MODE" = "1" ] || [ "$SDL_GAMEPAD_EVENT_MODE" = "1" ]; then
    /system/bin/chroot "$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp \
        "$HELPER" "$SOURCE" "$RELAY_TIMEOUT" relay \
        >"$HELPER_LOG" 2>&1 &
else
    /system/bin/chroot "$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp \
        "$HELPER" "$SOURCE" "$RELAY_TIMEOUT" none >"$HELPER_LOG" 2>&1 &
fi
helper_pid=$!

virtual_path=
attempt=0
while [ "$attempt" -lt 50 ]; do
    virtual_path=$(sed -n 's/^uinput_device=//p' "$HELPER_LOG")
    if [ -n "$virtual_path" ] && [ -e "$ROOT$virtual_path" ]; then
        break
    fi
    /system/bin/sleep 0.1
    attempt=$((attempt + 1))
done

if [ -z "$virtual_path" ] || [ ! -e "$ROOT$virtual_path" ]; then
    echo "udev_smoke_error=virtual_device_timeout" >"$OUT"
    status=1
else
    virtual_event_index=${virtual_path##*event}
    case "$virtual_event_index" in
        ''|*[!0-9]*) ;;
        *)
            if [ ! -e "$ROOT$virtual_path" ]; then
                /system/bin/mknod "$ROOT$virtual_path" c 13 $((64 + virtual_event_index)) \
                    >/dev/null 2>&1 || true
                /system/bin/chmod 0666 "$ROOT$virtual_path" >/dev/null 2>&1 || true
            fi
            ;;
    esac
    if [ "$UDEVD_MODE" = "enabled" ]; then
        /system/bin/chroot "$ROOT" /usr/bin/udevadm settle --timeout=5 \
            >/dev/null 2>&1 || true
    fi
    /system/bin/sleep 0.5
    case "$virtual_event_index" in
        ''|*[!0-9]*) ;;
        *)
            if [ ! -e "$ROOT$virtual_path" ]; then
                /system/bin/mknod "$ROOT$virtual_path" c 13 $((64 + virtual_event_index)) \
                    >/dev/null 2>&1 || true
                /system/bin/chmod 0666 "$ROOT$virtual_path" >/dev/null 2>&1 || true
            fi
            ;;
    esac
    sdl_status=0
    gamepad_status=0
    gamepad_event_sent=disabled
    GAMEPAD_LOG="$WORK/sdl3-gamepad.log"
    if [ "$SDL_EVENT_MODE" = "1" ] || [ "$SDL_GAMEPAD_EVENT_MODE" = "1" ]; then
        /system/bin/chroot "$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp \
            "$PROBE" "Nova Virtual Xbox Controller" "$virtual_path" >"$PROBE_LOG" 2>&1
        probe_status=$?
    fi
    if [ -n "$SDL_GAMEPAD_PROBE" ]; then
        if [ "$SDL_GAMEPAD_EVENT_MODE" = "1" ]; then
            /system/bin/chroot "$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp \
                LD_LIBRARY_PATH="${SDL_LIBRARY%/*}:/usr/lib" "$SDL_GAMEPAD_PROBE" \
                "$SDL_LIBRARY" "Nova Virtual Xbox Controller" gamepad-event "$SDL_EVENT_TIMEOUT" \
                "$virtual_path" \
                >"$GAMEPAD_LOG" 2>&1 &
            gamepad_pid=$!
            gamepad_ready=0
            attempt=0
            while [ "$attempt" -lt 100 ]; do
                if grep -q '^sdl3_gamepad_event_ready=pass$' "$GAMEPAD_LOG" 2>/dev/null; then
                    gamepad_ready=1
                    break
                fi
                if ! /system/bin/kill -0 "$gamepad_pid" >/dev/null 2>&1; then
                    break
                fi
                /system/bin/sleep 0.1
                attempt=$((attempt + 1))
            done
            if [ "$gamepad_ready" -eq 1 ]; then
                /system/bin/sendevent "$SOURCE" 1 "$SDL_EVENT_CODE" 1
                /system/bin/sendevent "$SOURCE" 0 0 0
                /system/bin/sendevent "$SOURCE" 1 "$SDL_EVENT_CODE" 0
                /system/bin/sendevent "$SOURCE" 0 0 0
                gamepad_event_sent=pass
            else
                gamepad_event_sent=fail
            fi
            wait "$gamepad_pid"
            gamepad_status=$?
            gamepad_pid=
        else
            /system/bin/chroot "$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp \
                LD_LIBRARY_PATH="${SDL_LIBRARY%/*}:/usr/lib" "$SDL_GAMEPAD_PROBE" \
                "$SDL_LIBRARY" "Nova Virtual Xbox Controller" gamepad "$virtual_path" \
                >"$GAMEPAD_LOG" 2>&1
            gamepad_status=$?
        fi
    fi
    SDL_LOG="$WORK/sdl3.log"
    if [ -n "$SDL_PROBE" ]; then
        SDL_LIBRARY_DIR=${SDL_LIBRARY%/*}
        LD_LIBRARY_PATH="$SDL_LIBRARY_DIR:/usr/lib"
        if [ "$SDL_EVENT_MODE" = "1" ]; then
            /system/bin/chroot "$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp \
                LD_LIBRARY_PATH="$LD_LIBRARY_PATH" "$SDL_PROBE" "$SDL_LIBRARY" \
                "Nova Virtual Xbox Controller" event "$SDL_EVENT_TIMEOUT" "$virtual_path" \
                >"$SDL_LOG" 2>&1 &
            sdl_pid=$!
            sdl_ready=0
            attempt=0
            while [ "$attempt" -lt 100 ]; do
                if grep -q '^sdl3_event_ready=pass$' "$SDL_LOG" 2>/dev/null; then
                    sdl_ready=1
                    break
                fi
                if ! /system/bin/kill -0 "$sdl_pid" >/dev/null 2>&1; then
                    break
                fi
                /system/bin/sleep 0.1
                attempt=$((attempt + 1))
            done
            if [ "$sdl_ready" -eq 1 ]; then
                /system/bin/sendevent "$SOURCE" 1 "$SDL_EVENT_CODE" 1
                /system/bin/sendevent "$SOURCE" 0 0 0
                /system/bin/sendevent "$SOURCE" 1 "$SDL_EVENT_CODE" 0
                /system/bin/sendevent "$SOURCE" 0 0 0
                sdl_event_sent=pass
            else
                sdl_event_sent=fail
            fi
            wait "$sdl_pid"
            sdl_status=$?
            sdl_pid=
        else
            /system/bin/chroot "$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp \
                LD_LIBRARY_PATH="$LD_LIBRARY_PATH" "$SDL_PROBE" "$SDL_LIBRARY" \
                "Nova Virtual Xbox Controller" "$virtual_path" >"$SDL_LOG" 2>&1
            sdl_status=$?
            sdl_event_sent=disabled
        fi
    fi
    if [ "$SDL_EVENT_MODE" != "1" ]; then
        /system/bin/chroot "$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp \
            "$PROBE" "Nova Virtual Xbox Controller" "$virtual_path" >"$PROBE_LOG" 2>&1
        probe_status=$?
    fi
    if [ "$SDL_EVENT_MODE" = "1" ] || [ "$SDL_GAMEPAD_EVENT_MODE" = "1" ]; then
        wait "$helper_pid" >/dev/null 2>&1 || true
        helper_pid=
    fi
    {
        echo "udev_smoke_source=$SOURCE"
        echo "udev_smoke_virtual_device=$virtual_path"
        echo "udev_smoke_udevd=$udevd_status"
        if [ "$udevd_status" != "disabled" ]; then
            echo "udev_smoke_udevd_log_begin"
            cat "$UDEVD_LOG" 2>/dev/null || true
            echo "udev_smoke_udevd_log_end"
        fi
        if [ -n "$SDL_PROBE" ]; then
            echo "udev_smoke_sdl3_probe=$sdl_status"
            echo "udev_smoke_sdl3_event_mode=$SDL_EVENT_MODE"
            echo "udev_smoke_sdl3_event_code=$SDL_EVENT_CODE"
            echo "udev_smoke_sdl3_event_sent=${sdl_event_sent:-disabled}"
            echo "udev_smoke_sdl3_log_begin"
            cat "$SDL_LOG" 2>/dev/null || true
            echo "udev_smoke_sdl3_log_end"
        fi
        if [ -n "$SDL_GAMEPAD_PROBE" ]; then
            echo "udev_smoke_sdl3_gamepad_probe=$gamepad_status"
            echo "udev_smoke_sdl3_gamepad_event_mode=$SDL_GAMEPAD_EVENT_MODE"
            echo "udev_smoke_sdl3_gamepad_event_code=$SDL_EVENT_CODE"
            echo "udev_smoke_sdl3_gamepad_event_sent=$gamepad_event_sent"
            echo "udev_smoke_sdl3_gamepad_log_begin"
            cat "$GAMEPAD_LOG" 2>/dev/null || true
            echo "udev_smoke_sdl3_gamepad_log_end"
        fi
        echo "udev_smoke_helper_begin"
        cat "$HELPER_LOG"
        echo "udev_smoke_helper_end"
        echo "udev_smoke_probe_begin"
        cat "$PROBE_LOG"
        echo "udev_smoke_probe_end"
        echo "udev_smoke_probe_status=$probe_status"
    } >"$OUT"
    if [ "$probe_status" -ne 0 ] || [ "$udevd_status" = "fail" ] || \
        [ "$sdl_status" -ne 0 ] || [ "$gamepad_status" -ne 0 ]; then
        status=1
    else
        status=0
    fi
fi

exit "$status"
