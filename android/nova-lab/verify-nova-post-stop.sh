#!/usr/bin/env bash

set -euo pipefail

ADB=${ADB:-/Users/kurt/.local/bin/adb}
PACKAGE=com.xjsonderulo.steamandroid.novalab
DEVICE_ROOT=${DEVICE_ROOT:-/data/local/tmp/nova-holo-rootfs}
RUN_ID=${NOVA_RUN_ID:?set NOVA_RUN_ID to the stopped run identity}
RUN_DIR=${NOVA_RUN_DIR:?set NOVA_RUN_DIR to the stopped run directory}
REPORT=${NOVA_POST_STOP_REPORT:?set NOVA_POST_STOP_REPORT to the pulled run report}
FORWARD_PORT=${NOVA_POST_STOP_FORWARD_PORT:-}
OUTPUT=${NOVA_POST_STOP_OUTPUT:-$RUN_DIR/post-stop-verification.txt}

if [ ! -d "$RUN_DIR" ]; then
    echo "missing run directory: $RUN_DIR" >&2
    exit 1
fi
if [ ! -s "$REPORT" ]; then
    echo "missing or empty stopped-run report: $REPORT" >&2
    exit 1
fi

exec > >(tee "$OUTPUT") 2>&1

failures=0

report_sha256=$(shasum -a 256 "$REPORT" | awk '{print $1}')
echo "nova_run_id=$RUN_ID"
echo "post_stop_report=$REPORT"
echo "post_stop_report_sha256=$report_sha256"

if [ -n "$FORWARD_PORT" ]; then
    forward_output=$($ADB forward --list 2>&1 | tr -d '\r' || true)
    if printf '%s\n' "$forward_output" | rg -F "tcp:$FORWARD_PORT" >/dev/null; then
        echo "post_stop_adb_forward=fail port=$FORWARD_PORT" >&2
        printf '%s\n' "$forward_output" >&2
        failures=$((failures + 1))
    else
        echo "post_stop_adb_forward=pass port=$FORWARD_PORT";
    fi
fi

if device_processes=$($ADB shell su -c "/system/bin/ps -A -o PID,PPID,ARGS" 2>&1); then
    device_processes=$(printf '%s\n' "$device_processes" | tr -d '\r')
    device_process_status=0
else
    device_process_status=$?
    device_processes=$(printf '%s\n' "$device_processes" | tr -d '\r')
fi
if [ "$device_process_status" -ne 0 ]; then
    echo "post_stop_process_check=fail status=$device_process_status" >&2
    printf '%s\n' "$device_processes" >&2
    failures=$((failures + 1))
fi
residual_processes=$(printf '%s\n' "$device_processes" | \
    rg -e "$DEVICE_ROOT/opt/nova-steam" \
       -e '/opt/nova-kgsl-driver/gamescope-headless' \
       -e '/opt/nova-kgsl-driver/nova-libei-input-bridge' \
       -e '/opt/nova-kgsl-driver/nova-uinput-gamepad-relay' | \
    rg -v 'nova-runtime-cleanup|app_process|content call|su -c|ps -A -o PID,PPID,ARGS|grep' || true)
if [ -n "$residual_processes" ]; then
    echo "post_stop_residual_processes=fail" >&2
    printf '%s\n' "$residual_processes" >&2
    failures=$((failures + 1))
else
    echo "post_stop_residual_processes=pass"
fi

app_files_output=
if app_files_output=$($ADB shell \
    "run-as $PACKAGE sh -c 'for path in files/nova-input.sock files/nova-touch.sock files/nova-lab-ahb-double-buffer.sock.* files/dmabuf-double-buffer-report.txt files/android-input-bridge-report.txt files/android-touch-bridge-report.txt; do if [ -e \"\$path\" ]; then echo \"\$path\"; fi; done'" \
    2>&1); then
    app_files_status=0
else
    app_files_status=$?
fi
app_files_output=$(printf '%s\n' "$app_files_output" | tr -d '\r')
if [ "$app_files_status" -ne 0 ]; then
    echo "post_stop_app_files=fail status=$app_files_status" >&2
    printf '%s\n' "$app_files_output" >&2
    failures=$((failures + 1))
elif [ -n "$app_files_output" ]; then
    echo "post_stop_app_files=fail" >&2
    printf '%s\n' "$app_files_output" >&2
    failures=$((failures + 1))
else
    echo "post_stop_app_files=pass"
fi

if trace_output=$($ADB shell \
    "su -c 'printf \"ahb-trace=\"; cat $DEVICE_ROOT/opt/nova-steam/ahb-trace; printf \"ahb-socket-trace=\"; cat $DEVICE_ROOT/opt/nova-steam/ahb-socket-trace; printf \"ahb-scheduler-trace=\"; cat $DEVICE_ROOT/opt/nova-steam/ahb-scheduler-trace'" \
    2>&1); then
    trace_status=0
else
    trace_status=$?
fi
trace_output=$(printf '%s\n' "$trace_output" | tr -d '\r')
if [ "$trace_status" -ne 0 ]; then
    echo "post_stop_trace_query=fail status=$trace_status" >&2
    printf '%s\n' "$trace_output" >&2
    failures=$((failures + 1))
fi
printf '%s\n' "$trace_output"
if [ "$trace_status" -eq 0 ] && \
    printf '%s\n' "$trace_output" | rg -q '^ahb-trace=0$' && \
    printf '%s\n' "$trace_output" | rg -q '^ahb-socket-trace=0$' && \
    printf '%s\n' "$trace_output" | rg -q '^ahb-scheduler-trace=0$'; then
    echo "post_stop_trace_state=pass"
else
    echo "post_stop_trace_state=fail" >&2
    failures=$((failures + 1))
fi

if ack_poll_output=$($ADB shell getprop debug.nova.ahb_ack_poll_timeout_ms 2>&1); then
    ack_poll_status=0
else
    ack_poll_status=$?
fi

if scheduler_trace_output=$($ADB shell getprop debug.nova.ahb_scheduler_trace 2>&1); then
    scheduler_trace_status=0
else
    scheduler_trace_status=$?
fi
scheduler_trace_output=$(printf '%s\n' "$scheduler_trace_output" | tr -d '\r')
scheduler_trace_value=$(printf '%s\n' "$scheduler_trace_output" | tail -n 1)
echo "debug.nova.ahb_scheduler_trace=$scheduler_trace_value"
if [ "$scheduler_trace_status" -eq 0 ] && [ "$scheduler_trace_value" = "0" ]; then
    echo "post_stop_scheduler_trace_state=pass"
else
    echo "post_stop_scheduler_trace_state=fail" >&2
    failures=$((failures + 1))
fi
ack_poll_output=$(printf '%s\n' "$ack_poll_output" | tr -d '\r')
ack_poll_value=$(printf '%s\n' "$ack_poll_output" | tail -n 1)
echo "debug.nova.ahb_ack_poll_timeout_ms=$ack_poll_value"
if [ "$ack_poll_status" -eq 0 ] && [ "$ack_poll_value" = "0" ]; then
    echo "post_stop_ack_poll_timeout_state=pass"
else
    echo "post_stop_ack_poll_timeout_state=fail status=$ack_poll_status" >&2
    failures=$((failures + 1))
fi

if [ "$failures" -ne 0 ]; then
    echo "post_stop_verification=fail failures=$failures" >&2
    exit 1
fi
echo "post_stop_verification=pass"
