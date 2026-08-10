# Termux:X11 UID-matched session-bus result — 2026-08-09

Status: the UID-matched session bus repair worked as a D-Bus transport repair,
but it did not restore Steam login or the native User bridge.

## Run identity and provenance

```text
run_id=termux-x11-20260809T184147Z-network-uid-session-0
repo_commit=12baec8ab4f7f68832f4b08f9ccc0660eeef6ca5
adb_serial=675a2365
device=Retroid Pocket Nova
android_version=13
termux_x11_apk=/tmp/nova-x11-prior-art-20260809/termux-x11-universal-debug.apk
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
x11_client=android/nova-lab/device/nova-termux-x11-steam-client.sh
x11_client_sha256=7f6069a87390ef450a243459d890a607a82a2741f087f610b240bff51a7448d5
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
client_namespace_mode=chroot-dev
bind_android_dev=1
steam_uid=501:20
steam_timeout_seconds=90
dbus_session=1
dbus_session_user=steam
dbus_session_uid_record=1
network_observer_duration_seconds=60
```

The complete run directory is:

```text
android/nova-lab/build/manual-runs/termux-x11-20260809T184147Z-network-uid-session-0/
```

## D-Bus result

The run-scoped rootfs passwd record was added because UID 501 was absent. The
daemon then ran as the same identity as Steam:

```text
client_dbus_session_passwd_record=added uid=501 gid=20
client_dbus_session_status=pass
client_dbus_session_address=unix:path=/tmp/nova-steam-runtime/dbus-session-4223/bus
client_dbus_session_client_probe=pass
dbus-daemon ... session uid=501
dbus_session_dir_cleanup=pass path=/tmp/nova-steam-runtime/dbus-session-4223
dbus_session_passwd_restore=pass
```

The post-run rootfs check found no UID-501 passwd record and no leftover
`dbus-session-*` directory or `passwd.nova-original` backup. The exact Nova
cleanup and Termux:X11 teardown also passed:

```text
termux_x11_post_stop=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_runtime_cleanup=pass
network_observer_status=pass
network_observer_android_samples=16
```

The Steam Runtime Launch Service started under UID 501 and remained present in
the observer process snapshot:

```text
Steam Runtime Launch Service: steam-runtime-launcher-service is running pid 5301
steam-runtime-launcher-service --alongside-steam
```

The previous root-owned-bus error, `Can't find session bus: The connection is
closed`, did not occur in the fresh client stderr. The service exited during
the normal bounded shutdown; it was not observed repeatedly crashing during
startup. A separate GLib system-bus assertion and the expected “systemd is not
PID 1” messages remained.

## Steam/network result

The fresh CDP evaluation still returned:

```json
{
  "title": "Steam Big Picture Mode",
  "body": "6:44 PM\nWaiting for network...",
  "methods": {
    "getStartupUserChooserState": "undefined",
    "startLogin": "undefined",
    "getLoginUsers": "undefined",
    "getCurrentUser": "undefined"
  },
  "startupState": { "unavailable": true }
}
```

The CDP artifact SHA-256 is:

```text
cdp-login-state.json=a461475057797debf3bd40134298a62a1f62149d1445288eab63abfef301f674
```

The fresh client network log still recorded five `NMClient` failures at
`18:43:32`:

```text
operator(): failed to create a NMClient: Could not connect: No such file or directory
Init: failed to create a NetworkManager client
```

Android networking and the native Steam connectivity test remained healthy;
the network observer captured 16 Android samples and the Steam client had
external sockets. The UI throbber and input gates passed, but no QR/login
surface appeared.

## Decision

The session-bus-only hypothesis is closed. The identity repair is useful
harness plumbing and can remain opt-in, but it is not the networking fix. The
remaining local-service evidence is now sharper:

```text
Android data plane                         pass
UID-matched private session bus            pass
Steam Runtime Launch Service startup      improved / no closed-bus crash
NetworkManager client endpoint            absent
SteamClient.User bridge                    absent
Steam login/QR surface                     absent
```

The next experiment should test the available native systemd service boundary
in a run-scoped namespace/configuration, beginning with observation and a
system-bus/resolver contract. It must not let `systemd-networkd` claim or
reconfigure Android's inherited `wlan0` unless that exact behavior is
explicitly bounded and verified.
