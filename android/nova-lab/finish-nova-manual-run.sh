#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ADB=${ADB:-/Users/kurt/.local/bin/adb}
RUN_ID=${NOVA_RUN_ID:?NOVA_RUN_ID is required}
RUN_DIR=${NOVA_RUN_DIR:?NOVA_RUN_DIR is required}
FORWARD_PORT=${NOVA_POST_STOP_FORWARD_PORT:?NOVA_POST_STOP_FORWARD_PORT is required}
REPORT_SOURCE=${NOVA_POST_STOP_REPORT_SOURCE:-$SCRIPT_DIR/build/holo-glibc-report.txt}
POST_STOP_REPORT=${NOVA_POST_STOP_REPORT:-$RUN_DIR/report-pulled-on-stop.txt}

case "$FORWARD_PORT" in
    ''|*[!0-9]*)
        echo "invalid NOVA_POST_STOP_FORWARD_PORT: $FORWARD_PORT" >&2
        exit 2
        ;;
esac
mkdir -p "$RUN_DIR"
exec > >(tee "$RUN_DIR/post-stop-teardown.log") 2>&1

echo "nova_teardown_run_id=$RUN_ID"
"$SCRIPT_DIR/deploy-native-steam-manual-session.sh" stop

if [ ! -s "$REPORT_SOURCE" ]; then
    echo "post-stop report source is missing or empty: $REPORT_SOURCE" >&2
    exit 1
fi
cp "$REPORT_SOURCE" "$POST_STOP_REPORT"
test -s "$POST_STOP_REPORT"
echo "post_stop_report_sha256=$(sha256sum "$POST_STOP_REPORT" | awk '{print $1}')"

if "$ADB" forward --remove "tcp:$FORWARD_PORT"; then
    echo "post_stop_forward_remove=pass port=$FORWARD_PORT"
else
    echo "post_stop_forward_remove=fail port=$FORWARD_PORT" >&2
    exit 1
fi

NOVA_RUN_ID="$RUN_ID" NOVA_RUN_DIR="$RUN_DIR" \
    NOVA_POST_STOP_REPORT="$POST_STOP_REPORT" \
    NOVA_POST_STOP_FORWARD_PORT="$FORWARD_PORT" \
    "$SCRIPT_DIR/verify-nova-post-stop.sh"
echo "nova_teardown_status=pass"
