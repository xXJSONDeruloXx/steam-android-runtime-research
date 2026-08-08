#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
PACKAGE=com.xjsonderulo.steamandroid.novalab
SOURCE_EVENT=${NOVA_STEAM_GAMEPAD_SOURCE:-/dev/input/event7}
EVENT_CODE=${NOVA_CONTROLLER_UI_EVENT_CODE:-304}
EVENT_NAME=${NOVA_CONTROLLER_UI_EVENT_NAME:-BTN_SOUTH}
WAIT_TIMEOUT=${NOVA_CONTROLLER_UI_WAIT_TIMEOUT:-140}
SETTLE_DELAY=${NOVA_CONTROLLER_UI_SETTLE_DELAY:-30}
STABLE_ATTEMPTS=${NOVA_CONTROLLER_UI_STABLE_ATTEMPTS:-20}
RELAY_TIMEOUT=${NOVA_CONTROLLER_UI_RELAY_TIMEOUT:-180000}
EXPECT_NAVIGATION=${NOVA_CONTROLLER_UI_EXPECT_NAVIGATION:-0}
AFTER_DELAY=${NOVA_CONTROLLER_UI_AFTER_DELAY:-20}
HELPER="$BUILD_DIR/nova-uinput-gamepad-relay"
DEVICE_HELPER="$DEVICE_ROOT/opt/nova-kgsl-driver/nova-uinput-gamepad-relay"
CHROOT_HELPER=/opt/nova-kgsl-driver/nova-uinput-gamepad-relay
DEVICE_STAGE=/data/local/tmp/nova-libei-stage
DEVICE_FD_SCRIPT=/data/local/tmp/nova-steam-input-fd-probe.sh
DEVICE_FD_REPORT=/data/local/tmp/nova-controller-ui-steam-input-fd.txt
STEAM_LOGS_DIR="$DEVICE_ROOT/opt/nova-steam/home/.local/share/Steam/logs"
RUN_LOG="$BUILD_DIR/native-steam-controller-ui-input-smoke.log"
HELPER_LOG="$BUILD_DIR/nova-controller-ui-uinput-relay.log"
FD_LOG="$BUILD_DIR/nova-controller-ui-steam-input-fd.log"
BEFORE_SCREENSHOT="$BUILD_DIR/native-steam-controller-ui-before.png"
AFTER_SCREENSHOT="$BUILD_DIR/native-steam-controller-ui-after.png"

export INSTALL_HOLO_GAMESCOPE=${INSTALL_HOLO_GAMESCOPE:-0}
export NOVA_AHB_FRAME_COUNT=${NOVA_AHB_FRAME_COUNT:-120}
export NOVA_AHB_WIDTH=${NOVA_AHB_WIDTH:-960}
export NOVA_AHB_HEIGHT=${NOVA_AHB_HEIGHT:-540}
export NOVA_STEAM_BOOTSTRAP_MODE=${NOVA_STEAM_BOOTSTRAP_MODE:-skip}
export NOVA_STEAM_PRELOAD_PROFILE=${NOVA_STEAM_PRELOAD_PROFILE:-sysv}
export NOVA_STEAM_MESA_DRIVER=${NOVA_STEAM_MESA_DRIVER:-swrast}
export NOVA_STEAM_GALLIUM_DRIVER=${NOVA_STEAM_GALLIUM_DRIVER:-softpipe}
export NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE=${NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE:-1}
export NOVA_STEAM_NO_CEF_SANDBOX=${NOVA_STEAM_NO_CEF_SANDBOX:-1}
export NOVA_STEAM_CLIENT_TIMEOUT=${NOVA_STEAM_CLIENT_TIMEOUT:-180}
export NOVA_STEAM_GAMESCOPE_TIMEOUT=${NOVA_STEAM_GAMESCOPE_TIMEOUT:-220}

mkdir -p "$BUILD_DIR"
rm -f "$RUN_LOG" "$HELPER_LOG" "$FD_LOG" \
    "$BEFORE_SCREENSHOT" "$AFTER_SCREENSHOT"

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "missing required host tool: ffmpeg" >&2
    exit 1
