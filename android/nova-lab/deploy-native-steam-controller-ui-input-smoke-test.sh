#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
PACKAGE=com.xjsonderulo.steamandroid.novalab
RUNTIME_CLEANUP="$SCRIPT_DIR/device/nova-runtime-cleanup.sh"
DEVICE_RUNTIME_CLEANUP=/data/local/tmp/nova-runtime-cleanup.sh
SOURCE_EVENT=${NOVA_STEAM_GAMEPAD_SOURCE:-/dev/input/event7}
INPUT_MODE=${NOVA_CONTROLLER_UI_INPUT_MODE:-physical}
ANDROID_KEYCODE=${NOVA_CONTROLLER_UI_ANDROID_KEYCODE:-20}
ANDROID_KEY_NAME=${NOVA_CONTROLLER_UI_ANDROID_KEY_NAME:-KEYCODE_DPAD_DOWN}
if [ "$INPUT_MODE" = "android-keyevent" ]; then
    EVENT_CODE=${NOVA_CONTROLLER_UI_EVENT_CODE:-545}
    EVENT_NAME=${NOVA_CONTROLLER_UI_EVENT_NAME:-BTN_DPAD_DOWN}
else
    EVENT_CODE=${NOVA_CONTROLLER_UI_EVENT_CODE:-304}
    EVENT_NAME=${NOVA_CONTROLLER_UI_EVENT_NAME:-BTN_SOUTH}
fi
WAIT_TIMEOUT=${NOVA_CONTROLLER_UI_WAIT_TIMEOUT:-140}
SETTLE_DELAY=${NOVA_CONTROLLER_UI_SETTLE_DELAY:-30}
STABLE_ATTEMPTS=${NOVA_CONTROLLER_UI_STABLE_ATTEMPTS:-20}
RELAY_TIMEOUT=${NOVA_CONTROLLER_UI_RELAY_TIMEOUT:-180000}
EXPECT_NAVIGATION=${NOVA_CONTROLLER_UI_EXPECT_NAVIGATION:-0}
AFTER_DELAY=${NOVA_CONTROLLER_UI_AFTER_DELAY:-20}
REQUIRE_STEAM_SURFACE=${NOVA_CONTROLLER_UI_REQUIRE_STEAM_SURFACE:-1}
MANUAL_SESSION=${NOVA_CONTROLLER_UI_MANUAL_SESSION:-0}
export NOVA_AHB_TRACE=${NOVA_AHB_TRACE:-0}
export NOVA_AHB_SOCKET_TRACE=${NOVA_AHB_SOCKET_TRACE:-0}
if [ "$MANUAL_SESSION" = "1" ]; then
    PHYSICAL_RELAY_MODE=relay
else
    PHYSICAL_RELAY_MODE=relay-once-code
fi
if [ "${NOVA_FULLSCREEN_PRESENTATION:-0}" = "1" ]; then
    STEAM_PANEL_CROP=${NOVA_CONTROLLER_UI_STEAM_PANEL_CROP:-255:280:970:45}
else
    STEAM_PANEL_CROP=${NOVA_CONTROLLER_UI_STEAM_PANEL_CROP:-255:280:970:185}
fi
STEAM_PANEL_YLOW_MIN=${NOVA_CONTROLLER_UI_STEAM_PANEL_YLOW_MIN:-20}
HELPER="$BUILD_DIR/nova-uinput-gamepad-relay"
DEVICE_HELPER="$DEVICE_ROOT/opt/nova-kgsl-driver/nova-uinput-gamepad-relay"
CHROOT_HELPER=/opt/nova-kgsl-driver/nova-uinput-gamepad-relay
DEVICE_STAGE=/data/local/tmp/nova-libei-stage
DEVICE_FD_SCRIPT=/data/local/tmp/nova-steam-input-fd-probe.sh
DEVICE_FD_REPORT=/data/local/tmp/nova-controller-ui-steam-input-fd.txt
DEVICE_RELAY_LAUNCHER=/data/local/tmp/nova-uinput-gamepad-relay-launcher.sh
DEVICE_MOUNT_PRIVATE_HELPER=/data/local/tmp/nova-mount-private
STEAM_LOGS_DIR="$DEVICE_ROOT/opt/nova-steam/home/.local/share/Steam/logs"
RUN_LOG="$BUILD_DIR/native-steam-controller-ui-input-smoke.log"
HELPER_LOG="$BUILD_DIR/nova-controller-ui-uinput-relay.log"
FD_LOG="$BUILD_DIR/nova-controller-ui-steam-input-fd.log"
BEFORE_SCREENSHOT="$BUILD_DIR/native-steam-controller-ui-before.png"
AFTER_SCREENSHOT="$BUILD_DIR/native-steam-controller-ui-after.png"
APP_LOG="$BUILD_DIR/native-steam-controller-ui-app-logcat.txt"
APP_REPORT="$BUILD_DIR/native-steam-controller-ui-app-report.txt"
RUN_DIR=${NOVA_RUN_DIR:-}

