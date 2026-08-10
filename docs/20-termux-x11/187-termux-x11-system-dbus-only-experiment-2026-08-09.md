# Termux:X11 system-D-Bus-only experiment — 2026-08-09

Status: predeclared; this change is committed and pushed before the Nova run.

## Hypothesis

The UID-matched session bus fixed the Steam Runtime Launch Service's closed
session-bus failure but left the login state unchanged. The fresh Steam logs
also showed two independent system-service signals:

```text
Initialized CSteamUINetworkController: 0
Failed to connect to the bus: Failed to connect to socket /run/dbus/system_bus_socket: No such file or directory
```

This experiment supplies the rootfs's existing `dbus-daemon` system bus at its
standard path, while retaining the successful UID-matched session bus. It does
not start NetworkManager, `systemd-networkd`, `systemd-resolved`, or any
network configuration service. The purpose is to separate “no system bus” from
“missing NetworkManager/system service” without changing Android routing or
DNS.

## Exact change

The client gets an explicit opt-in:

```text
NOVA_TERMUX_X11_DBUS_SYSTEM=1
```

For one run it starts the shipped `/usr/bin/dbus-daemon` with
`/usr/share/dbus-1/system.conf` and `--nofork`, records the standard
`/run/dbus/system_bus_socket`, probes `org.freedesktop.DBus.ListNames` as UID
501, and removes only the socket, pid file, and run-created `/run/dbus`
directory on exit. The session bus remains UID-matched with the temporary
passwd record from the preceding experiment.

## Acceptance gates

Record all of these independently:

- system bus daemon and socket reachability;
- UID-501 system-bus `dbus-send` probe;
- `CSteamUINetworkController` initialization state;
- fresh `steamwebhelper` system-bus connection errors;
- fresh `NMClient` errors and `SteamClient.User` CDP methods;
- Android/X11 display/input/network observer status; and
- exact cleanup of both buses, passwd record, runtime processes, and sockets.

Starting the bus alone is not a networking success. The target milestone
remains a real Steam login/QR surface with the UI bridge present.

## Decision rules

- If the system bus removes the webhelper bus errors and the User bridge/login
  state appears, keep the bus as a required runtime dependency and identify the
  minimum additional service it needs.
- If the webhelper errors disappear but `NMClient` and `SteamClient.User`
  remain absent, the system bus is necessary but not sufficient; the next
  experiment should address the native service behind the NetworkManager or
  Steam User contract.
- If the daemon cannot start or cleanup is incomplete, treat this as a
  harness/system-bus compatibility failure and do not interpret UI state.
