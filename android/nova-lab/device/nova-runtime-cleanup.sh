#!/system/bin/sh

set -u

ROOT="${1:-/data/local/tmp/nova-holo-rootfs}"
SELF_PID=$$

runtime_pids() {
    /system/bin/ps -A -o PID,PPID,ARGS 2>/dev/null | \
        /system/bin/awk -v root="$ROOT" -v self="$SELF_PID" '
            NR == 1 { next }
            {
                pid = $1
                args = $0
                if (pid == "" || pid == self) {
                    next
                }
                if (index(args, "awk") || index(args, "nova-runtime-cleanup")) {
                    next
                }
                if (index(args, root "/opt/nova-steam") ||
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
        /system/bin/awk -v parents="$parents" -v self="$SELF_PID" '
            BEGIN {
                count = split(parents, values, /[[:space:]]+/)
                for (slot = 1; slot <= count; slot++) {
                    if (values[slot] != "") {
                        wanted[values[slot]] = 1
                    }
                }
            }
            NR == 1 { next }
            {
                pid = $1
                parent = $2
                if (pid == "" || pid == self) {
                    next
                }
                if (index($0, "awk") || index($0, "nova-runtime-cleanup")) {
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
    /system/bin/sleep 1
    current_kill=$(kill_runtime KILL)
    if [ -n "$kill_pids" ] && [ -n "$current_kill" ]; then
        kill_pids="$kill_pids
$current_kill"
    elif [ -n "$current_kill" ]; then
        kill_pids=$current_kill
    fi
    /system/bin/sleep 1
    remaining=$(all_runtime_pids)
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
