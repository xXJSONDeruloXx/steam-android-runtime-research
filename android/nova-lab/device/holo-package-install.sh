#!/system/bin/sh

set -u

ROOT="$1"
PACKAGES="$2"
OUT="$3"
WORK="$4"
OUT_DIR="${OUT%/*}"
mkdir -p "$OUT_DIR" "$WORK"

{
    echo "probe_version=1"
    echo "rootfs=$ROOT"
    echo "packages=$PACKAGES"
    echo "timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"

    HELPER="$WORK/holo-package-helper.sh"
    cat >"$HELPER" <<EOF
#!/system/bin/sh

ROOT='$ROOT'
PACKAGES='$PACKAGES'
status=0

cleanup() {
    /system/bin/umount -l "\$ROOT/tmp/holo-pkgs" >/dev/null 2>&1 || true
    /system/bin/umount -l "\$ROOT/sys" >/dev/null 2>&1 || true
    /system/bin/umount -l "\$ROOT/proc" >/dev/null 2>&1 || true
    /system/bin/umount -l "\$ROOT/dev" >/dev/null 2>&1 || true
}

mount_one() {
    source="\$1"
    target="\$2"
    mkdir -p "\$target"
    if /system/bin/mount -o bind "\$source" "\$target"; then
        echo "mount.\$target=pass"
    else
        echo "mount.\$target=fail"
        status=1
    fi
}

trap cleanup EXIT
mount_one /dev "\$ROOT/dev"
mount_one /proc "\$ROOT/proc"
mount_one /sys "\$ROOT/sys"
mount_one "\$PACKAGES" "\$ROOT/tmp/holo-pkgs"

if [ "\$status" -eq 0 ]; then
    echo "pacman.begin"
    /system/bin/chroot "\$ROOT" /usr/bin/env -i PATH=/usr/bin:/bin HOME=/tmp /usr/bin/sh -c '/usr/bin/pacman --noconfirm -U /tmp/holo-pkgs/*.pkg.tar.zst' || status=1
    echo "pacman.end"
else
    echo "pacman=skipped-mount-failure"
fi

exit "\$status"
EOF
    chmod 700 "$HELPER"
    /system/bin/unshare -m /system/bin/sh "$HELPER"
    status=$?
    rm -f "$HELPER"
    echo "install_status=$status"
    exit "$status"
} >"$OUT" 2>&1

exit $?
