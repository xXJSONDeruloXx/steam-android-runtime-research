#!/system/bin/sh
set -eu

EXPECTED_MODEL='Retroid Pocket Nova'
EXPECTED_PRODUCT='kalama'
BACKUP_DIR=/sdcard/Download/rp-nova-root-backup
REPORT="$BACKUP_DIR/report.txt"

fail() {
    echo "error=$1" >&2
    exit 1
}

[ "$(getprop ro.product.model)" = "$EXPECTED_MODEL" ] || fail 'unexpected model'
[ "$(getprop ro.product.device)" = "$EXPECTED_PRODUCT" ] || fail 'unexpected product/device'
[ "$(getprop ro.boot.slot_suffix)" = '_a' ] || fail 'active slot is not _a'
[ ! -e "$BACKUP_DIR" ] || fail 'backup directory already exists; preserve it before retrying'

mkdir -p "$BACKUP_DIR"
{
    echo "model=$(getprop ro.product.model)"
    echo "product=$(getprop ro.product.device)"
    echo "fingerprint=$(getprop ro.build.fingerprint)"
    echo "slot=$(getprop ro.boot.slot_suffix)"
    echo "flash_locked=$(getprop ro.boot.flash.locked)"
    echo "verified_boot=$(getprop ro.boot.verifiedbootstate)"
    id
} > "$REPORT"

for partition in boot_a boot_b init_boot_a init_boot_b; do
    output="$BACKUP_DIR/$partition.img"
    dd if="/dev/block/by-name/$partition" of="$output" bs=4M >> "$REPORT" 2>&1
    size="$(stat -c '%s' "$output")"
    expected_size=100663296
    case "$partition" in
        init_boot_*) expected_size=8388608 ;;
    esac
    [ "$size" = "$expected_size" ] || fail "$partition size mismatch"
    echo "${partition}_size=$size" >> "$REPORT"
    echo "${partition}_sha256=$(sha256sum "$output" | cut -d ' ' -f 1)" >> "$REPORT"
done

echo 'backup=complete' >> "$REPORT"
chmod 644 "$REPORT" "$BACKUP_DIR"/*.img
