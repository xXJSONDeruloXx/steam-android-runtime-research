#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
PACKAGE=com.xjsonderulo.steamandroid.novalab
APK="$BUILD_DIR/nova-lab-debug.apk"

"$SCRIPT_DIR/build.sh" >/dev/null
"$ADB" wait-for-device
"$ADB" install -r -d "$APK" >/dev/null

ROOT_SCRIPT="$SCRIPT_DIR/src/main/assets/root-probe.sh"
DEVICE_SCRIPT=/data/local/tmp/nova-lab-root-probe.sh
DEVICE_REPORT=/data/local/tmp/nova-lab-root-probe-report.txt
DEVICE_WORK=/data/local/tmp/nova-lab-root-probe-work
"$ADB" push "$ROOT_SCRIPT" "$DEVICE_SCRIPT" >/dev/null
"$ADB" shell "su -c '/system/bin/sh $DEVICE_SCRIPT $DEVICE_REPORT $DEVICE_WORK'"
"$ADB" pull "$DEVICE_REPORT" "$BUILD_DIR/root_probe_report.txt" >/dev/null

"$ADB" logcat -c
"$ADB" shell am force-stop "$PACKAGE"
"$ADB" shell am start -W -n "$PACKAGE/.MainActivity" --ez run_native true >/dev/null
"$ADB" shell sleep 3
"$ADB" logcat -d -v threadtime NovaLab:I '*:S' > "$BUILD_DIR/device-logcat.txt"
"$ADB" exec-out screencap -p > "$BUILD_DIR/device-screenshot.png"

echo "root report: $BUILD_DIR/root_probe_report.txt"
echo "app logcat:  $BUILD_DIR/device-logcat.txt"
echo "screenshot:  $BUILD_DIR/device-screenshot.png"
