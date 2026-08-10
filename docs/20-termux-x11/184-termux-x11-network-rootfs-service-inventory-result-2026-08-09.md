# Termux:X11 rootfs network-service inventory result — 2026-08-09

Status: Android data transport remains healthy, but the rootfs does not contain
NetworkManager. It does contain the systemd network and resolver daemons, so a
system-service experiment is possible; it must be isolated and explicitly
bounded rather than inferred from the presence of D-Bus service descriptors.

## Inventory identity

```text
inventory_time=2026-08-09T18:39:39Z
adb_serial=675a2365
device=Retroid Pocket Nova
android_version=13
device_root=/data/local/tmp/nova-holo-rootfs
presentation_baseline=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
```

The first path-specific check looked only under `usr/bin` and therefore missed
the systemd-installed daemons. The corrected read-only inventory searched the
whole rootfs and recorded the following.

## Available and absent components

```text
/usr/bin/NetworkManager                         absent
/usr/sbin/NetworkManager                        absent
/usr/bin/nmcli                                  absent
/usr/lib/systemd/systemd-networkd               present
/usr/lib/systemd/systemd-resolved               present
/usr/bin/networkctl                             present
/usr/bin/resolvectl                             present
/usr/bin/dbus-daemon                            present
/usr/lib/dbus-daemon-launch-helper              present
/usr/bin/systemctl                              present
```

The available ARM64 rootfs artifacts have these SHA-256 values:

```text
systemd-networkd=28c76114fbb676229aa018a19b13e77d5a3d303f35527155a82429febc421e65
systemd-resolved=7c298f8f96fec0ebc91008b6e660e3ad47fe883ae10828dc57e43eaa4b5ef83e
networkctl=f98ba46cd82ea88e11728042e1408a43396ab6dee184825ce601357a5bf9b48d
resolvectl=8a4b6cf34f0c54aa9656508761c46483615194c4bd16a90e60e8601dd158d88a
dbus-daemon=bb1615945033771602d9a41c9363edee14cff50aaba0786963acd0e506ee9a6e
```

`libnm.so.0.1.0` exists only inside the Steam Runtime ARM64/x86 runtime
trees; no matching NetworkManager executable or `nmcli` client exists in the
rootfs. The rootfs has `/usr/share/dbus-1/system-services` entries for
`org.freedesktop.network1` and `org.freedesktop.resolve1`, but both declare
`Exec=/bin/false` and rely on `SystemdService=` activation. They are not
standalone service implementations.

The shipped system D-Bus configuration expects a `dbus` user, a system bus at
`/run/dbus/system_bus_socket`, and systemd activation. The rootfs has no
running system bus in the Termux:X11 launch namespace, and its `/etc/passwd`
has no entry for the Steam UID used by the launcher (`501`).

## Interpretation

The inventory does not justify adding a fake NetworkManager, changing Android
routes/NAT, or replacing `/etc/resolv.conf`. It does justify one narrowly
scoped next test: make the existing private session bus run as the same
numeric Steam identity, using a run-scoped UID record if D-Bus requires it,
and check whether the Steam Runtime Launch Service can retain its bus
connection. This is a control-plane repair experiment, not a claim that
systemd-networkd should manage Android's `wlan0`.

The systemd network/resolver daemons remain candidates only after that test.
Starting either daemon without a dedicated configuration and a system-bus
contract could alter or claim the inherited Android network namespace, so it
is not part of this inventory run.
