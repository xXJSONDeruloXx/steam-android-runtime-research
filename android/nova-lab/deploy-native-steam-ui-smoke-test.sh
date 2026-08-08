#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
PACKAGE=com.xjsonderulo.steamandroid.novalab
SCREENSHOT="$BUILD_DIR/native-steam-live-screenshot.png"
RUN_LOG="$BUILD_DIR/native-steam-ui-smoke.log"
WAIT_TIMEOUT=${NOVA_STEAM_UI_WAIT_TIMEOUT:-90}
CAPTURE_DELAY=${NOVA_STEAM_UI_CAPTURE_DELAY:-20}
STEAM_LOGS_DIR="$DEVICE_ROOT/opt/nova-steam/home/.local/share/Steam/logs"

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
rm -f "$SCREENSHOT"
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

steamui_html_lines=$(device_line_count "$STEAM_LOGS_DIR/steamui_html.txt")
webhelper_js_lines=$(device_line_count "$STEAM_LOGS_DIR/webhelper_js.txt")

set +e
"$SCRIPT_DIR/deploy-native-steam-smoke-test.sh" >"$RUN_LOG" 2>&1 &
run_pid=$!
set -e

capture_status=1
elapsed=0
while [ "$elapsed" -lt "$WAIT_TIMEOUT" ]; do
    app_pid=$("$ADB" shell pidof "$PACKAGE" 2>/dev/null || true)
    app_pid=$(printf '%s\n' "$app_pid" | tr -d '\r' | awk '{print $1}')
    if [ -n "$app_pid" ] && [ "$app_pid" != "$previous_app_pid" ] && \
        "$ADB" shell "su -c 'ps -A -o ARGS | grep -q steamwebhelper && tail -n +$((steamui_html_lines + 1)) $STEAM_LOGS_DIR/steamui_html.txt | grep -q \"Started webhelper process\" && tail -n +$((webhelper_js_lines + 1)) $STEAM_LOGS_DIR/webhelper_js.txt | grep -q \"CWebSocketConnection (steamUI): connection ready\" && tail -n +$((webhelper_js_lines + 1)) $STEAM_LOGS_DIR/webhelper_js.txt | grep -q \"OOBE Store: keyboards\"'" \
        >/dev/null 2>&1 && \
        "$ADB" shell logcat -d -s NovaLab:I '*:S' 2>/dev/null | \
        grep -q " $app_pid .*ahb_double_buffer_frame_in_flight=0"; then
        sleep "$CAPTURE_DELAY"
        if "$ADB" exec-out screencap -p >"$SCREENSHOT"; then
            capture_status=0
            break
        fi
    fi
    if ! kill -0 "$run_pid" 2>/dev/null; then
        break
    fi
    sleep 1
    elapsed=$((elapsed + 1))
done

set +e
wait "$run_pid"
run_status=$?
set -e
cat "$RUN_LOG"

steam_logs_dir="$DEVICE_ROOT/opt/nova-steam/home/.local/share/Steam/logs"
for log_name in console_log steamui_html webhelper webhelper_js webhelper_gpu connection_log cef_log; do
    "$ADB" shell "su -c 'cat $steam_logs_dir/$log_name.txt'" \
        >"$BUILD_DIR/nova-$log_name-latest.txt" 2>/dev/null || true
done

if [ "$run_status" -ne 0 ]; then
    echo "native_steam_ui_smoke=fail underlying_status=$run_status" >&2
    exit "$run_status"
fi
if [ "$capture_status" -ne 0 ]; then
    echo "native_steam_ui_smoke=fail reason=webui_ready_screenshot_timeout" >&2
    exit 1
fi

echo "live_screenshot=$SCREENSHOT"
echo "native_steam_ui_smoke=pass"
