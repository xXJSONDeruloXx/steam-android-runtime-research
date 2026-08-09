# Termux:X11 network and Steam bridge inventory experiment — 2026-08-09

Status: predeclared; this is the first device experiment on
`feat/termux-x11-networking`. It is observation-only.

## Question

Does the current direct Termux:X11 session fail because Android networking is
not actually available inside the `chroot-dev` Steam process, or because the
native Steam client is missing a local service/IPC boundary that is separate
from ordinary TCP reachability?

The preceding run already recorded all of the following in the same Steam
session:

```text
Connectivity test: result=Connected
CWebSocketConnection (steamUI): connection ready
CWebSocketConnection (clientdll): connection ready
WebUITransportStore: Connection status: connected
SteamClient.User.GetStartupUserChooserState = undefined
SteamClient.User.StartLogin = undefined
SteamClient.User.GetLoginUsers = undefined
SteamClient.User.GetCurrentUser = undefined
```

This experiment will not treat the first four lines as proof that the login
bridge is complete, and it will not treat the last four lines as proof of a
route failure.

## Fixed profile

Use the same direct native ARM64 Steam profile as the accepted X11 login-probe
baseline:

```text
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
client_namespace_mode=chroot-dev
bind_android_dev=1
tmpfs_dev_shm=1
bind_android_proc=1
steam_uid=501:20
steam_flags=-gamepadui -steamos3 -steampal -steamdeck -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox -cef-disable-gpu
input=KEYCODE_ENTER,KEYCODE_ENTER,KEYCODE_ENTER
```

The diagnostic observer runs for 45 seconds at a five-second interval. The
client lifetime is 75 seconds for this run so the observer covers startup,
the OOBE network selection, and the resulting login-wait state without
changing the renderer or waiting indefinitely.

The mandatory [Nova runtime harness lifecycle](34-nova-runtime-harness-lifecycle.md)
must be read immediately before launch. The run uses a fresh run ID and the
usual exact-scope preflight and teardown checks.

## Evidence collected

The host observer records timestamped Android snapshots containing:

- `dumpsys connectivity` and validated-network state;
- Android interface addresses, routes, DNS properties, and `/proc/net` tables;
- Android process state; and
- Android DNS/netd socket endpoints.

The device-side observer runs inside the same `chroot-dev` namespace as the
Steam session and records timestamped samples containing:

- rootfs resolver/NSS files, interface/routes, and `/proc/net` tables;
- `getent` lookups and bounded HTTPS HEAD requests to Steam endpoints;
- TCP and Unix socket listings when `ss` or `netstat` exists;
- DBus, NetworkManager, resolver, and related local endpoint presence;
- Steam/client/webhelper process command lines, namespaces, per-process
  network views, relevant file descriptors; and
- tails of the Steam bootstrap, connection, UI, webhelper, and network-manager
  logs when present.

The observer does not create an ADB forward, alter DNS, start DBus, start
NetworkManager, patch Steam files, call SteamClient methods, or inject input.

## Acceptance gates

Require all of the following for a usable inventory result:

1. fresh Termux:X11 window and paired Android/X11 capture gates pass;
2. the three Enter events retain the same focused X11 window and reach the
   network-selection/login-wait state;
3. at least one Android and one chroot observer sample are timestamped while
   Steam is alive;
4. exact-scope cleanup passes and the observer script leaves no remote file or
   process; and
5. the report preserves command status and absence versus failure for missing
   tools/endpoints rather than collapsing them into a generic “network good”.

The result must classify the next boundary as one of:

- Android route/DNS not available in the chroot;
- route/DNS available but Steam’s required local service/IPC endpoint absent;
- transport and local services observable, with the missing `SteamClient.User`
  bridge still unexplained; or
- an observer/harness failure requiring a clean rerun before interpretation.

## Implementation boundary

The observer is opt-in through
`NOVA_TERMUX_X11_NETWORK_OBSERVER=1`. It is staged with a run-specific remote
path and removed on completion. No default Termux:X11 experiment changes its
behavior, and no Gamescope/AHardwareBuffer code is involved.
