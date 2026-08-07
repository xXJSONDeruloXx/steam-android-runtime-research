#!/bin/sh

set -u

export GAMESCOPE_SCRIPT_PATH=/usr/share/gamescope/scripts
OUTPUT_WIDTH=${NOVA_AHB_WIDTH:-960}
OUTPUT_HEIGHT=${NOVA_AHB_HEIGHT:-540}
CLIENT_FRAMES=${NOVA_XWAYLAND_CLIENT_FRAMES:-120}

if [ "${1:-}" = "--client" ]; then
    client_log=/tmp/nova-xwayland-client.log
    client_stdout=/tmp/nova-xwayland-client.stdout
    client_stderr=/tmp/nova-xwayland-client.stderr
    echo "client_begin $(date +%s)" > "$client_log"
    echo "client_display=${DISPLAY:-unset}" >> "$client_log"
    export DISPLAY=:0
    echo "client_output=${OUTPUT_WIDTH}x${OUTPUT_HEIGHT}" >> "$client_log"
    if [ -x /opt/nova-kgsl-driver/nova-x11-animate ]; then
        /opt/nova-kgsl-driver/nova-x11-animate \
            "$CLIENT_FRAMES" "$OUTPUT_WIDTH" "$OUTPUT_HEIGHT" \
            >"$client_stdout" 2>"$client_stderr" &
        client_kind=animated_x11
    else
        /usr/bin/xmessage \
            -title "Nova Xwayland Gamescope probe" \
            -geometry "${OUTPUT_WIDTH}x${OUTPUT_HEIGHT}+0+0" \
            "Native Xwayland window reaching Android AHardwareBuffer" \
            >"$client_stdout" 2>"$client_stderr" &
        client_kind=xmessage
    fi
    client_pid=$!
    echo "client_kind=$client_kind" >> "$client_log"
    echo "client_pid=$client_pid" >> "$client_log"
    if /usr/bin/kill -0 "$client_pid" 2>/dev/null; then
        echo "client_started=pass" >> "$client_log"
    else
        echo "client_started=fail" >> "$client_log"
    fi
    if [ "$client_kind" = animated_x11 ]; then
        wait "$client_pid" 2>/dev/null
        client_status=$?
    else
        /usr/bin/sleep 8
        echo "sleep_complete $(date +%s)" >> "$client_log"
        /usr/bin/kill "$client_pid" 2>/dev/null || true
        wait "$client_pid" 2>/dev/null
        client_status=$?
    fi
    echo "client_status=$client_status" >> "$client_log"
    client_stdout_size=$(wc -c < "$client_stdout")
    client_stderr_size=$(wc -c < "$client_stderr")
    echo "client_stdout=$client_stdout_size" >> "$client_log"
    echo "client_stderr=$client_stderr_size" >> "$client_log"
    echo "client_end $(date +%s)" >> "$client_log"
    exit 0
fi

set +e
echo "xwayland_control_begin output=${OUTPUT_WIDTH}x${OUTPUT_HEIGHT} client_frames=$CLIENT_FRAMES output_socket=${NOVA_AHB_OUTPUT_SOCKET:-missing}" >&2
/usr/bin/timeout 25 /opt/nova-kgsl-driver/gamescope-headless \
    --backend headless \
    --xwayland-count 1 \
    --output-width "$OUTPUT_WIDTH" \
    --output-height "$OUTPUT_HEIGHT" \
    --nested-width "$OUTPUT_WIDTH" \
    --nested-height "$OUTPUT_HEIGHT" \
    -- /opt/nova-kgsl-driver/gamescope-headless-ahb-control.sh --client
status=$?
set -e
if [ "$status" -eq 124 ]; then
    exit 0
fi
exit "$status"
