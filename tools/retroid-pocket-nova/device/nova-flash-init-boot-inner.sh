#!/system/bin/sh
set -eu

EXPECTED_MODEL='Retroid Pocket Nova'
EXPECTED_PRODUCT='kalama'
EXPECTED_BYTES=8388608
PATCH=/sdcard/Download/nova-init_boot_a-magisk.img
STOCK=/sdcard/Download/rp-nova-root-backup/init_boot_a.img
TARGET=/dev/block/by-name/init_boot_a
REPORT=/sdcard/Download/rp-nova-init-boot-flash-report.txt

fail() {
    echo 'flash=failed' > "$REPORT"
    echo "error=$1" >> "$REPORT"
    chmod 644 "$REPORT" 2>/dev/null || true
    exit 1
}

[ "$(getprop ro.product.model)" = "$EXPECTED_MODEL" ] || fail 'unexpected model'
[ "$(getprop ro.product.device)" = "$EXPECTED_PRODUCT" ] || fail 'unexpected product/device'
[ "$(getprop ro.boot.slot_suffix)" = '_a' ] || fail 'active slot is not _a'
[ -f "$PATCH" ] || fail 'patched image is missing'
[ -f "$STOCK" ] || fail 'stock init_boot_a backup is missing'

patch_size="$(stat -c '%s' "$PATCH")"
stock_size="$(stat -c '%s' "$STOCK")"
[ "$patch_size" = "$EXPECTED_BYTES" ] || fail 'patched image size mismatch'
[ "$stock_size" = "$EXPECTED_BYTES" ] || fail 'stock backup size mismatch'

patch_sha="$(sha256sum "$PATCH" | cut -d ' ' -f 1)"
stock_sha="$(sha256sum "$STOCK" | cut -d ' ' -f 1)"
[ "$patch_sha" != "$stock_sha" ] || fail 'patched image is identical to stock backup'
target_path="$(readlink -f "$TARGET" 2>/dev/null)" || fail 'init_boot_a target is missing'

{
    echo "model=$(getprop ro.product.model)"
    echo "product=$(getprop ro.product.device)"
    echo "fingerprint=$(getprop ro.build.fingerprint)"
    echo "slot=$(getprop ro.boot.slot_suffix)"
    echo "target=$target_path"
    echo "patch_sha256=$patch_sha"
    echo "stock_sha256=$stock_sha"
} > "$REPORT"

dd if="$PATCH" of="$TARGET" bs=4M >> "$REPORT" 2>&1
sync
target_sha="$(sha256sum "$TARGET" | cut -d ' ' -f 1)"
echo "target_sha256=$target_sha" >> "$REPORT"
[ "$target_sha" = "$patch_sha" ] || fail 'target read-back hash mismatch'
echo 'flash=verified' >> "$REPORT"
chmod 644 "$REPORT"