case "$INPUT_MODE" in
    physical|android-keyevent)
        ;;
    *)
        echo "unknown controller UI input mode: $INPUT_MODE" >&2
        exit 2
        ;;
esac

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
if [ "$MANUAL_SESSION" = "1" ]; then
    export NOVA_EIS_TOUCH_TIMEOUT=${NOVA_EIS_TOUCH_TIMEOUT:-86400000}
    export NOVA_EIS_TOUCH_CONTINUOUS=${NOVA_EIS_TOUCH_CONTINUOUS:-1}
fi

mkdir -p "$BUILD_DIR"
rm -f "$RUN_LOG" "$HELPER_LOG" "$FD_LOG" \
    "$BEFORE_SCREENSHOT" "$AFTER_SCREENSHOT" "$APP_LOG" "$APP_REPORT"

stop_remote_helper() {
    "$ADB" shell "su -c 'for remote_pid in \$(pidof nova-uinput-gamepad-relay 2>/dev/null); do kill -9 \$remote_pid; done'" \
        >/dev/null 2>&1 || true
}

cleanup_remote_runtime() {
    local push_status cleanup_status cleanup_output
    if "$ADB" push "$RUNTIME_CLEANUP" "$DEVICE_RUNTIME_CLEANUP" \
        >/dev/null 2>&1; then
        push_status=0
    else
        push_status=$?
    fi
    if [ "$push_status" -eq 0 ]; then
        if cleanup_output=$("$ADB" shell su -c \
            "/system/bin/sh $DEVICE_RUNTIME_CLEANUP $DEVICE_ROOT" 2>&1); then
            cleanup_status=0
        else
            cleanup_status=$?
        fi
    else
        cleanup_status=1
        cleanup_output=
    fi
    cleanup_output=$(printf '%s\n' "$cleanup_output" | tr -d '\r')
    printf '%s\n' "$cleanup_output"
    if [ "$push_status" -ne 0 ] || [ "$cleanup_status" -ne 0 ] || \
        ! printf '%s\n' "$cleanup_output" | rg -q '^nova_runtime_cleanup=pass '; then
        echo "native_steam_runtime_cleanup=fail push=$push_status command=$cleanup_status" >&2
        return 1
    fi
    echo "native_steam_runtime_cleanup=pass"
}

clear_app_runtime_files() {
    if "$ADB" shell "run-as $PACKAGE sh -c 'rm -f files/nova-input.sock files/nova-touch.sock files/nova-lab-ahb-double-buffer.sock.* files/dmabuf-double-buffer-report.txt files/android-input-bridge-report.txt files/android-touch-bridge-report.txt'" \
        >/dev/null 2>&1; then
        echo "controller_ui_app_files_cleanup=pass"
    else
        echo "controller_ui_app_files_cleanup=fail" >&2
        return 1
    fi
}

if [ "$INPUT_MODE" = "android-keyevent" ]; then
    export NOVA_ANDROID_INPUT_BRIDGE=1
    export NOVA_ANDROID_INPUT_KEY_ONLY=${NOVA_CONTROLLER_UI_ANDROID_KEY_ONLY:-1}
