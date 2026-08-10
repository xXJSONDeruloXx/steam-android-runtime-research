# Termux:X11 system-bus-only dependency isolation experiment — 2026-08-09

Status: predeclared on `feat/termux-x11-networking-followup`; committed and
pushed before the Nova run.

## Purpose

The two-bus profile reached the QR login surface twice. The private session
bus repair also fixed the Steam Runtime Launch Service's identity/connection
failure, but it is not yet proven necessary for the login page once the
standard system bus is present. This experiment keeps the successful system
bus and removes only the private session bus.

## Fixed and changed variables

```text
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
client_namespace_mode=chroot-dev
bind_android_dev=1
steam_uid=501:20
dbus_system=1
dbus_session=0
dbus_session_uid_record=0
```

Compared with docs/188 and docs/190, only `dbus_session` changes from `1` to
`0`. Android routing/DNS, Steam flags, APK, X11 helpers, input sequence,
observer, and cleanup remain fixed.

## Acceptance gates

Record independently:

- system-bus startup and UID-501 access behavior;
- whether the Steam Runtime Launch Service starts or reports a missing session
  bus;
- `CSteamUINetworkController` and NetworkManager-client state;
- external Steam CM connectivity;
- fresh CDP login body and QR page; and
- paired Android/X11 capture plus exact cleanup.

If the QR surface remains present, the follow-up profile can simplify to the
system bus only. If it regresses to `Waiting for network...`, retain both
buses in the named profile and document the session bus as a supporting
runtime dependency.
