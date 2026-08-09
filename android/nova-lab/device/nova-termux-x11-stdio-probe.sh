#!/system/bin/sh

set -u

ROOTFS="${1:-}"
RUN_ID="${2:-}"
CASE_DIR="${3:-}"

if [ -z "$ROOTFS" ] || [ -z "$RUN_ID" ] || [ -z "$CASE_DIR" ]; then
    echo "nova_x11_stdio_probe=fail reason=missing_arguments" >&2
    exit 2
fi

CHROOT_CASE_DIR="/tmp/nova-x11-stdio-$RUN_ID"

/system/bin/mkdir -p "$CASE_DIR" || exit 1
/system/bin/chmod 777 "$CASE_DIR" || exit 1

node_status=0
for name in null zero full random urandom tty; do
    path="$ROOTFS/dev/$name"
    if [ ! -c "$path" ]; then
        echo "nova_rootfs_device=fail name=$name path=$path"
        node_status=1
    else
        echo "nova_rootfs_device=pass name=$name path=$path"
        /system/bin/ls -lZ "$path"
    fi
done

run_case() {
    name="$1"
    command="$2"
    stdout_path="$CASE_DIR/$name.stdout"
    stderr_path="$CASE_DIR/$name.stderr"
    status_path="$CASE_DIR/$name.status"

    /system/bin/rm -f "$stdout_path" "$stderr_path" "$status_path"
    /system/bin/chroot "$ROOTFS" /usr/bin/setpriv \
        --reuid=501 --regid=20 --clear-groups \
        /bin/sh -c "$command" >"$stdout_path" 2>"$stderr_path"
    status=$?
    echo "$status" >"$status_path"
    stdout_bytes=$(/system/bin/wc -c <"$stdout_path" | /system/bin/awk '{print $1}')
    stderr_bytes=$(/system/bin/wc -c <"$stderr_path" | /system/bin/awk '{print $1}')
    echo "nova_stdio_case=$name status=$status stdout_bytes=$stdout_bytes stderr_bytes=$stderr_bytes"
    if [ -s "$stderr_path" ]; then
        /system/bin/cat "$stderr_path"
    fi
}

run_case foreground_explicit_null \
    "/bin/true </dev/null >$CHROOT_CASE_DIR/child.stdout 2>$CHROOT_CASE_DIR/child.stderr"
run_case background_implicit_stdin \
    "/bin/true >$CHROOT_CASE_DIR/child.stdout 2>$CHROOT_CASE_DIR/child.stderr & pid=\$!; wait \$pid"
run_case background_explicit_null \
    "/bin/true </dev/null >$CHROOT_CASE_DIR/child.stdout 2>$CHROOT_CASE_DIR/child.stderr & pid=\$!; wait \$pid"
run_case background_explicit_zero \
    "/bin/true </dev/zero >$CHROOT_CASE_DIR/child.stdout 2>$CHROOT_CASE_DIR/child.stderr & pid=\$!; wait \$pid"
run_case timeout_explicit_null \
    "/usr/bin/timeout 1 /bin/true </dev/null >$CHROOT_CASE_DIR/child.stdout 2>$CHROOT_CASE_DIR/child.stderr"
run_case timeout_background_explicit_null \
    "/usr/bin/timeout 1 /bin/true </dev/null >$CHROOT_CASE_DIR/child.stdout 2>$CHROOT_CASE_DIR/child.stderr & pid=\$!; wait \$pid"
run_case urandom_explicit_fd \
    "exec 3</dev/urandom; /bin/true"

case_status() {
    value=$(/system/bin/cat "$CASE_DIR/$1.status" 2>/dev/null || true)
    if [ -z "$value" ]; then
        echo 999
    else
        echo "$value"
    fi
}

foreground_status=$(case_status foreground_explicit_null)
implicit_status=$(case_status background_implicit_stdin)
explicit_null_status=$(case_status background_explicit_null)
explicit_zero_status=$(case_status background_explicit_zero)
timeout_status=$(case_status timeout_explicit_null)
timeout_background_status=$(case_status timeout_background_explicit_null)
urandom_status=$(case_status urandom_explicit_fd)

pattern=unexpected
if [ "$node_status" -eq 0 ] &&
    [ "$foreground_status" -eq 0 ] &&
    [ "$implicit_status" -ne 0 ] &&
    [ "$explicit_null_status" -eq 0 ] &&
    [ "$explicit_zero_status" -eq 0 ] &&
    [ "$timeout_status" -eq 0 ] &&
    [ "$timeout_background_status" -eq 0 ] &&
    [ "$urandom_status" -eq 0 ]; then
    pattern=implicit_background_stdin_only
fi

echo "nova_x11_stdio_probe=pass pattern=$pattern nodes=$node_status"
echo "nova_x11_stdio_statuses foreground=$foreground_status implicit=$implicit_status explicit_null=$explicit_null_status explicit_zero=$explicit_zero_status timeout=$timeout_status timeout_background=$timeout_background_status urandom=$urandom_status"
exit 0
