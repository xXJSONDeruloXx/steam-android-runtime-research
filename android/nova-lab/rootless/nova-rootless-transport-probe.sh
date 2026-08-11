#!/system/bin/sh

# Read-only rootless transport probe. It never launches app_process, su, a
# mount helper, or a second Steam client. It reports whether a rootless X11
# socket is actually reachable by the current Android UID.

set -eu

X11_PACKAGE="${NOVA_ROOTLESS_X11_PACKAGE:-com.termux.x11}"
TERMUX_PACKAGE="${NOVA_ROOTLESS_TERMUX_PACKAGE:-com.termux}"
SOCKET="${NOVA_ROOTLESS_X11_SOCKET:-}"
TCP_HOST="${NOVA_ROOTLESS_X11_HOST:-}"
TCP_PORT="${NOVA_ROOTLESS_X11_PORT:-}"

id_bin=/system/bin/id
pm_bin=/system/bin/pm
toybox_bin=/system/bin/toybox
test_bin=/system/bin/test

fail() {
    echo "nova_rootless_transport=fail reason=$1"
    exit 1
}

reject_rooted_socket() {
    candidate="$1"
    case "$candidate" in
        /data/local/tmp/nova-runtimes/*|/data/local/tmp/nova-holo-rootfs/*)
            fail rooted_runtime_socket_not_rootless
            ;;
    esac
}

has_package() {
    package="$1"
    if "$pm_bin" path "$package" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

if [ "$($id_bin -u)" -eq 0 ]; then
    fail root_uid_detected
fi
if ! has_package "$X11_PACKAGE"; then
    fail missing_termux_x11
fi

termux_present=0
if has_package "$TERMUX_PACKAGE"; then
    termux_present=1
fi

if [ -n "$TCP_HOST" ] || [ -n "$TCP_PORT" ]; then
    [ "$termux_present" -eq 1 ] || fail missing_termux_base
    [ "$TCP_HOST" = 127.0.0.1 ] || fail tcp_host_must_be_loopback
    case "$TCP_PORT" in
        ''|*[!0-9]*) fail invalid_tcp_port ;;
    esac
    if [ "$TCP_PORT" -lt 1024 ] || [ "$TCP_PORT" -gt 65535 ]; then
        fail tcp_port_out_of_range
    fi
    if ! "$toybox_bin" nc -w 1 "$TCP_HOST" "$TCP_PORT" \
        </dev/null >/dev/null 2>&1; then
        fail tcp_endpoint_unreachable
    fi
    echo "nova_rootless_transport=pass uid=$($id_bin -u) x11_package=$X11_PACKAGE termux_base=$termux_present transport=loopback-tcp host=$TCP_HOST port=$TCP_PORT"
    echo "nova_rootless_transport_network=android-inherited-namespace"
    echo "nova_rootless_transport_audio=unverified"
    echo "nova_rootless_transport_input=unverified"
    exit 0
fi

if [ -z "$SOCKET" ]; then
    # Only accept explicitly shared or app-owned locations. In particular,
    # never treat the rooted Nova runtime's socket as rootless evidence.
    for candidate in \
        "${NOVA_ROOTLESS_SHARED_X11_SOCKET:-}" \
        "/data/local/tmp/nova-rootless-x11/.X11-unix/X0" \
        "/data/user/0/$X11_PACKAGE/files/usr/tmp/.X11-unix/X0" \
        "/data/data/$X11_PACKAGE/files/usr/tmp/.X11-unix/X0"; do
        [ -n "$candidate" ] || continue
        case "$candidate" in
            /data/local/tmp/nova-runtimes/*|/data/local/tmp/nova-holo-rootfs/*)
                continue
                ;;
        esac
        if "$test_bin" -S "$candidate" && "$test_bin" -r "$candidate"; then
            SOCKET="$candidate"
            break
        fi
    done
fi

if [ -z "$SOCKET" ]; then
    if [ "$termux_present" -eq 1 ]; then
        fail no_rootless_readable_x11_socket
    fi
    fail missing_termux_base_and_shared_x11_socket
fi
reject_rooted_socket "$SOCKET"
if ! "$test_bin" -S "$SOCKET"; then
    fail x11_socket_not_socket
fi
if ! "$test_bin" -r "$SOCKET"; then
    fail x11_socket_not_readable
fi

echo "nova_rootless_transport=pass uid=$($id_bin -u) x11_package=$X11_PACKAGE termux_base=$termux_present socket=$SOCKET"
echo "nova_rootless_transport_network=android-inherited-namespace"
echo "nova_rootless_transport_audio=unverified"
echo "nova_rootless_transport_input=unverified"