fi

if [ ! -x "$HELPER" ]; then
    "$SCRIPT_DIR/build-uinput-gamepad-relay.sh"
fi

"$ADB" shell "mkdir -p $DEVICE_STAGE"
"$ADB" push "$HELPER" "$DEVICE_STAGE/nova-uinput-gamepad-relay" >/dev/null
"$ADB" shell su -c "mkdir -p $DEVICE_ROOT/opt/nova-kgsl-driver"
"$ADB" shell su -c "cp $DEVICE_STAGE/nova-uinput-gamepad-relay $DEVICE_HELPER"
"$ADB" shell su -c "chmod 755 $DEVICE_HELPER"
"$ADB" push "$SCRIPT_DIR/device/nova-steam-input-fd-probe.sh" \
    "$DEVICE_FD_SCRIPT" >/dev/null
"$ADB" shell su -c "chmod 755 $DEVICE_FD_SCRIPT"

previous_app_pid=$("$ADB" shell pidof "$PACKAGE" 2>/dev/null || true)
previous_app_pid=$(printf '%s\n' "$previous_app_pid" | tr -d '\r' | awk '{print $1}')

device_line_count() {
    local remote_path=$1
    local count
    count=$("$ADB" shell "su -c 'wc -l < $remote_path'" 2>/dev/null || true)
    count=$(printf '%s\n' "$count" | tr -d '\r' | awk '{print $1}')
    case "$count" in
        ''|*[!0-9]*) echo 0 ;;
        *) echo "$count" ;;
    esac
}

capture_ready_screenshot() {
    local target=$1
    local sample="$target.sample"
    local surface_sample="$target.surface.png"
    local attempt
    local surface_hash
    local surface_yhigh

    for attempt in $(seq 1 "$STABLE_ATTEMPTS"); do
        "$ADB" exec-out screencap -p >"$sample"
        ffmpeg -y -hide_banner -loglevel error -i "$sample" \
            -vf "crop=1232:312:24:170" "$surface_sample" >/dev/null 2>&1
        surface_hash=$(sha256sum "$surface_sample" | cut -c1-64)
        surface_yhigh=$(ffmpeg -hide_banner -i "$sample" \
            -vf "crop=1232:312:24:170,signalstats,metadata=print:file=-" \
            -f null - 2>&1 | grep "lavfi.signalstats.YHIGH=" | head -1 | cut -d= -f2)
        case "$surface_yhigh" in
            ""|*[!0-9]*) surface_yhigh=0 ;;
        esac
        if [ "$surface_yhigh" -ge 40 ]; then
            cp "$sample" "$target"
            stable_surface_hash=$surface_hash
            echo "controller_ui_surface=pass"
            echo "controller_ui_screenshot=$(basename "$target")"
            echo "controller_ui_screenshot_sha256=$(sha256sum "$target" | cut -c1-64)"
            echo "controller_ui_surface_sha256=$surface_hash"
            echo "controller_ui_surface_yhigh=$surface_yhigh"
            return 0
        fi
        sleep 1
    done

    echo "controller_ui_surface=missing" >&2
    return 1
}

helper_pid=
fd_pid=
run_pid=
cleanup_remote_helper() {
    if [ -n "${helper_pid:-}" ]; then
        "$ADB" shell su -c \
            "for remote_pid in \$(pidof nova-uinput-gamepad-relay 2>/dev/null); do kill \$remote_pid; done" \
            >/dev/null 2>&1 || true
    fi
}
trap cleanup_remote_helper EXIT

steamui_html_lines=$(device_line_count "$STEAM_LOGS_DIR/steamui_html.txt")
webhelper_js_lines=$(device_line_count "$STEAM_LOGS_DIR/webhelper_js.txt")

set +e
"$SCRIPT_DIR/deploy-native-steam-smoke-test.sh" >"$RUN_LOG" 2>&1 &
run_pid=$!
set -e

