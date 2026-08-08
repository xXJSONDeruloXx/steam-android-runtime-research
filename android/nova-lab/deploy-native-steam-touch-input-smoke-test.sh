#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
PACKAGE=com.xjsonderulo.steamandroid.novalab
TOUCH_X=${NOVA_TOUCH_X:-1100}
TOUCH_Y=${NOVA_TOUCH_Y:-100}
WAIT_TIMEOUT=${NOVA_TOUCH_WAIT_TIMEOUT:-150}
SETTLE_DELAY=${NOVA_TOUCH_SETTLE_DELAY:-30}
AFTER_DELAY=${NOVA_TOUCH_AFTER_DELAY:-8}
REQUIRE_STEAM_SURFACE=${NOVA_TOUCH_REQUIRE_STEAM_SURFACE:-0}
HELPER="$BUILD_DIR/nova-libei-input-bridge"
RUN_LOG="$BUILD_DIR/native-steam-touch-input-smoke.log"
EIS_LOG="$BUILD_DIR/nova-eis-touch-input-bridge.log"
APP_LOG="$BUILD_DIR/nova-android-touch-input-logcat.txt"
APP_REPORT="$BUILD_DIR/nova-android-touch-bridge-report.txt"
BEFORE_SCREENSHOT="$BUILD_DIR/native-steam-touch-before.png"
AFTER_SCREENSHOT="$BUILD_DIR/native-steam-touch-after.png"
ROOT_REPORT="$BUILD_DIR/device-gamescope-headless-ahb-report.txt"

export INSTALL_HOLO_GAMESCOPE=${INSTALL_HOLO_GAMESCOPE:-0}
export NOVA_GAMESCOPE_INPUT_EMULATION=enabled
export NOVA_EIS_TOUCH_BRIDGE=1
export NOVA_EIS_TOUCH_HELPER="$HELPER"
export NOVA_EIS_TOUCH_APP_SOCKET="@/data/user/0/$PACKAGE/files/nova-touch.sock"
export NOVA_EIS_TOUCH_TIMEOUT=${NOVA_EIS_TOUCH_TIMEOUT:-60000}
export NOVA_ANDROID_TOUCH_BRIDGE=1
export NOVA_FULLSCREEN_PRESENTATION=1
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
rm -f "$RUN_LOG" "$EIS_LOG" "$APP_LOG" "$APP_REPORT" \
    "$BEFORE_SCREENSHOT" "$AFTER_SCREENSHOT"

if ! command -v ffmpeg >/dev/null 2>&1; then
    echo "missing required host tool: ffmpeg" >&2
    exit 1
fi

if [ ! -x "$HELPER" ]; then
    "$SCRIPT_DIR/build-libei-input-bridge.sh"
fi

steamui_html_lines=$(
    "$ADB" shell "su -c 'wc -l < $DEVICE_ROOT/opt/nova-steam/home/.local/share/Steam/logs/steamui_html.txt'" \
        2>/dev/null | tr -d '\r' | awk '{print $1}'
)
webhelper_js_lines=$(
    "$ADB" shell "su -c 'wc -l < $DEVICE_ROOT/opt/nova-steam/home/.local/share/Steam/logs/webhelper_js.txt'" \
        2>/dev/null | tr -d '\r' | awk '{print $1}'
)
steamui_html_lines=${steamui_html_lines:-0}
webhelper_js_lines=${webhelper_js_lines:-0}

set +e
"$SCRIPT_DIR/deploy-native-steam-smoke-test.sh" >"$RUN_LOG" 2>&1 &
run_pid=$!
set -e

cleanup() {
    if [ -n "${run_pid:-}" ] && kill -0 "$run_pid" 2>/dev/null; then
        kill "$run_pid" 2>/dev/null || true
    fi
}
trap cleanup EXIT

touch_ready=1
elapsed=0
while [ "$elapsed" -lt "$WAIT_TIMEOUT" ]; do
    "$ADB" shell run-as "$PACKAGE" cat files/android-touch-bridge-report.txt \
        >"$APP_REPORT" 2>/dev/null || true
    "$ADB" shell "su -c 'cat $DEVICE_ROOT/tmp/nova-eis-touch.log'" \
        >"$EIS_LOG" 2>/dev/null || true
    if rg -q -- 'android_touch_socket=connected' "$APP_REPORT" && \
        rg -q -- 'libei_touch_device_resumed=pass' "$EIS_LOG" && \
        "$ADB" shell "su -c 'ps -A -o ARGS | grep -q steamwebhelper && tail -n +$((steamui_html_lines + 1)) $DEVICE_ROOT/opt/nova-steam/home/.local/share/Steam/logs/steamui_html.txt | grep -q \"Started webhelper process\" && tail -n +$((webhelper_js_lines + 1)) $DEVICE_ROOT/opt/nova-steam/home/.local/share/Steam/logs/webhelper_js.txt | grep -q \"CWebSocketConnection (steamUI): connection ready\" && tail -n +$((webhelper_js_lines + 1)) $DEVICE_ROOT/opt/nova-steam/home/.local/share/Steam/logs/webhelper_js.txt | grep -q \"OOBE Store: keyboards\"'" \
        >/dev/null 2>&1; then
        touch_ready=0
        break
    fi
    if ! kill -0 "$run_pid" 2>/dev/null; then
        break
    fi
    sleep 1
    elapsed=$((elapsed + 1))