fi

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
stop_remote_helper
"$ADB" shell su -c "cp $DEVICE_STAGE/nova-uinput-gamepad-relay $DEVICE_HELPER"
"$ADB" shell su -c "chmod 755 $DEVICE_HELPER"
"$ADB" push "$SCRIPT_DIR/device/nova-steam-input-fd-probe.sh" \
    "$DEVICE_FD_SCRIPT" >/dev/null
"$ADB" shell su -c "chmod 755 $DEVICE_FD_SCRIPT"
"$ADB" push "$SCRIPT_DIR/device/nova-uinput-gamepad-relay-launcher.sh" \
    "$DEVICE_RELAY_LAUNCHER" >/dev/null
"$ADB" shell su -c "chmod 755 $DEVICE_RELAY_LAUNCHER"
if [ ! -x "$BUILD_DIR/nova-mount-private" ]; then
    "$SCRIPT_DIR/build-mount-private.sh" >/dev/null
fi
"$ADB" push "$BUILD_DIR/nova-mount-private" "$DEVICE_MOUNT_PRIVATE_HELPER" >/dev/null
"$ADB" shell su -c "chmod 755 $DEVICE_MOUNT_PRIVATE_HELPER"

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
    local steam_panel_ymin
    local steam_panel_ylow
    local steam_panel_yavg
    local steam_panel_ymax

    for attempt in $(seq 1 "$STABLE_ATTEMPTS"); do
        "$ADB" exec-out screencap -p >"$sample"
        ffmpeg -y -hide_banner -loglevel error -i "$sample" \
            -vf "crop=1232:312:24:170" "$surface_sample" >/dev/null 2>&1
        surface_hash=$(sha256sum "$surface_sample" | cut -c1-64)
        surface_yhigh=$(ffmpeg -hide_banner -i "$sample" \
            -vf "crop=1232:312:24:170,signalstats,metadata=print:file=-" \
            -f null - 2>&1 | awk -F= '/lavfi.signalstats.YHIGH=/{value=$2} END {printf "%s", value}')
        case "$surface_yhigh" in
            ""|*[!0-9]*) surface_yhigh=0 ;;
        esac
        if [ "$surface_yhigh" -ge 40 ]; then
            if [ "$REQUIRE_STEAM_SURFACE" = "1" ]; then
                steam_panel_stats=$(ffmpeg -hide_banner -i "$sample" \
                    -vf "crop=$STEAM_PANEL_CROP,signalstats,metadata=print:file=-" \
                    -f null - 2>&1 | awk -F= '
                        /lavfi.signalstats.YMIN=/{ymin=$2}
                        /lavfi.signalstats.YLOW=/{ylow=$2}
                        /lavfi.signalstats.YAVG=/{yavg=$2}
                        /lavfi.signalstats.YMAX=/{ymax=$2}
                        END {printf "%d %d %d %d", ymin, ylow, yavg, ymax}
                    ')
                read -r steam_panel_ymin steam_panel_ylow steam_panel_yavg steam_panel_ymax <<EOF
$steam_panel_stats
EOF
                case "$steam_panel_ymin" in
                    ''|*[!0-9]*) steam_panel_ymin=0 ;;
                esac
                case "$steam_panel_ylow" in
                    ''|*[!0-9]*) steam_panel_ylow=0 ;;
                esac
                case "$steam_panel_yavg" in
                    ''|*[!0-9]*) steam_panel_yavg=0 ;;
                esac
                case "$steam_panel_ymax" in
                    ''|*[!0-9]*) steam_panel_ymax=0 ;;
                esac
                if [ "$steam_panel_ymin" -lt 20 ] || \
                    [ "$steam_panel_ylow" -lt "$STEAM_PANEL_YLOW_MIN" ] || \
                    [ "$steam_panel_yavg" -lt 50 ] || \
                    [ "$steam_panel_yavg" -gt 90 ] || \
                    [ "$steam_panel_ymax" -lt 220 ]; then
                    sleep 1
                    continue
                fi
            fi
            cp "$sample" "$target"
            stable_surface_hash=$surface_hash
            echo "controller_ui_surface=pass"
            echo "controller_ui_screenshot=$(basename "$target")"
            echo "controller_ui_screenshot_sha256=$(sha256sum "$target" | cut -c1-64)"
            echo "controller_ui_surface_sha256=$surface_hash"
            echo "controller_ui_surface_yhigh=$surface_yhigh"
            if [ "$REQUIRE_STEAM_SURFACE" = "1" ]; then
                echo "controller_ui_steam_surface=pass"
                echo "controller_ui_steam_panel_ymin=$steam_panel_ymin"
                echo "controller_ui_steam_panel_ylow=$steam_panel_ylow"
                echo "controller_ui_steam_panel_yavg=$steam_panel_yavg"
                echo "controller_ui_steam_panel_ymax=$steam_panel_ymax"
            else
                echo "controller_ui_steam_surface=unchecked"
            fi
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
overlay_guard_pid=
cleanup_remote_helper() {
    if [ -n "${helper_pid:-}" ]; then
        stop_remote_helper
    fi
}
stop_remote_lab() {
    if [ "$MANUAL_SESSION" != "1" ]; then
        return
    fi
    local cleanup_status=0 app_files_status=0
    cleanup_remote_runtime || cleanup_status=$?
    "$ADB" shell am force-stop "$PACKAGE" >/dev/null 2>&1 || true
    clear_app_runtime_files || app_files_status=$?
    if [ "$cleanup_status" -ne 0 ]; then
        return "$cleanup_status"
    fi
    return "$app_files_status"
}
cleanup_session() {
    if [ -n "${overlay_guard_pid:-}" ] && kill -0 "$overlay_guard_pid" 2>/dev/null; then
        kill "$overlay_guard_pid" 2>/dev/null || true
        wait "$overlay_guard_pid" 2>/dev/null || true
    fi
    overlay_guard_pid=
    if [ -n "${run_pid:-}" ] && kill -0 "$run_pid" 2>/dev/null; then
        kill "$run_pid" 2>/dev/null || true
    fi
    cleanup_remote_helper
    if ! stop_remote_lab; then
        echo "controller_ui_runtime_cleanup=fail" >&2
    fi
}
trap cleanup_session EXIT INT TERM

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
            # The Nova settings overlay can show its USB dialog without
            # honoring BACK; its fixed Cancel action is at this coordinate.
            "$ADB" shell input tap 920 630 >/dev/null 2>&1 || true
            sleep 1
        fi
        echo "controller_ui_dismissed_overlay=com.rp.settings"
    fi
}

