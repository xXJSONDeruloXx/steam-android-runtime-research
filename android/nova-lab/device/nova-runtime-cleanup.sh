#!/system/bin/sh

set -u

ROOT="${1:-/data/local/tmp/nova-holo-rootfs}"
SELF_PID=$$
EXCLUDE_PIDS="${NOVA_RUNTIME_CLEANUP_EXCLUDE_PIDS:-}"
EXCLUDE_PIDS=$(printf '%s\n' "$EXCLUDE_PIDS" | tr '\n' ' ')

runtime_pids() {
    /system/bin/ps -A -o PID,PPID,ARGS 2>/dev/null | \
        /system/bin/awk -v root="$ROOT" -v self="$SELF_PID" -v exclude="$EXCLUDE_PIDS" '
            BEGIN {
                count = split(exclude, values, /[[:space:]]+/)
                for (slot = 1; slot <= count; slot++) {
                    if (values[slot] != "") {
                        protected[values[slot]] = 1
                    }
                }
            }
            NR == 1 { next }
            {
                pid = $1
                args = $0
                if (pid == "" || pid == self || protected[pid]) {
                    next
                }
                if (index(args, "awk") || index(args, "nova-runtime-cleanup")) {
                    next
                }
                # The one-click stop command itself carries ROOT and would
                # otherwise be indistinguishable from a launch wrapper when
                # invoked through adb shell/su. Preserve this exact caller;
                # its separate start wrapper remains in the cleanup set.
                if (index(args, "nova-one-click-root-launcher.sh stop")) {
                    next
                }
                # Magisk may expose an in-flight `su -c` as a content-provider
                # policy-log wrapper. Its --command argument can contain ROOT,
                # but it is not part of the Nova runtime to terminate.
                if (index(args, "com.android.commands.content.Content")) {
                    next
                }
                # The launch wrappers carry ROOT as an argument, while their
                # chrooted descendants expose only /opt/nova-steam. Matching
                # ROOT here seeds the descendant walk with the exact Nova
                # launcher tree without broad process-name termination.
                if (index(args, root) ||
                    index(args, root "/opt/nova-steam") ||
                    index(args, "/opt/nova-kgsl-driver/gamescope-headless") ||
                    index(args, "gamescope-headless-ahb-control.sh") ||
                    index(args, "nova-libei-input-bridge") ||
                    index(args, "nova-uinput-gamepad-relay")) {
                    print pid
                }
            }'
}

descendant_pids() {
    parents=$(printf '%s\n' "$1" | tr '\n' ' ')
    /system/bin/ps -A -o PID,PPID,ARGS 2>/dev/null | \
        /system/bin/awk -v parents="$parents" -v self="$SELF_PID" -v exclude="$EXCLUDE_PIDS" '
            BEGIN {
                count = split(parents, values, /[[:space:]]+/)
                for (slot = 1; slot <= count; slot++) {
                    if (values[slot] != "") {
                        wanted[values[slot]] = 1
                    }
                }
                count = split(exclude, values, /[[:space:]]+/)
                for (slot = 1; slot <= count; slot++) {
                    if (values[slot] != "") {
                        protected[values[slot]] = 1
                    }
                }
            }
            NR == 1 { next }
            {
                pid = $1
                parent = $2
                if (pid == "" || pid == self || protected[pid]) {
                    next
                }
                if (index($0, "awk") || index($0, "nova-runtime-cleanup")) {
                    next
                }
                if (index($0, "nova-one-click-root-launcher.sh stop")) {
                    next
                }
                if (wanted[parent]) {
                    print pid
                }
            }'
}

all_runtime_pids() {
    pids=$(runtime_pids | tr '\n' ' ')
    # Include children of the exact Nova launchers. This catches shell,
    # Xwayland, gamescopereaper, Steam, and webhelper descendants whose argv
    # no longer contains the original rootfs path after chroot.
    iteration=0
    while [ "$iteration" -lt 8 ]; do
        children=$(descendant_pids "$pids")
        if [ -z "$children" ]; then
            break
        fi
        pids="$pids $children"
        iteration=$((iteration + 1))
    done
    printf '%s\n' "$pids" | /system/bin/awk 'NF && !seen[$1]++ { print $1 }'
}

runtime_process_snapshot() {
    snapshot_label="$1"
    snapshot_targets="$2"
    if [ -z "$snapshot_targets" ]; then
        return 0
    fi
    # Android toybox awk rejects a multiline value passed through `-v`. The
    # PID list is intentionally numeric, so normalize its separators before
    # handing it to awk while preserving the same membership test.
    snapshot_targets=$(printf '%s\n' "$snapshot_targets" | tr '\n' ' ')
    echo "nova_runtime_cleanup_${snapshot_label}_snapshot_begin"
    /system/bin/ps -A -o PID,PPID,ARGS 2>/dev/null | \
        /system/bin/awk -v targets="$snapshot_targets" -v exclude="$EXCLUDE_PIDS" '
            BEGIN {
                count = split(targets, values, /[[:space:]]+/)
                for (slot = 1; slot <= count; slot++) {
                    if (values[slot] != "") {
                        wanted[values[slot]] = 1
                    }
                }
                count = split(exclude, values, /[[:space:]]+/)
                for (slot = 1; slot <= count; slot++) {
                    if (values[slot] != "") {
                        protected[values[slot]] = 1
                    }
                }
            }
            NR == 1 { next }
            wanted[$1] && !protected[$1] &&
                !index($0, "nova-one-click-root-launcher.sh stop") { print }
        '
    echo "nova_runtime_cleanup_${snapshot_label}_snapshot_end"
}

kill_runtime() {
    signal="$1"
    pids=$(all_runtime_pids)
    if [ -n "$pids" ]; then
        # Word splitting is intentional: all values come from numeric ps PIDs.
        /system/bin/kill -"$signal" $pids 2>/dev/null || true
    fi
    printf '%s\n' "$pids"
}

term_pids=
kill_pids=
remaining=
attempts=0
while [ "$attempts" -lt 3 ]; do
    current_term=$(kill_runtime TERM)
    current_kill=
    if [ -n "$term_pids" ] && [ -n "$current_term" ]; then
        term_pids="$term_pids
$current_term"
    elif [ -n "$current_term" ]; then
        term_pids=$current_term
    fi
    runtime_process_snapshot "term" "$current_term"
    /system/bin/sleep 1
    current_kill=$(kill_runtime KILL)
    if [ -n "$kill_pids" ] && [ -n "$current_kill" ]; then
        kill_pids="$kill_pids
$current_kill"
    elif [ -n "$current_kill" ]; then
        kill_pids=$current_kill
    fi
    runtime_process_snapshot "kill" "$current_kill"
    /system/bin/sleep 1
    remaining=$(all_runtime_pids)
    runtime_process_snapshot "remaining" "$remaining"
    attempts=$((attempts + 1))
    if [ -z "$remaining" ]; then
        break
    fi
done

if [ -z "$remaining" ]; then
    status=pass
else
    status=fail
fi
echo "nova_runtime_cleanup=$status root=$ROOT attempts=$attempts term_pids=$(printf '%s' "$term_pids" | tr '\n' ',') kill_pids=$(printf '%s' "$kill_pids" | tr '\n' ',') remaining=$(printf '%s' "$remaining" | tr '\n' ',')"
[ "$status" = pass ]
