# Termux:X11 system-bus-only result — 2026-08-09

Status: regression. Keeping the system D-Bus while removing the private
UID-matched session bus did not reach the QR login surface. The Android data
plane still connected to Steam, so this isolates the remaining failure to the
Steam runtime's D-Bus/session-service integration rather than Android route,
DNS, or TCP passthrough.

## Run identity and provenance

```text
run_id=termux-x11-20260809T185935Z-network-system-only-0
repo_commit=efa2e303e047b8eecd6c665d5cd43bc8a41e18b9
adb_serial=675a2365
device=Retroid Pocket Nova
android_version=13
termux_x11_apk=/tmp/nova-x11-prior-art-20260809/termux-x11-universal-debug.apk
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
x11_client=android/nova-lab/device/nova-termux-x11-steam-client.sh
x11_client_sha256=a5d032caeda8c34f0384201c14f9dd91fc4394beaad2cfdcaf6d80246143299c
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
client_namespace_mode=chroot-dev
bind_android_dev=1
steam_uid=501:20
steam_timeout_seconds=90
dbus_session=0
dbus_session_user=steam
dbus_session_uid_record=0
dbus_system=1
network_observer_duration_seconds=60
network_observer_samples=16
```

The complete run directory is:

```text
android/nova-lab/build/manual-runs/termux-x11-20260809T185935Z-network-system-only-0/
```

Compared with the successful runs in [docs/188](188-termux-x11-system-dbus-only-result-2026-08-09.md)
and [docs/190](190-termux-x11-system-dbus-repeat-result-2026-08-09.md), this
run changed only the session-bus settings from enabled to disabled.

## Result

The system bus started at `/run/dbus/system_bus_socket`, and the launcher
recorded `client_dbus_system_status=pass`. The direct UID-501 system-bus
`ListNames` probe still timed out, matching the earlier runs' policy/helper
limitation. With no session bus, however, the Steam Runtime Launch Service
repeatedly failed its `dbus-launch --autolaunch` attempt and was disabled:

```text
Steam Runtime Launch Service: steam-runtime-launcher-service is running
Error: failed to connect to object manager: Error spawning command line “dbus-launch --autolaunch=...”: Child process exited with code 1
Steam Runtime Launch Service: steam-runtime-launcher-service keeps crashing on startup, disabling
```

The fresh Steam network log consequently returned:

```text
operator(): failed to create a NMClient: The connection is closed
Init: failed to create a NetworkManager client
```

This did not mean that Android connectivity was absent. The observer still
captured Steam CM WebSocket connections using the Android address
`192.168.0.23`, including a fresh connection to `162.254.192.98:443`, and the
Steam connectivity test reported `result=Connected`. The rootfs still has no
NetworkManager daemon or private NetworkManager socket; the important change
was the missing session-bus service lifecycle.

## Login acceptance

Fresh CDP returned:

```text
title=Steam Big Picture Mode
body=7:00 PM / Waiting for network...
SteamClient.User methods=undefined
```

The paired artifact hashes are:

```text
cdp-login-state.json=497b128897375269d45e881f0ca3f878e429aa4691a3917ab023a9f1e39dee2d
steam-client.log=a2ee7842391ebfb248309330771bbab4e30a32e74cace1aadcbc715c0c3e7f6f
steam-client.stderr=cdd9dc6bdd42c33a70532e5eaa559a6565ab61f443109aa23ca8a3c1a04be709
android-screenshot-step-03-after-input.png=9e1204fb51da2f46a72eed85c1187763df71dcaf1c2eb27e69d9a6c3125b3e2e
x11-window-step-03-after-input.ppm=9cb54e6e18c6266425c8986cd360d07e7e4ad512dfc8dd4163d5d502a426acda
```

## Cleanup

```text
dbus_system_cleanup=pass socket=/run/dbus/system_bus_socket
termux_x11_post_stop=pass
server_state=absent client_state=absent server_parent_state=absent socket_state=absent
nova_runtime_cleanup=pass
network_observer_status=pass
network_observer_android_samples=16
```

## Decision

System D-Bus alone is rejected as the simplified profile. The named
[`run-termux-x11-system-bus-profile.sh`](../android/nova-lab/run-termux-x11-system-bus-profile.sh)
must retain both the system bus and the private UID-matched session bus. The
two-bus configuration reached a live QR login page in two fresh runs; this
control run reached only `Waiting for network...` despite successful external
Steam sockets.

The next acceptance step is user interaction with the already-proven QR
surface: scan the QR code with Steam Mobile in a fresh named run and capture
the authenticated transition. Reopening Gamescope/AHardwareBuffer work is not
needed for that step.
