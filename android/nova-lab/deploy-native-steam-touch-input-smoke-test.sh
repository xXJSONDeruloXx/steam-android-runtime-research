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
SURFACE_WAIT_TIMEOUT=${NOVA_TOUCH_SURFACE_WAIT_TIMEOUT:-90}
REQUIRE_STEAM_SURFACE=${NOVA_TOUCH_REQUIRE_STEAM_SURFACE:-0}
REQUIRE_VISUAL_CHANGE=${NOVA_TOUCH_REQUIRE_VISUAL_CHANGE:-0}
HELPER="$BUILD_DIR/nova-libei-input-bridge"
RUN_LOG="$BUILD_DIR/native-steam-touch-input-smoke.log"
EIS_LOG="$BUILD_DIR/nova-eis-touch-input-bridge.log"
APP_LOG="$BUILD_DIR/nova-android-touch-input-logcat.txt"
APP_REPORT="$BUILD_DIR/nova-android-touch-bridge-report.txt"
BEFORE_SCREENSHOT="$BUILD_DIR/native-steam-touch-before.png"
AFTER_SCREENSHOT="$BUILD_DIR/native-steam-touch-after.png"
ROOT_REPORT="$BUILD_DIR/device-gamescope-headless-ahb-report.txt"
RUN_DIR=${NOVA_RUN_DIR:-}
if [ -n "$RUN_DIR" ]; then
    ROOT_REPORT="$RUN_DIR/device-gamescope-headless-ahb-report.txt"
fi

export INSTALL_HOLO_GAMESCOPE=${INSTALL_HOLO_GAMESCOPE:-0}
export NOVA_GAMESCOPE_INPUT_EMULATION=enabled
export NOVA_EIS_TOUCH_BRIDGE=1
export NOVA_EIS_TOUCH_HELPER="$HELPER"
export NOVA_EIS_TOUCH_APP_SOCKET="@/data/user/0/$PACKAGE/files/nova-touch.sock"
export NOVA_EIS_TOUCH_TIMEOUT=${NOVA_EIS_TOUCH_TIMEOUT:-60000}
export NOVA_ANDROID_TOUCH_BRIDGE=1
export NOVA_FULLSCREEN_PRESENTATION=${NOVA_FULLSCREEN_PRESENTATION:-1}
export NOVA_GAMESCOPE_AHB_REQUIRE_TARGET=${NOVA_GAMESCOPE_AHB_REQUIRE_TARGET:-0}
export NOVA_AHB_FRAME_COUNT=${NOVA_AHB_FRAME_COUNT:-120}
if [ "$NOVA_FULLSCREEN_PRESENTATION" = "1" ]; then
    export NOVA_FULLSCREEN_WIDTH=${NOVA_FULLSCREEN_WIDTH:-1280}
    export NOVA_FULLSCREEN_HEIGHT=${NOVA_FULLSCREEN_HEIGHT:-960}
    export NOVA_AHB_WIDTH=${NOVA_AHB_WIDTH:-$NOVA_FULLSCREEN_WIDTH}
    export NOVA_AHB_HEIGHT=${NOVA_AHB_HEIGHT:-$NOVA_FULLSCREEN_HEIGHT}
else
    export NOVA_AHB_WIDTH=${NOVA_AHB_WIDTH:-960}
    export NOVA_AHB_HEIGHT=${NOVA_AHB_HEIGHT:-540}
fi
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

cleanup_remote_runtime() {
    local cleanup_output
    "$ADB" push "$SCRIPT_DIR/device/nova-runtime-cleanup.sh" \
        /data/local/tmp/nova-runtime-cleanup.sh >/dev/null 2>&1 || true
    cleanup_output=$(
        "$ADB" shell su -c \
            "/system/bin/sh /data/local/tmp/nova-runtime-cleanup.sh $DEVICE_ROOT" \
            2>&1 || true
    )
    printf '%s\n' "$cleanup_output"
}

clear_app_runtime_files() {
    "$ADB" shell "run-as $PACKAGE sh -c 'rm -f files/nova-input.sock files/nova-touch.sock files/nova-lab-ahb-double-buffer.sock.* files/dmabuf-double-buffer-report.txt files/android-input-bridge-report.txt files/android-touch-bridge-report.txt'" \
        >/dev/null 2>&1 || true
}

focused_window() {
    "$ADB" shell dumpsys input 2>/dev/null | tr -d '\r' | \
        awk '/FocusedWindows:/{getline; print; exit}' || true
}

dismiss_android_overlay() {
    local focused
    focused=$(focused_window)
    if printf '%s\n' "$focused" | rg -q 'com\.rp\.settings'; then
        "$ADB" shell input keyevent 4 >/dev/null 2>&1 || true
        sleep 1
        focused=$(focused_window)
        if printf '%s\n' "$focused" | rg -q 'com\.rp\.settings'; then
            "$ADB" shell input tap 920 630 >/dev/null 2>&1 || true
            sleep 1
        fi
        echo "touch_dismissed_overlay=com.rp.settings"
    fi
}

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
    trap - EXIT INT TERM
    if [ -n "${run_pid:-}" ] && kill -0 "$run_pid" 2>/dev/null; then
        kill "$run_pid" 2>/dev/null || true
        wait "$run_pid" 2>/dev/null || true
    fi
    cleanup_remote_runtime
    "$ADB" shell am force-stop "$PACKAGE" >/dev/null 2>&1 || true
    clear_app_runtime_files
}
trap cleanup EXIT INT TERM