source_ready=1
elapsed=0
while [ "$elapsed" -lt "$WAIT_TIMEOUT" ]; do
    if "$ADB" shell su -c "test -e $DEVICE_ROOT$SOURCE_EVENT" \
        >/dev/null 2>&1; then
        set +e
        "$ADB" shell su -c \
            "/system/bin/chroot $DEVICE_ROOT /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp XDG_RUNTIME_DIR=/tmp $CHROOT_HELPER $SOURCE_EVENT $RELAY_TIMEOUT relay-once-code $EVENT_CODE" \
            >"$HELPER_LOG" 2>&1 &
        helper_pid=$!
        set -e
        source_ready=0
        break
    fi
    if ! kill -0 "$run_pid" 2>/dev/null; then
        break
    fi
    sleep 1
    elapsed=$((elapsed + 1))
done

if [ "$source_ready" -eq 0 ]; then
    set +e
    "$ADB" shell su -c \
        "/system/bin/sh $DEVICE_FD_SCRIPT $DEVICE_ROOT $DEVICE_FD_REPORT $WAIT_TIMEOUT" \
        >"$FD_LOG" 2>&1 &
    fd_pid=$!
    set -e
fi

helper_ready=1
elapsed=0
while [ "$elapsed" -lt 30 ]; do
    if [ -s "$HELPER_LOG" ] && rg -q 'uinput_device_ready=pass' "$HELPER_LOG"; then
        helper_ready=0
        break
    fi
    if [ -n "$helper_pid" ] && ! kill -0 "$helper_pid" 2>/dev/null; then
        break
    fi
    sleep 1
    elapsed=$((elapsed + 1))
done

app_pid=
ui_ready=1
elapsed=0
while [ "$elapsed" -lt "$WAIT_TIMEOUT" ]; do
    app_pid=$("$ADB" shell pidof "$PACKAGE" 2>/dev/null || true)
    app_pid=$(printf '%s\n' "$app_pid" | tr -d '\r' | awk '{print $1}')
    if [ -n "$app_pid" ] && [ "$app_pid" != "$previous_app_pid" ] && \
        "$ADB" shell "su -c 'ps -A -o ARGS | grep -q steamwebhelper && tail -n +$((steamui_html_lines + 1)) $STEAM_LOGS_DIR/steamui_html.txt | grep -q \"Started webhelper process\" && tail -n +$((webhelper_js_lines + 1)) $STEAM_LOGS_DIR/webhelper_js.txt | grep -q \"CWebSocketConnection (steamUI): connection ready\" && tail -n +$((webhelper_js_lines + 1)) $STEAM_LOGS_DIR/webhelper_js.txt | grep -q \"OOBE Store: keyboards\"'" \
        >/dev/null 2>&1 && \
        "$ADB" shell logcat -d -s NovaLab:I '*:S' 2>/dev/null | \
        grep -q " $app_pid .*ahb_double_buffer_frame_in_flight=0"; then
        ui_ready=0
        break
    fi
    if ! kill -0 "$run_pid" 2>/dev/null; then
        break
    fi
    sleep 1
    elapsed=$((elapsed + 1))
done

echo "controller_ui_source_ready=$([ "$source_ready" -eq 0 ] && echo 1 || echo 0)"
echo "controller_ui_relay_ready=$([ "$helper_ready" -eq 0 ] && echo 1 || echo 0)"
if [ -n "$app_pid" ]; then
    echo "controller_ui_ready=$([ "$ui_ready" -eq 0 ] && echo 1 || echo 0) app_pid=$app_pid"
else
    echo "controller_ui_ready=0 app_pid=missing"
fi

