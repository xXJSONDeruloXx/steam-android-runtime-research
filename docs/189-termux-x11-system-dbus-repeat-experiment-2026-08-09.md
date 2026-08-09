# Termux:X11 system-D-Bus repeatability experiment — 2026-08-09

Status: predeclared; this repeat is committed and pushed before the device
run.

## Purpose

The preceding fresh run reached the real Steam sign-in page with a visible QR
code after adding only the rootfs standard system D-Bus, while retaining the
UID-matched session bus. This run repeats that exact profile with a new run
identity and no code or environment change. It is intended to distinguish a
repeatable system-bus unblocker from a one-off cached or stale UI state.

## Fixed profile

```text
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
client_namespace_mode=chroot-dev
bind_android_dev=1
steam_uid=501:20
dbus_session=1
dbus_session_user=steam
dbus_session_uid_record=1
dbus_system=1
```

The APK, X11 client/capture helpers, Steam flags, input sequence, observer
duration, and cleanup contract remain the same as the preceding result. Only
the run ID and fresh process/log/artifact set change.

## Acceptance gates

The repeat passes only if a fresh run records:

- system and session bus startup/cleanup markers;
- `CSteamUINetworkController: 1` and successful NetworkManager-client
  initialization;
- external Steam CM connectivity;
- a fresh CDP body containing the sign-in/QR surface; and
- a paired Android/X11 capture at the controlled input step visibly showing
  the QR code, with exact Nova and ADB-forward cleanup.

If the repeat falls back to `Waiting for network...`, preserve the complete
evidence and treat the result as nondeterministic rather than changing another
variable in the same run.
