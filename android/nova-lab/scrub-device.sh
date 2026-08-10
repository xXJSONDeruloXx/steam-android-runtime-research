#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BUILD_DIR="$SCRIPT_DIR/build"
ADB=${ADB:-/Users/kurt/.local/bin/adb}
PACKAGE=com.xjsonderulo.steamandroid.novalab
TERMUX_PACKAGE=com.termux.x11
DEVICE_ROOT_SCRIPT=/data/local/tmp/nova-device-scrub-root.sh
CONFIRM=${NOVA_SCRUB_CONFIRM:-}
STAMP=${NOVA_SCRUB_STAMP:-$(date -u +%Y%m%dT%H%M%SZ)}
BEFORE="$BUILD_DIR/nova-device-scrub-before-$STAMP.txt"
AFTER="$BUILD_DIR/nova-device-scrub-after-$STAMP.txt"

if [ "$CONFIRM" != "remove-nova-device-state" ]; then
    echo "refusing device scrub: set NOVA_SCRUB_CONFIRM=remove-nova-device-state" >&2
    exit 2
fi

mkdir -p "$BUILD_DIR"

inventory() {
    local output=$1
    {
        echo "scrub_stamp=$STAMP"
        echo "device=$($ADB get-serialno | tr -d '\r')"
        echo "nova_package=$PACKAGE"
        echo "termux_x11_package_preserved=$TERMUX_PACKAGE"
        echo "--- package paths ---"
        $ADB shell pm path "$PACKAGE" 2>&1 || true
        echo "--- processes ---"
        $ADB shell "ps -A -o PID,ARGS | grep -E 'nova|steam|Xwayland|termux.x11|uinput|libei|gamescope' | grep -v grep || true"
        echo "--- top-level nova paths ---"
        $ADB shell su -mm 0 -c "/system/bin/find /data/local/tmp -maxdepth 1 -mindepth 1 -name 'nova*' -print 2>/dev/null | /system/bin/sort"
        echo "--- listed non-nova project paths ---"
        $ADB shell su -mm 0 -c "/system/bin/sh -c 'for p in /data/local/tmp/audio-20260809T230053Z-steam-alsa-group /data/local/tmp/launcher-20260809T223146Z-x11-custom-1280x960-termux-x11-preferences.xml; do if [ -e \"\$p\" ]; then echo \"\$p\"; fi; done'"
        echo "--- storage ---"
        $ADB shell su -mm 0 -c "/system/bin/df -Pk /data/local/tmp; /system/bin/df -Pi /data/local/tmp"
    } >"$output"
}

inventory "$BEFORE"
echo "nova_device_scrub_inventory_before=$BEFORE"

$ADB shell am force-stop "$PACKAGE" >/dev/null 2>&1 || true
$ADB shell am force-stop "$TERMUX_PACKAGE" >/dev/null 2>&1 || true

launcher="/data/user/0/$PACKAGE/files/launcher/nova-one-click-root-launcher.sh"
termux_apk=$($ADB shell pm path "$TERMUX_PACKAGE" 2>/dev/null | sed -n 's/^package://p' | head -n 1 | tr -d '\r' || true)
if $ADB shell su -mm 0 -c "/system/bin/test -x $launcher" >/dev/null 2>&1; then
    $ADB shell su -mm 0 -c "/system/bin/sh $launcher stop /data/local/tmp/nova-active-runtime /data/local/tmp/nova-android-launcher $termux_apk /data/user/0/$PACKAGE/files/launcher" >/dev/null 2>&1 || true
fi

$ADB push "$SCRIPT_DIR/device/nova-device-scrub-root.sh" "$DEVICE_ROOT_SCRIPT" >/dev/null
$ADB shell su -mm 0 -c "/system/bin/sh $DEVICE_ROOT_SCRIPT"

uninstall_output=$($ADB uninstall "$PACKAGE" 2>&1 || true)
printf '%s\n' "$uninstall_output"
if ! printf '%s\n' "$uninstall_output" | grep -q 'Success'; then
    echo "nova_device_scrub=fail reason=apk_uninstall" >&2
    exit 1
fi

inventory "$AFTER"
echo "nova_device_scrub_inventory_after=$AFTER"

if grep -q '^package:' "$AFTER" || grep -q '^/data/local/tmp/nova' "$AFTER" || \
    grep -q '^/data/local/tmp/audio-20260809T230053Z-steam-alsa-group$' "$AFTER" || \
    grep -q '^/data/local/tmp/launcher-20260809T223146Z-x11-custom-1280x960-termux-x11-preferences.xml$' "$AFTER"; then
    echo "nova_device_scrub=fail reason=residual_target" >&2
    exit 1
fi
if ! $ADB shell pm path "$TERMUX_PACKAGE" >/dev/null 2>&1; then
    echo "nova_device_scrub=fail reason=termux_x11_missing" >&2
    exit 1
fi

echo "nova_device_scrub=pass package_removed=1 termux_x11_preserved=1"
