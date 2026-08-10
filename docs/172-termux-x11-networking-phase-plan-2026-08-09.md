# Termux:X11 networking phase plan — 2026-08-09

Status: the Termux:X11 renderer and physical controller input path are frozen
as the working presentation baseline. This branch investigates the remaining
Steam login boundary: Android-hosted networking and the native Steam-to-webhelper
connection/IPC services that populate the SteamClient bridge.

## Starting point

The merged Termux:X11 track reached the native ARM64 Steam Gamepad UI through
OOBE and selected `Continue with Android host network`. The paired Android
SurfaceView and X11 capture remained live, input focus stayed correct, and the
Steam throbber continued to animate. A 180-second lifetime run and a same-run
read-only CDP probe both stopped at:

```text
Waiting for network...
```

The same client logs recorded successful basic reachability and local UI
transport:

```text
Connectivity test: result=Connected
CWebSocketConnection (steamUI): connection ready
CWebSocketConnection (clientdll): connection ready
WebUITransportStore: Connection status: connected
SetLoginState: WaitingForCredentials - OK
```

The live page nevertheless reported `typeof SteamClient.User.*` as
`undefined` for the startup-user, login, and current-user methods expected by
the shipped login component. The current evidence therefore distinguishes
ordinary network reachability from the missing native Steam auth/user bridge;
it does not yet justify changing Gamescope, AHardwareBuffer, or SurfaceFlinger.

## Frozen presentation baseline

Every networking experiment keeps these variables unchanged unless an
experiment explicitly names a UI-mode comparison:

```text
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
controller=physical device confirmed working in the live Steam session
client_namespace_mode=chroot-dev
bind_android_dev=1
bind_android_proc=1
tmpfs_dev_shm=1
steam_uid=501:20
MESA_LOADER_DRIVER_OVERRIDE=swrast
GALLIUM_DRIVER=softpipe
LIBGL_ALWAYS_SOFTWARE=1
LD_PRELOAD=/opt/nova-kgsl-driver/libsysv-sem-shim.so
steam_flags=-gamepadui -steamos3 -steampal -steamdeck -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox -cef-disable-gpu
```

The exact APK, rootfs, Steam launcher, X11 helpers, flags, hashes, and run
identity remain part of every device report. The existing Nova cleanup and
fresh-log/readiness contract remains mandatory.

## Experiment order

### 1. Network and bridge inventory

Add observation only. In one fresh direct Steam session, correlate:

- Android `dumpsys connectivity`, interface addresses, routes, DNS, and
  validated-network state;
- the chroot's `/etc/resolv.conf`, NSS configuration, route table, resolver
  lookups, and HTTPS requests;
- the Steam/client/webhelper process tree, command lines, namespaces, open
  sockets, listening ports, Unix sockets, and `/proc/<pid>/net` views;
- the presence, path, permissions, and ownership of DBus/NetworkManager
  sockets and any SteamOS service endpoints expected by the native client;
- fresh Steam logs around connectivity, WebSocket readiness, login state, and
  missing optional APIs.

This run must not patch the Steam UI bundle or synthesize a `SteamClient.User`
method. Its acceptance result is a provenance table identifying which
transport boundaries are demonstrably alive and which are absent or
unobservable.

### 2. Android-host network versus explicit Linux service boundary

If experiment 1 identifies a missing local service rather than a route/DNS
failure, test one service boundary at a time. Candidate boundaries are the
Android-host network path already selected by OOBE, a private/local DNS or
resolver setup, DBus, and the SteamOS/NetworkManager service contract. The
change must be explicit and reversible, with a fresh run and the same
presentation baseline.

Do not infer that a successful TCP connectivity probe proves the Steam login
bridge is complete: retain the CDP/API and Steam-log gates.

### 3. Desktop Steam control comparison

Only if the Gamepad UI contract itself prevents useful bridge diagnosis, run a
separately named desktop-mode comparison using the closest upstream/native
Steam flags. GameNative/Winlator prior art makes this a useful fallback
question, but it is not interchangeable with the Gamepad UI result and must
not be used to claim that the original network path is fixed.

### 4. QR/login acceptance

The phase succeeds only when a fresh run reaches a real Steam login surface,
renders the QR-code view or equivalent login controls on the Android
SurfaceView, and records the live Steam UI/API state plus paired X11/Android
visual evidence. A spinning throbber is a display/input pass, not a login pass.

## Guardrails

- Read `docs/34-nova-runtime-harness-lifecycle.md` immediately before every
  Nova device run.
- Predeclare each experiment, commit it, and push it before the device run.
- Treat every run as a new identity; do not reuse Steam processes, logs,
  sockets, forwards, screenshots, or readiness lines.
- Run exact-scope cleanup before launch and on every exit, then verify no
  matching process, temporary mount, bridge socket, or ADB forward remains.
- Document the result, commit it, and push it before starting the next
  hypothesis.
- Keep Gamescope-to-AHardwareBuffer work out of this branch unless new
  evidence independently reopens that boundary.

## Immediate next step

Implement the smallest run-scoped inventory observer needed for experiment 1,
predeclare its exact output and acceptance gates, push that documentation and
observer, then run it against the attached Nova device. The first decision
afterward is whether the blocker is Android/chroot network transport, a missing
Steam local service/IPC contract, or a Steam UI bridge that is unavailable in
this ARM64 client mode for another reason.
