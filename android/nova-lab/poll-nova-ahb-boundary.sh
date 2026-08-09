#!/usr/bin/env bash

set -euo pipefail

ADB=${ADB:-/Users/kurt/.local/bin/adb}
RUN_ID=${NOVA_RUN_ID:?NOVA_RUN_ID is required}
RUN_DIR=${NOVA_RUN_DIR:?NOVA_RUN_DIR is required}
ANDROID_PID=${NOVA_ANDROID_PID:?NOVA_ANDROID_PID is required}
POLL_TIMEOUT_SECONDS=${NOVA_BOUNDARY_POLL_TIMEOUT_SECONDS:-180}
BLOCKED_WINDOW_SECONDS=${NOVA_BOUNDARY_BLOCKED_WINDOW_SECONDS:-30}
POLL_INTERVAL_SECONDS=${NOVA_BOUNDARY_POLL_INTERVAL_SECONDS:-1}

case "$RUN_ID" in
    ''|*[!A-Za-z0-9._-]*)
        echo "invalid NOVA_RUN_ID: $RUN_ID" >&2
        exit 2
        ;;
esac
case "$ANDROID_PID" in
    ''|*[!0-9]*)
        echo "invalid NOVA_ANDROID_PID: $ANDROID_PID" >&2
        exit 2
        ;;
esac
mkdir -p "$RUN_DIR"

case "$POLL_TIMEOUT_SECONDS:$BLOCKED_WINDOW_SECONDS:$POLL_INTERVAL_SECONDS" in
    *[!0-9:]*|*::*)
        echo "boundary poll durations must be non-negative integers" >&2
        exit 2
        ;;
esac

POLL_LOG="$RUN_DIR/boundary-poll.txt"
ALL_LOG="$RUN_DIR/logcat-live-marker-all.txt"
FILTERED_LOG="$RUN_DIR/logcat-live-marker.txt"
SOURCE="$RUN_DIR/marker-source.txt"
STATUS="$RUN_DIR/boundary-poll-status.txt"

write_status() {
    local status_code="$1"
    local status_value=fail
    if [ "$status_code" -eq 0 ]; then
        status_value=pass
    fi
    {
        printf 'nova_run_id=%s\n' "$RUN_ID"
        printf 'marker_source_pid=%s\n' "$ANDROID_PID"
        printf 'boundary_status=%s\n' "$status_value"
        printf 'boundary_marker=%s\n' "${marker:-unset}"
        printf 'boundary_frame=%s\n' "${boundary_frame:-${blocked_frame:-unset}}"
    } >"$STATUS"
}

on_exit() {
    local status_code=$?
    trap - EXIT
    write_status "$status_code"
    exit "$status_code"
}
trap on_exit EXIT

: >"$POLL_LOG"
blocked_frame=
blocked_since=
boundary_frame=
marker=
deadline=$((SECONDS + POLL_TIMEOUT_SECONDS))

while [ "$SECONDS" -lt "$deadline" ]; do
    "$ADB" logcat -d -v threadtime -s NovaLab:I '*:S' >"$ALL_LOG"
    rg "(^|[[:space:]])${ANDROID_PID}([[:space:]]|\))" "$ALL_LOG" \
        >"$FILTERED_LOG" || true

    if ! rg -q "(^|[[:space:]])${ANDROID_PID}([[:space:]]|\)).*launch_flags run_dmabuf_double_buffer" \
        "$FILTERED_LOG"; then
        printf '%s marker_source=waiting_for_pid_launch pid=%s\n' \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$ANDROID_PID" >>"$POLL_LOG"
        sleep "$POLL_INTERVAL_SECONDS"
        continue
    fi
    if [ ! -e "$SOURCE" ]; then
        {
            printf 'nova_run_id=%s\n' "$RUN_ID"
            printf 'marker_source_pid=%s\n' "$ANDROID_PID"
            printf 'marker_start_utc=%s\n' "${NOVA_RUN_STARTED_UTC:-unset}"
            printf 'marker_observed_utc=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
            printf 'marker_freshness=pass\n'
        } >"$SOURCE"
    fi

    wait_line=$(awk '/ahb_double_buffer_trace .*phase=wait_ack/ { line = $0 } END { if (line != "") print line }' \
        "$FILTERED_LOG")
    frame=$(printf '%s\n' "$wait_line" |
        sed -n 's/.*frame=\([0-9][0-9]*\).*phase=wait_ack.*/\1/p')

    if rg -q 'ahb_socket_trace op=ack_wait_timeout' "$FILTERED_LOG"; then
        marker=ack_poll_timeout
        boundary_frame=${frame:-unknown}
        printf '%s marker=%s frame=%s\n' \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$marker" \
            "$boundary_frame" >>"$POLL_LOG"
        exit 0
    fi
    if rg -q 'ahb_socket_trace op=ack_wait_poll_error' "$FILTERED_LOG"; then
        marker=ack_poll_error
        boundary_frame=${frame:-unknown}
        printf '%s marker=%s frame=%s\n' \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$marker" \
            "$boundary_frame" >>"$POLL_LOG"
        exit 0
    fi
    if rg -q 'recv_timeout_queue_bytes=' "$FILTERED_LOG"; then
        marker=recv_timeout_queue
        boundary_frame=${frame:-unknown}
        printf '%s marker=%s frame=%s\n' \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$marker" \
            "$boundary_frame" >>"$POLL_LOG"
        exit 0
    fi

    if [ -n "$frame" ]; then
        if rg -q "ahb_double_buffer_trace frame=$frame .*phase=ack_received bytes=[1-9][0-9]* .*status=0" \
            "$FILTERED_LOG"; then
            if [ -n "$blocked_frame" ]; then
                printf '%s blocked_ack_cleared frame=%s\n' \
                    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$blocked_frame" >>"$POLL_LOG"
            fi
            blocked_frame=
            blocked_since=
        elif [ "$blocked_frame" != "$frame" ]; then
            blocked_frame=$frame
            blocked_since=$SECONDS
            boundary_frame=$frame
            printf '%s blocked_ack_start_utc=%s frame=%s\n' \
                "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
                "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$frame" >>"$POLL_LOG"
        fi
    fi

    if [ -n "$blocked_since" ] &&
        [ "$((SECONDS - blocked_since))" -ge "$BLOCKED_WINDOW_SECONDS" ]; then
        marker=blocked_ack_window
        boundary_frame=$blocked_frame
        printf '%s marker=%s frame=%s elapsed=%s\n' \
            "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$marker" "$blocked_frame" \
            "$((SECONDS - blocked_since))" >>"$POLL_LOG"
        exit 0
    fi
    printf '%s frame=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        "${frame:-none}" >>"$POLL_LOG"
    sleep "$POLL_INTERVAL_SECONDS"
done

marker=marker_timeout
printf '%s marker=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$marker" >>"$POLL_LOG"
exit 1
