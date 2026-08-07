#!/usr/bin/env bash
set -euo pipefail

ADB_BIN="${ADB:-adb}"
ADB_ARGS=()
if [[ -n "${ANDROID_SERIAL:-}" ]]; then
    ADB_ARGS=(-s "$ANDROID_SERIAL")
fi

die() {
    printf 'error: %s\n' "$1" >&2
    exit 1
}

command -v "$ADB_BIN" >/dev/null 2>&1 || die "ADB executable not found: $ADB_BIN"

adb_cmd() {
    "$ADB_BIN" "${ADB_ARGS[@]}" "$@"
}

state="$(adb_cmd get-state 2>/dev/null | tr -d '\r' || true)"
[[ "$state" = "device" ]] || die "ADB device is not ready"

model="$(adb_cmd shell getprop ro.product.model | tr -d '\r')"
product="$(adb_cmd shell getprop ro.product.device | tr -d '\r')"
slot="$(adb_cmd shell getprop ro.boot.slot_suffix | tr -d '\r')"
root_id="$(adb_cmd shell su -c id 2>/dev/null | tr -d '\r' || true)"
magisk_version="$(adb_cmd shell magisk -v 2>/dev/null | tr -d '\r' || true)"
magisk_path="$(adb_cmd shell magisk --path 2>/dev/null | tr -d '\r' || true)"

printf 'model=%s\nproduct=%s\nactive_slot=%s\n' "$model" "$product" "$slot"
printf 'su=%s\nmagisk=%s\nmagisk_path=%s\n' "$root_id" "$magisk_version" "$magisk_path"

[[ "$model" = "Retroid Pocket Nova" ]] || die "unexpected model: $model"
[[ "$product" = "kalama" ]] || die "unexpected product/device: $product"
[[ "$root_id" = *"uid=0(root)"* ]] || die "persistent Magisk root was not verified"

printf 'root=verified\n'