overlay_guard_loop() {
    while :; do
        if printf '%s\n' "$(focused_window)" | rg -q 'com\.rp\.settings'; then
            dismiss_android_overlay
        fi
        sleep 1
    done
}

start_overlay_guard() {
    if [ "$MANUAL_SESSION" = "1" ]; then
        overlay_guard_loop &
        overlay_guard_pid=$!
        echo "controller_ui_overlay_guard=started pid=$overlay_guard_pid"
    fi
}

steamui_html_lines=$(device_line_count "$STEAM_LOGS_DIR/steamui_html.txt")
webhelper_js_lines=$(device_line_count "$STEAM_LOGS_DIR/webhelper_js.txt")

# The nested deploy path force-stops the APK, purges its app-owned bridge files,
# and records fresh Steam log baselines before launching the new Activity.
"$ADB" shell am force-stop "$PACKAGE"

set +e
"$SCRIPT_DIR/deploy-native-steam-smoke-test.sh" >"$RUN_LOG" 2>&1 &
run_pid=$!
set -e

source_ready=1
app_data_dir=
socket_path=
elapsed=0
while [ "$elapsed" -lt "$WAIT_TIMEOUT" ]; do
    input_available=0
    if [ "$INPUT_MODE" = "physical" ] && \
        "$ADB" shell su -c "test -e $SOURCE_EVENT" \
            >/dev/null 2>&1; then
        input_available=1
    elif [ "$INPUT_MODE" = "android-keyevent" ]; then
        source_available=0
        if "$ADB" shell su -c "test -e $SOURCE_EVENT" \
            >/dev/null 2>&1; then
            source_available=1
        fi
        if [ -z "$socket_path" ]; then
            app_data_dir=$("$ADB" shell run-as "$PACKAGE" pwd 2>/dev/null | tr -d '\r' || true)
            if [ -n "$app_data_dir" ]; then
                socket_path="@$app_data_dir/files/nova-input.sock"
            fi
        fi
        if [ "$source_available" -eq 1 ] && [ -n "$socket_path" ] && \
            "$ADB" shell cat /proc/net/unix 2>/dev/null | tr -d '\r' | \
                rg -F -- "$socket_path" >/dev/null; then
            input_available=1
        fi
    fi
    if [ "$input_available" -eq 1 ]; then
        set +e
        if [ "$INPUT_MODE" = "physical" ]; then
            "$ADB" shell su -c \
                "/system/bin/sh $DEVICE_RELAY_LAUNCHER $DEVICE_ROOT $CHROOT_HELPER $SOURCE_EVENT $RELAY_TIMEOUT $PHYSICAL_RELAY_MODE $([ "$PHYSICAL_RELAY_MODE" = "relay-once-code" ] && printf '%s' "$EVENT_CODE")" \
                >"$HELPER_LOG" 2>&1 &
        else
            "$ADB" shell su -c \
                "/system/bin/sh $DEVICE_RELAY_LAUNCHER $DEVICE_ROOT $CHROOT_HELPER $SOURCE_EVENT $RELAY_TIMEOUT socket $socket_path" \
                >"$HELPER_LOG" 2>&1 &
        fi
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
    if [ -n "$app_pid" ] && \
        "$ADB" shell "su -c 'ps -A -o ARGS | grep -q steamwebhelper && tail -n +$((steamui_html_lines + 1)) $STEAM_LOGS_DIR/steamui_html.txt | grep -q \"Started webhelper process\" && tail -n +$((webhelper_js_lines + 1)) $STEAM_LOGS_DIR/webhelper_js.txt | grep -q \"CWebSocketConnection (steamUI): connection ready\" && tail -n +$((webhelper_js_lines + 1)) $STEAM_LOGS_DIR/webhelper_js.txt | grep -q \"OOBE Store: keyboards\"'" \
        >/dev/null 2>&1; then
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
echo "controller_ui_input_mode=$INPUT_MODE"
echo "controller_ui_relay_ready=$([ "$helper_ready" -eq 0 ] && echo 1 || echo 0)"
echo "controller_ui_ahb_trace=$NOVA_AHB_TRACE"
echo "controller_ui_ahb_socket_trace=$NOVA_AHB_SOCKET_TRACE"
if [ -n "$app_pid" ]; then
    echo "controller_ui_ready=$([ "$ui_ready" -eq 0 ] && echo 1 || echo 0) app_pid=$app_pid"
