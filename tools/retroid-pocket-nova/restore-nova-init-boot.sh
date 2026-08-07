#!/usr/bin/env bash
set -euo pipefail

NOVA_INIT_BOOT_BYTES=8388608
FASTBOOT_BIN="${FASTBOOT:-fastboot}"
FASTBOOT_ARGS=()
STOCK_INIT_BOOT=""
CONFIRM=false

die() {
    printf 'error: %s\n' "$1" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: restore-nova-init-boot.sh --stock-init-boot PATH --yes

The Nova must already be in fastboot mode. This restores only init_boot_a.
The explicit --yes flag is required because this writes a partition.
Environment:
  ANDROID_SERIAL  Fastboot serial, when needed
  FASTBOOT        Fastboot executable to use (default: fastboot)
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --stock-init-boot)
            [[ $# -ge 2 ]] || die "--stock-init-boot requires a path"
            STOCK_INIT_BOOT="$2"
            shift 2
            ;;
        --yes)
            CONFIRM=true
            shift
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

command -v "$FASTBOOT_BIN" >/dev/null 2>&1 || die "fastboot executable not found: $FASTBOOT_BIN"
[[ -n "$STOCK_INIT_BOOT" ]] || die "--stock-init-boot is required"
[[ "$CONFIRM" = true ]] || die "refusing to flash without --yes"
[[ -f "$STOCK_INIT_BOOT" ]] || die "image not found: $STOCK_INIT_BOOT"
[[ "$(wc -c < "$STOCK_INIT_BOOT" | tr -d '[:space:]')" = "$NOVA_INIT_BOOT_BYTES" ]] || \
    die "expected an 8 MiB init_boot image"

if [[ -n "${ANDROID_SERIAL:-}" ]]; then
    FASTBOOT_ARGS=(-s "$ANDROID_SERIAL")
fi

fastboot_cmd() {
    "$FASTBOOT_BIN" "${FASTBOOT_ARGS[@]}" "$@"
}

[[ -n "$(fastboot_cmd devices)" ]] || die "no fastboot device found"

product_info="$(fastboot_cmd getvar product 2>&1 || true)"
printf '%s\n' "$product_info"
printf '%s\n' "$product_info" | grep -Eiq 'product:[[:space:]]*kalama' || \
    die "fastboot did not report product kalama"

slot_info="$(fastboot_cmd getvar current-slot 2>&1 || true)"
printf '%s\n' "$slot_info"
printf '%s\n' "$slot_info" | grep -Eiq 'current-slot:[[:space:]]*a' || \
    die "fastboot did not report current slot a"

fastboot_cmd flash init_boot_a "$STOCK_INIT_BOOT"
printf 'restored init_boot_a; reboot manually with: fastboot reboot\n'
