# Termux:X11 two-bus interactive QR login session — 2026-08-09

Status: predeclared and pushed before launch. This is an explicitly
long-lived manual session for operator QR scanning, not a bounded acceptance
run. The session uses the proven system-D-Bus plus UID-matched private
session-D-Bus profile and remains available until the operator logs in or the
session is stopped.

## Run identity

```text
run_id=termux-x11-20260809T190803Z-qr-login-interactive-0
adb_serial=675a2365
device=Retroid Pocket Nova
android_version=13
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
steam_timeout_seconds=86400
input_mode=android-keyevent-sequence
input_keycodes=66,66,66
input_after_delay_seconds=8
network_observer=1
network_observer_duration_seconds=300
network_observer_interval_seconds=10
```

The APK, X11 client, mount helper, cleanup helper, and rootfs are recorded by
the harness in the run metadata with exact paths and SHA-256 values. The run
directory is:

```text
android/nova-lab/build/manual-runs/termux-x11-20260809T190803Z-qr-login-interactive-0/
```

## Purpose and fixed boundary

The two successful system-bus runs reached a live QR page, while the
system-bus-only control remained at `Waiting for network...`. This session
keeps the successful bus configuration fixed and asks the operator to scan the
QR code with Steam Mobile. It does not reopen the Gamescope/AHardwareBuffer
presentation path, alter the Android route, add NAT/proxying, or attempt to
automate credentials or QR approval.

## Acceptance gates

Record separately:

1. fresh exact-scope Nova and Termux:X11 cleanup before launch;
2. fresh Android and X11 captures tied to this run ID;
3. fresh CDP evidence whose body contains the Steam QR login instruction;
4. the system/session bus and Steam CM network evidence;
5. the operator's post-scan state, if login succeeds; and
6. exact cleanup after the operator stops the session, including no ADB CDP
   forward, rootfs Steam process, Termux:X11 process, or temporary socket.

The QR page is a display/login-surface milestone. A successful scan and
authenticated Steam landing state will be recorded as a separate result after
the operator interaction.
