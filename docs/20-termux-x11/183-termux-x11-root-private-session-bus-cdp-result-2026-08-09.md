# Termux:X11 root-private session-bus CDP result — 2026-08-09

Status: the live CDP probe confirms that a reachable private session bus does
not restore the Steam login/User bridge.

## Run identity and provenance

```text
run_id=termux-x11-20260809T183228Z-network-root-session-bus-cdp-1
repo_commit=ecd0a25709217f281e1d27f74076bd1cde8946f0
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
network_observer_duration_seconds=45
network_observer_interval_seconds=5
cdp_probe=android/nova-lab/probe-termux-x11-steam-cdp.sh
```

The complete run directory is:

```text
android/nova-lab/build/manual-runs/termux-x11-20260809T183228Z-network-root-session-bus-cdp-1/
```

## Direct login-bridge result

The fresh CDP probe passed against the Steam Big Picture page and evaluated
the read-only expression without invoking any login method. The exact result
was:

```json
{
  "title": "Steam Big Picture Mode",
  "href_prefix": "https://steamloopback.host/index.html",
  "body": "6:32 PM\nWaiting for network...",
  "methods": {
    "getStartupUserChooserState": "undefined",
    "startLogin": "undefined",
    "getLoginUsers": "undefined",
    "getCurrentUser": "undefined"
  },
  "startupState": { "unavailable": true }
}
```

The complete JSON artifact is:

```text
cdp-login-state.json
sha256=80e04d9cc35e890d1ebc7b97d0dc344fbf4af167c5056f5401fba6922db62d9b
```

The read-only ADB forward was cleaned up; the probe reported
`cdp_probe_status=pass`. Its other primary hashes are:

```text
cdp-targets.json=a95efbe6e2094e900447a4f98f2ad9f5a992c8f1e910b5fed193bc45f320c4fa
adb-cdp-forward.txt=f3391274ff6230706cde3bf74411dd636ad84979ef62113073934b359f86ffda
cdp-probe-status.txt=b3b8b5c5f1f7af731a46023334ae9ce1d05b434aaf5698f2369af2b1c8fc3d14
```

No QR code or login controls appeared.

## Control and network gates

The root-private D-Bus socket started with
`client_dbus_session_status=pass`; the observer saw its run-scoped path and
the Steam process tree. The full Termux:X11 display/input path also passed:

```text
x11_window=0x2400035
network_observer_status=pass
network_observer_android_samples=13
input_sequence=pass events=3
termux_x11_post_stop=pass
nova_runtime_cleanup=pass
```

The final paired captures remained live but showed the same waiting state:

```text
android-screenshot-step-03-after-input.png
sha256=d609c098e6a8ddb4fd626353d2ebce5dac5b3f36233e2109dad63b997716db3a
x11-window-step-03-after-input.ppm
sha256=293a0d6cd8206e16b36aa4c80e1391fcb32d0acd85b1638ee41cc0875c98152d
```

The network observer continued to show inherited Android DNS/HTTPS and
external Steam/webhelper sockets, while `/run/dbus/system_bus_socket`,
`/run/NetworkManager/private`, and the `NetworkManager` binary remained
absent. The root-private session bus did not change that system-service
boundary.

## Decision

This closes the session-bus hypothesis:

```text
Android/chroot data transport = pass
Steam/webhelper external sockets = pass
private D-Bus session socket = pass
SteamClient.User bridge = still absent
Steam login/QR surface = not reached
```

The blocker is now more specifically the native Steam-to-webhelper/User
bridge or a required system service behind it, not ordinary Android network
passthrough and not a missing session socket alone. The next experiment must
inventory the available system-bus/NetworkManager libraries, service files,
and Steam runtime bridge processes before attempting a minimal system-service
implementation. No fake NetworkManager, route/NAT/proxy, UI patch, or
Gamescope/AHB change is justified yet.