touch_ready=1
elapsed=0
while [ "$elapsed" -lt "$WAIT_TIMEOUT" ]; do
    dismiss_android_overlay
    "$ADB" shell run-as "$PACKAGE" cat files/android-touch-bridge-report.txt \
        >"$APP_REPORT" 2>/dev/null || true
    "$ADB" shell "su -c 'cat $DEVICE_ROOT/tmp/nova-eis-touch.log'" \
        >"$EIS_LOG" 2>/dev/null || true
    if rg -q -- 'android_touch_socket=connected' "$APP_REPORT" && \
        rg -q -- 'libei_touch_device_resumed=pass' "$EIS_LOG" && \
        "$ADB" shell "dumpsys window | grep 'mCurrentFocus=.*$PACKAGE/.*MainActivity' >/dev/null" && \
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
dismiss_android_overlay
if [ "$REQUIRE_STEAM_SURFACE" = "1" ]; then
    if [ "${NOVA_FULLSCREEN_PRESENTATION:-1}" = "1" ]; then
        touch_panel_crop=265:60:982:50
        touch_panel_min_yavg=180
    else
        touch_panel_crop=265:30:970:185
        touch_panel_min_yavg=100
    fi
    surface_wait_elapsed=0
    surface_wait_pass=0
    while [ "$surface_wait_elapsed" -lt "$SURFACE_WAIT_TIMEOUT" ]; do
        "$ADB" exec-out screencap -p >"$BEFORE_SCREENSHOT.wait.png"
        surface_wait_stats=$(ffmpeg -hide_banner -i "$BEFORE_SCREENSHOT.wait.png" \
            -vf "crop=$touch_panel_crop,signalstats,metadata=print:file=-" -f null - 2>&1 | awk -F= '
                /lavfi.signalstats.YAVG=/{yavg=$2}
                /lavfi.signalstats.YMAX=/{ymax=$2}
                END {printf "%d %d", yavg, ymax}
            ')
        read -r surface_wait_yavg surface_wait_ymax <<EOF
$surface_wait_stats
EOF
        case "$surface_wait_yavg" in ''|*[!0-9]*) surface_wait_yavg=0 ;; esac
        case "$surface_wait_ymax" in ''|*[!0-9]*) surface_wait_ymax=0 ;; esac
        if [ "$surface_wait_ymax" -ge 220 ] && [ "$surface_wait_yavg" -ge "$touch_panel_min_yavg" ]; then
            surface_wait_pass=1
            break
        fi
        sleep 2
        surface_wait_elapsed=$((surface_wait_elapsed + 2))
    done
    rm -f "$BEFORE_SCREENSHOT.wait.png"
    echo "touch_surface_wait=$([ "$surface_wait_pass" -eq 1 ] && echo pass || echo timeout)"
fi
"$ADB" exec-out screencap -p >"$BEFORE_SCREENSHOT"
echo "android_touch_tap=x:$TOUCH_X y:$TOUCH_Y"
dismiss_android_overlay
"$ADB" shell input tap "$TOUCH_X" "$TOUCH_Y" >/dev/null
sleep "$AFTER_DELAY"
"$ADB" exec-out screencap -p >"$AFTER_SCREENSHOT"

set +e
wait "$run_pid"
run_status=$?
set -e
run_pid=

if [ -n "$RUN_DIR" ] && [ -s "$RUN_DIR/android-touch-bridge-report.txt" ]; then
    cp "$RUN_DIR/android-touch-bridge-report.txt" "$APP_REPORT"
    echo "touch_report_source=run_artifact"
else
    "$ADB" shell run-as "$PACKAGE" cat files/android-touch-bridge-report.txt \
        >"$APP_REPORT" 2>/dev/null || true
    echo "touch_report_source=device_app"
fi
"$ADB" logcat -d -v threadtime -s NovaLab:I >"$APP_LOG"
"$ADB" shell "su -c 'cat $DEVICE_ROOT/tmp/nova-eis-touch.log'" \
    >"$EIS_LOG" 2>/dev/null || true

cat "$EIS_LOG" 2>/dev/null || true
cat "$APP_REPORT" 2>/dev/null || true
cat "$RUN_LOG"

echo "touch_before_screenshot=$BEFORE_SCREENSHOT"
echo "touch_after_screenshot=$AFTER_SCREENSHOT"
echo "touch_before_sha256=$(sha256sum "$BEFORE_SCREENSHOT" | cut -c1-64)"
echo "touch_after_sha256=$(sha256sum "$AFTER_SCREENSHOT" | cut -c1-64)"
if cmp -s "$BEFORE_SCREENSHOT" "$AFTER_SCREENSHOT"; then
    touch_visual_changed=fail
else
    touch_visual_changed=pass
fi
echo "touch_visual_changed=$touch_visual_changed"
if [ "$REQUIRE_VISUAL_CHANGE" = "1" ] && [ "$touch_visual_changed" != "pass" ]; then
    echo "touch_visual_changed=fail reason=required_visual_change_not_observed" >&2
    exit 1
fi

touch_panel="$BEFORE_SCREENSHOT.steam-panel.png"
ffmpeg -y -hide_banner -loglevel error -i "$BEFORE_SCREENSHOT" \
    -vf "crop=$touch_panel_crop" "$touch_panel" >/dev/null 2>&1
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
if [ "$touch_panel_ymax" -ge 220 ] && [ "$touch_panel_yavg" -ge "$touch_panel_min_yavg" ]; then
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
