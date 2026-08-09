# Termux:X11 UID-matched session-bus experiment — 2026-08-09

Status: predeclared; this change is committed and pushed before the Nova run.

## Hypothesis

The previous root-private D-Bus run created a live socket, but the Steam client
still logged:

```text
Steam Runtime Launch Service: starting steam-runtime-launcher-service
steam-runtime-launcher-service: E: Can't find session bus: The connection is closed
```

The daemon was running as root while Steam and `steamwebhelper` ran as numeric
UID 501. The rootfs has no `/etc/passwd` record for UID 501, which caused the
first user-owned session-bus attempt to fail before launch. A bus socket being
present is therefore not enough evidence that the Steam UID can use it.

This experiment runs the existing session bus as UID 501 and, only when
explicitly enabled, appends a run-scoped `steam` record to the rootfs
`/etc/passwd`. The original file is copied into the run-scoped runtime
directory and restored during client cleanup. No system bus, NetworkManager,
systemd-networkd, resolver, route, NAT, proxy, or UI bundle change is included.

## Exact change

The deploy harness adds:

```text
NOVA_TERMUX_X11_DBUS_SESSION=1
NOVA_TERMUX_X11_DBUS_SESSION_USER=steam
NOVA_TERMUX_X11_DBUS_SESSION_UID_RECORD=1
```

The client will record all of the following:

- whether UID 501 already has a passwd record or received the temporary one;
- the session daemon PID, run-scoped socket, and owner;
- a `dbus-send --session ... ListNames` probe executed through the same UID;
- whether the Steam Runtime Launch Service remains usable;
- exact passwd restoration and Nova process/socket cleanup markers.

## Acceptance gates

The experiment is informative even if Steam still waits for network. The
primary gates are:

```text
session_bus_daemon_owner=501
session_bus_client_probe=pass
Steam Runtime Launch Service does not report a closed session bus
fresh CDP SteamClient.User methods and login body
```

The Termux:X11 display, input, Android-network observer, fresh-log, and
exact-scope cleanup gates remain unchanged. A QR/login result is required to
call the networking phase successful; a spinning throbber alone remains a
display/input pass.

## Decision rules

- If the same-UID bus becomes usable and the User bridge appears, retain this
  reversible identity repair as the leading explanation and test the login
  surface once more before adding any system network daemon.
- If the bus probe passes but the runtime launcher still fails or
  `SteamClient.User` remains undefined, close the session-bus hypothesis and
  investigate the native client/webhelper bridge or system-service contract.
- If the temporary passwd record cannot be restored or exact cleanup fails,
  treat the run as a harness failure and do not interpret its Steam state.