else
    echo "controller_ui_ready=0 app_pid=missing"
fi

if [ "$MANUAL_SESSION" = "1" ]; then
    if [ "$ui_ready" -eq 0 ]; then
        # Manual sessions must start with the same input focus invariant as
        # bounded runs; otherwise Android's USB chooser can consume real
        # controls and make a healthy Steam session appear unresponsive.
        dismiss_android_overlay
        start_overlay_guard
    fi
    echo "controller_ui_manual_session=$([ "$ui_ready" -eq 0 ] && echo ready || echo not_ready)"
    set +e
    wait "$run_pid"
    run_status=$?
    if [ -n "${helper_pid:-}" ]; then
        cleanup_remote_helper
        wait "$helper_pid"
        helper_status=$?
    else
        helper_status=1
    fi
    if [ -n "${fd_pid:-}" ]; then
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
    exit "$run_status"
fi

event_sent=1
stable_surface_hash=
navigation_result=unknown
if [ "$ui_ready" -eq 0 ]; then
    sleep "$SETTLE_DELAY"
    # The Nova settings process can put its USB chooser above the Steam
    # surface during an ADB-connected run.  It intercepts physical controls
    # too, so clear it before sampling regardless of the input transport.
    dismiss_android_overlay
    if capture_ready_screenshot "$BEFORE_SCREENSHOT"; then
        if [ "$INPUT_MODE" = "physical" ]; then
            "$ADB" shell su -c \
                "sendevent $SOURCE_EVENT 1 $EVENT_CODE 1; sendevent $SOURCE_EVENT 0 0 0; sendevent $SOURCE_EVENT 1 $EVENT_CODE 0; sendevent $SOURCE_EVENT 0 0 0" \
                >/dev/null
        else
            "$ADB" shell input keyevent "$ANDROID_KEYCODE" >/dev/null 2>&1 || true
        fi
        event_sent=0
        if [ "$INPUT_MODE" = "physical" ]; then
            echo "controller_ui_event=$EVENT_NAME code=$EVENT_CODE"
        else
            echo "controller_ui_android_event=$ANDROID_KEY_NAME code=$ANDROID_KEYCODE maps_to=$EVENT_NAME code=$EVENT_CODE"
        fi
        sleep "$AFTER_DELAY"
        dismiss_android_overlay
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
            -vf "crop=$STEAM_PANEL_CROP" "$before_panel" >/dev/null 2>&1
        ffmpeg -y -hide_banner -loglevel error -i "$AFTER_SCREENSHOT" \
            -vf "crop=$STEAM_PANEL_CROP" "$after_panel" >/dev/null 2>&1
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
if [ "$INPUT_MODE" = "android-keyevent" ]; then
    "$ADB" logcat -d -v threadtime NovaLab:I '*:S' >"$APP_LOG"
    if [ -n "$RUN_DIR" ] && [ -s "$RUN_DIR/android-input-bridge-report.txt" ]; then
        cp "$RUN_DIR/android-input-bridge-report.txt" "$APP_REPORT"
        echo "controller_ui_android_input_report_source=run_artifact"
    else
        "$ADB" shell run-as "$PACKAGE" cat files/android-input-bridge-report.txt \
            >"$APP_REPORT" 2>/dev/null || true
        echo "controller_ui_android_input_report_source=device_app"
    fi
    cat "$APP_LOG"
    cat "$APP_REPORT"
