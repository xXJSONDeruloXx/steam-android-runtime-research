#!/system/bin/sh

set -u

OUT="$1"
WORK="$2"
OUT_DIR="${OUT%/*}"
mkdir -p "$OUT_DIR" "$WORK"

{
    echo "probe_version=1"
    echo "timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
    echo "id=$(/system/bin/id)"
    echo "selinux=$(/system/bin/getenforce 2>&1)"
    echo "fingerprint=$(/system/bin/getprop ro.build.fingerprint)"
    echo "hardware=$(/system/bin/getprop ro.hardware)"
    echo "platform=$(/system/bin/getprop ro.board.platform)"
    echo "kernel=$(/system/bin/uname -r 2>&1)"
    echo "root_mount=$(awk '$2 == "/" { print $1 ":" $4 }' /proc/mounts 2>/dev/null)"
    echo

    for tool in unshare chroot mount umount; do
        if [ -x "/system/bin/$tool" ]; then
            echo "tool.$tool=present"
        else
            echo "tool.$tool=missing"
        fi
    done

    for path in /dev/dri/card0 /dev/dri/renderD128 /dev/kgsl-3d0 /dev/uinput /sys/class/kgsl /proc /sys; do
        if [ -e "$path" ]; then
            if [ -w "$path" ]; then
                access="rw"
            elif [ -r "$path" ]; then
                access="ro"
            else
                access="present-no-access"
            fi
            echo "path.$path=$access"
        else
            echo "path.$path=missing"
        fi
    done

    echo
    echo "namespace_test.begin"
    NS_ROOT="$WORK/android-chroot"
    NS_HELPER="$WORK/android-chroot-helper.sh"
    rm -rf "$NS_ROOT"
    mkdir -p "$NS_ROOT"
    cat >"$NS_HELPER" <<EOF
#!/system/bin/sh

NS_ROOT='$NS_ROOT'

cleanup() {
    /system/bin/umount -l "\$NS_ROOT/linkerconfig" >/dev/null 2>&1 || true
    /system/bin/umount -l "\$NS_ROOT/proc" >/dev/null 2>&1 || true
    /system/bin/umount -l "\$NS_ROOT/apex/com.android.runtime" >/dev/null 2>&1 || true
    /system/bin/umount -l "\$NS_ROOT/apex" >/dev/null 2>&1 || true
    /system/bin/umount -l "\$NS_ROOT/system" >/dev/null 2>&1 || true
}

trap cleanup EXIT
mkdir -p "\$NS_ROOT/system" "\$NS_ROOT/apex/com.android.runtime" "\$NS_ROOT/proc"
/system/bin/mount -o bind /system "\$NS_ROOT/system"
/system/bin/mount -o bind /apex "\$NS_ROOT/apex"
/system/bin/mount -o bind /apex/com.android.runtime "\$NS_ROOT/apex/com.android.runtime"
/system/bin/mount -o bind /proc "\$NS_ROOT/proc"
if [ -d /linkerconfig ]; then
    mkdir -p "\$NS_ROOT/linkerconfig"
    /system/bin/mount -o bind /linkerconfig "\$NS_ROOT/linkerconfig"
fi

status=0
/system/bin/chroot "\$NS_ROOT" /system/bin/sh -c 'echo chroot.exec=ok; /system/bin/id; test -r /proc/self/status && echo chroot.proc=ok' || status=\$?
exit "\$status"
EOF
    chmod 700 "$NS_HELPER"
    if /system/bin/unshare -m /system/bin/sh "$NS_HELPER"; then
        echo "namespace_test=pass"
        echo "chroot_test=pass"
    else
        echo "namespace_test=fail"
        echo "chroot_test=fail-or-unavailable"
    fi
    rm -rf "$NS_ROOT"
    rm -f "$NS_HELPER"
    echo "namespace_test.end"
} >"$OUT" 2>&1

exit 0
