#!/usr/bin/env bash
set -euo pipefail

NOVA_INIT_BOOT_BYTES=8388608
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
ADB_BIN="${ADB:-adb}"
ADB_ARGS=()
STOCK_INIT_BOOT=""
PATCHED_INIT_BOOT=""

die() {
    printf 'error: %s\n' "$1" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: stage-nova-root.sh [--stock-init-boot PATH] [--patched-init-boot PATH]

Environment:
  ANDROID_SERIAL  ADB serial when more than one device is connected
  ADB             ADB executable to use (default: adb)

The optional stock image is staged as nova-init_boot_a-stock.img. The optional
patched image is staged as nova-init_boot_a-magisk.img.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --stock-init-boot)
            [[ $# -ge 2 ]] || die "--stock-init-boot requires a path"
            STOCK_INIT_BOOT="$2"
            shift 2
            ;;
        --patched-init-boot)
            [[ $# -ge 2 ]] || die "--patched-init-boot requires a path"
            PATCHED_INIT_BOOT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown argument: $1"
            ;;
    esac
done

command -v "$ADB_BIN" >/dev/null 2>&1 || die "ADB executable not found: $ADB_BIN"
if [[ -n "${ANDROID_SERIAL:-}" ]]; then
    ADB_ARGS=(-s "$ANDROID_SERIAL")
fi

adb_cmd() {
    "$ADB_BIN" "${ADB_ARGS[@]}" "$@"
}

read_prop() {
    adb_cmd shell getprop "$1" | tr -d '\r'
}

image_size() {
    wc -c < "$1" | tr -d '[:space:]'
}

check_image() {
    local path="$1"
    [[ -f "$path" ]] || die "image not found: $path"
    [[ "$(image_size "$path")" = "$NOVA_INIT_BOOT_BYTES" ]] || \
        die "expected an 8 MiB init_boot image: $path"
}

state="$(adb_cmd get-state 2>/dev/null | tr -d '\r' || true)"
[[ "$state" = "device" ]] || die "ADB device is not ready"

model="$(read_prop ro.product.model)"
product="$(read_prop ro.product.device)"
locked="$(read_prop ro.boot.flash.locked)"
slot="$(read_prop ro.boot.slot_suffix)"
[[ "$model" = "Retroid Pocket Nova" ]] || die "unexpected model: $model"
[[ "$product" = "kalama" ]] || die "unexpected product/device: $product"
[[ "$locked" = "0" ]] || die "bootloader is not reported unlocked"
[[ "$slot" = "_a" ]] || die "this kit only targets active slot _a; found: $slot"

if [[ -n "$STOCK_INIT_BOOT" ]]; then
    check_image "$STOCK_INIT_BOOT"
fi
if [[ -n "$PATCHED_INIT_BOOT" ]]; then
    check_image "$PATCHED_INIT_BOOT"
fi

for script in \
    nova-backup.sh \
    nova-backup-inner.sh \
    nova-flash-init-boot.sh \
    nova-flash-init-boot-inner.sh; do
    adb_cmd push "$SCRIPT_DIR/device/$script" "/sdcard/Download/$script" >/dev/null
done

if [[ -n "$STOCK_INIT_BOOT" ]]; then
    adb_cmd push "$STOCK_INIT_BOOT" /sdcard/Download/nova-init_boot_a-stock.img >/dev/null
fi
if [[ -n "$PATCHED_INIT_BOOT" ]]; then
    adb_cmd push "$PATCHED_INIT_BOOT" /sdcard/Download/nova-init_boot_a-magisk.img >/dev/null
fi

printf 'staged Nova scripts for model=%s product=%s active_slot=%s\n' "$model" "$product" "$slot"
printf 'download path: /sdcard/Download/\n'
printf 'select nova-backup.sh or nova-flash-init-boot.sh in Handheld Settings -> Advanced -> Run script as Root\n'