done

echo "steam_touch_ready=$([ "$touch_ready" -eq 0 ] && echo 1 || echo 0)"
if [ "$touch_ready" -ne 0 ]; then
    cat "$EIS_LOG" 2>/dev/null || true
    cat "$APP_REPORT" 2>/dev/null || true
    cat "$RUN_LOG" 2>/dev/null || true
    echo "native_steam_touch_input_smoke=fail reason=touch_or_steam_ready_timeout" >&2
    exit 1
fi

sleep "$SETTLE_DELAY"
"$ADB" exec-out screencap -p >"$BEFORE_SCREENSHOT"
echo "android_touch_tap=x:$TOUCH_X y:$TOUCH_Y"
"$ADB" shell input tap "$TOUCH_X" "$TOUCH_Y" >/dev/null
sleep "$AFTER_DELAY"
"$ADB" exec-out screencap -p >"$AFTER_SCREENSHOT"

set +e
wait "$run_pid"
run_status=$?
set -e
run_pid=

"$ADB" shell run-as "$PACKAGE" cat files/android-touch-bridge-report.txt \
    >"$APP_REPORT" 2>/dev/null || true
"$ADB" logcat -d -v threadtime NovaLab:I '*:S' >"$APP_LOG"
"$ADB" shell "su -c 'cat $DEVICE_ROOT/tmp/nova-eis-touch.log'" \
    >"$EIS_LOG" 2>/dev/null || true

cat "$EIS_LOG" 2>/dev/null || true
cat "$APP_REPORT" 2>/dev/null || true
cat "$RUN_LOG"

echo "touch_before_screenshot=$BEFORE_SCREENSHOT"
echo "touch_after_screenshot=$AFTER_SCREENSHOT"
echo "touch_before_sha256=$(sha256sum "$BEFORE_SCREENSHOT" | cut -c1-64)"
echo "touch_after_sha256=$(sha256sum "$AFTER_SCREENSHOT" | cut -c1-64)"
echo "touch_screen_changed=$(cmp -s "$BEFORE_SCREENSHOT" "$AFTER_SCREENSHOT" && echo fail || echo pass)"

touch_panel="$BEFORE_SCREENSHOT.steam-panel.png"
ffmpeg -y -hide_banner -loglevel error -i "$BEFORE_SCREENSHOT" \
    -vf "crop=250:600:1000:20" "$touch_panel" >/dev/null 2>&1
touch_panel_stats=$(ffmpeg -hide_banner -i "$touch_panel" \
    -vf "signalstats,metadata=print:file=-" -f null - 2>&1 | awk -F= '
        /lavfi.signalstats.YAVG=/{yavg=$2}
        /lavfi.signalstats.YMAX=/{ymax=$2}
        END {printf "%d %d", yavg, ymax}
    ')
read -r touch_panel_yavg touch_panel_ymax <<EOF
$touch_panel_stats
EOF
case "$touch_panel_yavg" in ''|*[!0-9]*) touch_panel_yavg=0 ;; esac
case "$touch_panel_ymax" in ''|*[!0-9]*) touch_panel_ymax=0 ;; esac
echo "touch_steam_panel_yavg=$touch_panel_yavg"
echo "touch_steam_panel_ymax=$touch_panel_ymax"
if [ "$touch_panel_ymax" -ge 220 ] && [ "$touch_panel_yavg" -ge 20 ]; then
    echo "touch_steam_surface=pass"
else
    echo "touch_steam_surface=fail" >&2
    if [ "$REQUIRE_STEAM_SURFACE" = "1" ]; then
        exit 1
    fi
fi

for marker in \
    'headless_gamescope_ahb=pass' \
    'native_steam_smoke=pass'; do
    if ! rg -q -- "$marker" "$RUN_LOG"; then
        echo "missing touch smoke marker: $marker" >&2
        exit 1
    fi
done
for marker in \
    'android_touch_socket=listening' \
    'android_touch_socket=connected' \
    'android_touch_forwarded=pass'; do
    if ! rg -q -- "$marker" "$APP_REPORT"; then
        echo "missing Android touch marker: $marker" >&2
        exit 1
    fi
done
for marker in \
    'libei_connect=pass' \
    'libei_touch_seat=pass' \
    'libei_touch_device=pass' \
    'libei_touch_device_resumed=pass' \
    'android_touch_socket_connected=pass' \
    'libei_touch_down_sent=pass' \
    'libei_touch_up_sent=pass' \
    'libei_touch_probe=pass'; do
    if ! rg -q -- "$marker" "$EIS_LOG"; then
        echo "missing EIS touch marker: $marker" >&2
        exit 1
    fi
done
if ! rg -q -- 'EIS touch event type=' "$ROOT_REPORT"; then
    echo "missing Gamescope touch receive marker" >&2
    exit 1
fi
if rg -q -- 'No touch support yet' "$ROOT_REPORT"; then
    echo "Gamescope still rejected touch events" >&2
    exit 1
fi
if [ "$run_status" -ne 0 ]; then
    echo "native_steam_touch_input_smoke=fail underlying_status=$run_status" >&2
    exit "$run_status"
fi

if [ "$REQUIRE_STEAM_SURFACE" = "1" ]; then
    echo "native_steam_touch_input_smoke=pass"
else
    echo "native_steam_touch_input_transport=pass"
fi