fi
echo "controller_ui_run_status=$run_status"
echo "controller_ui_helper_status=$helper_status"
echo "controller_ui_fd_status=$fd_status"

if [ "$run_status" -ne 0 ]; then
    echo "native_steam_controller_ui_input_smoke=fail underlying_status=$run_status" >&2
    exit "$run_status"
fi
if [ "$INPUT_MODE" = "physical" ]; then
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
else
    for marker in \
        'uinput_device_ready=pass' \
        'android_input_socket_connected=pass' \
        'android_key_forwarded=pass' \
        'android_input_forwarded=pass'; do
        if ! rg -q -- "$marker" "$HELPER_LOG"; then
            echo "missing Android input relay marker: $marker" >&2
            exit 1
        fi
    done
    if rg -q -- "android_input_key_received code=$ANDROID_KEYCODE linux_code=$EVENT_CODE event=$EVENT_NAME action=0" \
        "$HELPER_LOG" && \
        rg -q -- "android_input_key_received code=$ANDROID_KEYCODE linux_code=$EVENT_CODE event=$EVENT_NAME action=1" \
        "$HELPER_LOG"; then
        echo "controller_ui_android_input_marker=press_release"
    elif rg -q -- "android_input_key_received code=$ANDROID_KEYCODE linux_code=$EVENT_CODE event=$EVENT_NAME action=1" \
        "$HELPER_LOG"; then
        echo "controller_ui_android_input_marker=release_only"
        if ! rg -q -- "android_input_key_normalized keycode=$ANDROID_KEYCODE synthesized_down=1" \
            "$APP_REPORT"; then
            echo "missing Android key normalization marker" >&2
            exit 1
        fi
        echo "controller_ui_android_key_normalized=pass"
    else
        echo "missing Android input relay marker: exact requested key event" >&2
        exit 1
    fi
    for marker in \
        'android_input_socket=listening' \
        'android_input_socket=connected' \
        'android_input_key_forwarded=pass' \
        "android_input_key_dispatch keycode=$ANDROID_KEYCODE action=[01] source=0x"; do
        if ! rg -q -- "$marker" "$APP_REPORT"; then
            echo "missing Android app bridge marker: $marker" >&2
            exit 1
        fi
    done
    if ! rg -q -- 'android_input_device_controller=pass' "$APP_LOG" "$APP_REPORT"; then
        echo "missing Android controller enumeration marker" >&2
        exit 1
    fi
    echo "controller_ui_android_input_bridge=pass"
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
