#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# This is the repeatable Termux:X11/native Steam profile established by the
# system-D-Bus experiments. Explicit caller values remain overridable so the
# direct/no-bus baseline can still be reproduced intentionally.
export NOVA_TERMUX_X11_DBUS_SESSION=${NOVA_TERMUX_X11_DBUS_SESSION:-1}
export NOVA_TERMUX_X11_DBUS_SESSION_USER=${NOVA_TERMUX_X11_DBUS_SESSION_USER:-steam}
export NOVA_TERMUX_X11_DBUS_SESSION_UID_RECORD=${NOVA_TERMUX_X11_DBUS_SESSION_UID_RECORD:-1}
export NOVA_TERMUX_X11_DBUS_SYSTEM=${NOVA_TERMUX_X11_DBUS_SYSTEM:-1}

exec "$SCRIPT_DIR/deploy-termux-x11-forwarding-smoke-test.sh" "$@"
