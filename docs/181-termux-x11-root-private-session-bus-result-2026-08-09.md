# Termux:X11 root-private session-bus result — 2026-08-09

Status: the private D-Bus socket started and was observed, but it did not
advance Steam login. The session-bus probe is therefore not a sufficient
networking fix.

## Run identity and provenance

```text
run_id=termux-x11-20260809T182402Z-network-root-session-bus-0
repo_commit=dd4ce05d8801086a34a47c27cf17bc6ce173dfbb
adb_serial=675a2365
device=Retroid Pocket Nova
android_version=13
termux_x11_apk=/tmp/nova-x11-prior-art-20260809/termux-x11-universal-debug.apk
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
source_tree=/Users/kurt/Developer/steam-android-runtime-research
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
client_namespace_mode=chroot-dev
bind_android_dev=1
x11_client=android/nova-lab/device/nova-termux-x11-steam-client.sh
x11_client_sha256=4321ae21cdd9ae15c8561b93e27c6a6daeaef0f09fd36b7f7008dd3467e7829e
x11_capture=android/nova-lab/build/nova-x11-capture
x11_capture_sha256=a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206ae3efb4b017
dbus_session=1
dbus_session_user=root
steam_uid=501:20
steam_timeout_seconds=75
input_mode=android-keyevent-sequence
input_keycodes=66,66,66
network_observer_duration_seconds=45
network_observer_interval_seconds=5
```

The complete run directory is:

```text
android/nova-lab/build/manual-runs/termux-x11-20260809T182402Z-network-root-session-bus-0/
```

## Session-bus gate

The private bus started and remained observable while Steam was alive:

```text
client_dbus_session_status=pass
client_dbus_session_user=root
client_dbus_session_address=unix:path=/tmp/nova-steam-runtime/dbus-session-25720/bus
private_session_bus_path=/tmp/nova-steam-runtime/dbus-session-25720
dbus-daemon=/usr/bin/dbus-daemon pid=26544 uid=0
```

The daemon emitted a non-fatal but important warning because the existing
`XDG_RUNTIME_DIR` belongs to Steam UID 501 while this compatibility bus runs
as root:

```text
Unable to set up transient service directory: XDG_RUNTIME_DIR "/tmp/nova-steam-runtime" is owned by uid 501, not our uid 0
```

The private socket itself was present and world-accessible inside the run's
mount namespace. This proves that a D-Bus endpoint can be staged, but it does
not prove that Steam's expected user/session service contract is satisfied.

## Display and network gates

The direct presentation path remained healthy:

```text
x11_window=0x2400035
network_observer_remote_status=0
network_observer_android_samples=13
network_observer_status=pass
```

All three Enter events passed focus, Android capture-change, and X11
capture-change checks. The final paired artifacts were:

```text
android-screenshot-step-03-after-input.png
sha256=b9e159c84eb17fd1898697aab14715bb303c3d7166056c6d998842d1dcffa565
x11-window-step-03-after-input.ppm
sha256=9310361a82b57c67c4e7c722c4c7b829cc99d6b988fcf5f107dbb5e0e61a5bc3
```

The Android image still showed the animated Steam logo and
`Waiting for network...`; no QR code or login controls appeared.

The observer repeated the data-plane result from the inventory baseline:

```text
Android validated Wi-Fi/DNS state = present
chroot getent and HTTPS HEAD checks = pass
Steam/webhelper external sockets = present
NetworkManager binary = absent
/run/dbus/system_bus_socket = absent
/run/NetworkManager/private = absent
```

The current Steam log recorded successful connectivity immediately beside the
local-service failures:

```text
Connectivity test (23.215.0.9:80): OK!
Connectivity test: result=Connected
operator(): failed to create a NMClient: Could not connect: No such file or directory
Init: failed to create a NetworkManager client
Steam Runtime Launch Service: starting steam-runtime-launcher-service
Error: failed to connect to object manager: The connection is closed
steam-runtime-launcher-service keeps crashing on startup, disabling
```

Steam stderr likewise reported that the runtime launch service could not find
or keep a session bus, and that the system-scope bus was unavailable. The
root-private socket therefore did not supply the broader SteamOS service
contract that this client expects.

## Interpretation

This run changes the service-boundary table to:

```text
Android/chroot data transport = pass
DNS and HTTPS from Steam namespace = pass
Steam/webhelper external sockets = pass
Private D-Bus socket creation = pass
Steam runtime/session service integration = not satisfied
System D-Bus and NetworkManager contract = absent
Steam login/QR surface = not reached
```

The result is not evidence that Android passthrough is broken. It is evidence
against spending more time on a session bus alone. The next networking work
should identify the native Steam-to-webhelper/User bridge and the system-bus
service contract separately. A root-owned private bus is not a final
architecture and should not be retained as a default workaround.

## Cleanup

The exact-scope teardown passed, including the private bus process and runtime
directory cleanup:

```text
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_runtime_cleanup=pass
dbus_session_cleanup=pass
```
