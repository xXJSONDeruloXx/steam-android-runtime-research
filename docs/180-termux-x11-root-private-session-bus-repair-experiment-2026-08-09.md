# Termux:X11 root-private session-bus repair experiment — 2026-08-09

Status: predeclared; not run yet.

## Why this is a separate experiment

The first private session-bus attempt was stopped before Steam startup because
the Nova rootfs has no passwd entry for UID 501 and its stale
`$XDG_RUNTIME_DIR/dbus-1` directory was owned by root. D-Bus therefore never
created its bus socket. That result was documented in
`docs/179-termux-x11-network-session-bus-startup-failure-result-2026-08-09.md`
and did not test Steam networking.

This experiment repairs only that startup boundary by running the existing
rootfs `dbus-daemon` as a root-owned private bus, while Steam still runs as
UID 501 and receives the bus address. This is intentionally a compatibility
probe, not the final user-session design: it tests whether a reachable D-Bus
session endpoint changes Steam's behavior without requiring a nonexistent
UID-501 passwd record. It does not provide a system bus or NetworkManager.

```text
control variable=NOVA_TERMUX_X11_DBUS_SESSION_USER=root
data plane=unchanged inherited Android connectivity
steam uid=501:20, unchanged
system bus=unchanged and absent
NetworkManager=not started or synthesized
Steam UI bundle=unchanged
presentation=unchanged direct Termux:X11 Android SurfaceView
```

The launcher removes the stale exact runtime directory before starting the
bus, records the owner mode and socket, terminates any daemon matching that
run-scoped socket, and removes the complete private runtime directory on
exit. No persistent rootfs `/etc/passwd` edit is made.

## Fixed device profile

Use the same successful inventory profile and a fresh run identity:

```text
device=Retroid Pocket Nova
adb_serial=675a2365
termux_x11_apk=/tmp/nova-x11-prior-art-20260809/termux-x11-universal-debug.apk
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
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
x11_client=android/nova-lab/device/nova-termux-x11-steam-client.sh
x11_window_name=empty, select the first viewable depth-1 child
x11_window_wait_seconds=25
x11_capture_delay_seconds=8
x11_capture_failure=allowed for observation, with status retained
input_mode=android-keyevent-sequence
input_keycodes=66,66,66
input_after_delay_seconds=8
steam_timeout_seconds=75
network_observer=enabled
network_observer_duration_seconds=45
network_observer_interval_seconds=5
NOVA_TERMUX_X11_DBUS_SESSION=1
NOVA_TERMUX_X11_DBUS_SESSION_USER=root
```

Use a fresh identity such as:

```text
termux-x11-<UTC>-network-root-session-bus-0
```

Read `docs/34-nova-runtime-harness-lifecycle.md` immediately before launch.

## Acceptance gates

1. Exact-scope preflight cleanup passes and all Steam logs, processes,
   sockets, captures, and observer outputs are fresh.
2. The client log records
   `client_dbus_session_status=pass`,
   `client_dbus_session_user=root`, and a private socket address. The
   observer sees the matching `dbus-daemon` and private session path while
   Steam is alive.
3. The native Steam window is discovered, the Android and X11 captures remain
   valid/changed after the same three Enter events, and the UI remains live.
4. The network observer completes with `network_observer_status=pass` and
   retains the same Android validated-network, chroot DNS/HTTPS, and external
   Steam socket evidence as the inventory baseline.
5. Fresh Steam logs and final visual/API evidence state whether the session
   bus changes the missing `SteamClient.User` bridge, the `Waiting for
   network...` state, or the QR/login surface. The `NMClient` system-bus
   failure is expected to remain unless independent evidence says otherwise.
6. Teardown proves no matching Steam/X11 process, root-private bus process,
   private bus socket, temporary runtime directory, mount, or observer
   artifact remains.

## Interpretation

* If the root-private bus starts but Steam still waits with `NMClient` and
  `SteamClient.User` unchanged, the session-bus endpoint is not sufficient;
  proceed to a separately declared system-bus/NetworkManager service
  investigation.
* If the login bridge changes, preserve this as evidence that D-Bus presence
  matters, but do not call the root-owned bus the final architecture. Follow
  with a user-session or compatible service implementation experiment.
* If the root-private bus cannot start or leaks, treat that as a harness
  failure, repair it, and do not reinterpret the inherited Android data plane.

Document, commit, and push the result before another device hypothesis.