event_sent=1
stable_surface_hash=
navigation_result=unknown
if [ "$ui_ready" -eq 0 ]; then
    sleep "$SETTLE_DELAY"
    if capture_ready_screenshot "$BEFORE_SCREENSHOT"; then
        "$ADB" shell su -c \
            "sendevent $SOURCE_EVENT 1 $EVENT_CODE 1; sendevent $SOURCE_EVENT 0 0 0; sendevent $SOURCE_EVENT 1 $EVENT_CODE 0; sendevent $SOURCE_EVENT 0 0 0" \
            >/dev/null
        event_sent=0
        echo "controller_ui_event=$EVENT_NAME code=$EVENT_CODE"
        sleep "$AFTER_DELAY"
        echo "controller_ui_after_delay=$AFTER_DELAY"
        "$ADB" exec-out screencap -p >"$AFTER_SCREENSHOT"
        after_surface="$AFTER_SCREENSHOT.surface.png"
        ffmpeg -y -hide_banner -loglevel error -i "$AFTER_SCREENSHOT" \
            -vf "crop=1232:312:24:170" "$after_surface" >/dev/null 2>&1
        after_surface_hash=$(sha256sum "$after_surface" | cut -c1-64)
        echo "controller_ui_after_screenshot=$(basename "$AFTER_SCREENSHOT")"
        echo "controller_ui_after_surface_sha256=$after_surface_hash"
        before_panel="$BEFORE_SCREENSHOT.navigation-panel.png"
        after_panel="$AFTER_SCREENSHOT.navigation-panel.png"
        ffmpeg -y -hide_banner -loglevel error -i "$BEFORE_SCREENSHOT" \
            -vf "crop=255:280:970:185" "$before_panel" >/dev/null 2>&1
        ffmpeg -y -hide_banner -loglevel error -i "$AFTER_SCREENSHOT" \
            -vf "crop=255:280:970:185" "$after_panel" >/dev/null 2>&1
        before_panel_hash=$(sha256sum "$before_panel" | cut -c1-64)
        after_panel_hash=$(sha256sum "$after_panel" | cut -c1-64)
        echo "controller_ui_navigation_panel_before_sha256=$before_panel_hash"
        echo "controller_ui_navigation_panel_after_sha256=$after_panel_hash"
        echo "controller_ui_after_screenshot_sha256=$(sha256sum "$AFTER_SCREENSHOT" | awk '{print $1}')"
        if [ "$stable_surface_hash" = "$after_surface_hash" ]; then
            echo "controller_ui_screen_changed=none"
        else
            echo "controller_ui_screen_changed=pass"
        fi
        if [ "$before_panel_hash" = "$after_panel_hash" ]; then
            navigation_result=none
        else
            navigation_result=pass
        fi
        echo "controller_ui_navigation=$navigation_result"
    fi
else
    echo "controller_ui_surface=not_run"
fi

set +e
wait "$run_pid"
run_status=$?
if [ -n "$helper_pid" ]; then
    if [ "$event_sent" -ne 0 ]; then
        cleanup_remote_helper
    fi
    wait "$helper_pid"
    helper_status=$?
else
    helper_status=1
fi
if [ -n "$fd_pid" ]; then
    wait "$fd_pid"
    fd_status=$?
else
    fd_status=1
fi
set -e

cat "$HELPER_LOG" 2>/dev/null || true
cat "$FD_LOG" 2>/dev/null || true
cat "$RUN_LOG"
echo "controller_ui_run_status=$run_status"
echo "controller_ui_helper_status=$helper_status"
echo "controller_ui_fd_status=$fd_status"

if [ "$run_status" -ne 0 ]; then
    echo "native_steam_controller_ui_input_smoke=fail underlying_status=$run_status" >&2
    exit "$run_status"
fi
for marker in \
    'uinput_device_ready=pass' \
    'uinput_event_forwarded=pass'; do
    if ! rg -q -- "$marker" "$HELPER_LOG"; then
        echo "missing controller relay marker: $marker" >&2
        exit 1
    fi
done
control_marker="uinput_control_event=$EVENT_NAME"
if ! rg -q -- "$control_marker" "$HELPER_LOG"; then
    echo "missing controller relay marker: $control_marker" >&2
    exit 1
fi
if [ "$fd_status" -ne 0 ] || ! rg -q -- 'steam_input_fd_probe=pass' "$FD_LOG"; then
    echo "missing Steam process FD marker" >&2
    exit 1
fi
if [ "$EXPECT_NAVIGATION" = "1" ] && [ "$navigation_result" != "pass" ]; then
    echo "expected controller UI navigation was not observed" >&2
    exit 1
fi
echo "native_steam_controller_ui_input_smoke=pass"
