# Termux:X11 private session-bus experiment — 2026-08-09

Status: predeclared; not run yet.

## Question

The successful network inventory proved that Android Wi-Fi, DNS, HTTPS, and
external Steam/webhelper sockets work inside the `chroot-dev` namespace. It
also found no D-Bus session or system bus and recorded fresh Steam messages
about the missing session bus and `NMClient` system service.

This experiment isolates only the session-bus portion of that boundary:

```text
control variable=run-scoped private D-Bus session bus
data plane=unchanged inherited Android connectivity
system bus=unchanged and absent unless the device proves otherwise
NetworkManager=not started or synthesized
Steam UI bundle=unchanged
presentation=unchanged direct Termux:X11 Android SurfaceView
```

The existing rootfs `/usr/bin/dbus-daemon` is started as Steam's UID with a
unique socket under the run's `/tmp` namespace. The Steam process receives
only `DBUS_SESSION_BUS_ADDRESS`; the launcher must fail explicitly if the
requested daemon cannot be started, rather than silently falling back to the
baseline.

## Implementation boundary

The opt-in launcher setting is:

```text
NOVA_TERMUX_X11_DBUS_SESSION=1
```

The launcher records the daemon path, socket, PID, startup status, and daemon
output in the existing Steam client log, then terminates the daemon and
removes the exact run-scoped socket directory on every exit path. The direct
native launcher does not invoke `dbus-launch` for this variant, so a second bus
cannot replace the measured address.

No NetworkManager binary is added. A successful session-bus start therefore
cannot be interpreted as satisfying the fresh `NMClient` system-bus failure.

## Fixed device profile

The run must preserve the successful inventory profile:

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
```

Use a fresh run identity such as:

```text
termux-x11-<UTC>-network-session-bus-0
```

Read `docs/34-nova-runtime-harness-lifecycle.md` immediately before launch.

## Acceptance gates

Record all gates independently; a display pass is not a networking or login
pass.

1. The exact-scope preflight cleanup passes and the run starts from fresh
   Steam logs, processes, sockets, and captures.
2. The private session bus starts from the rootfs, its socket is visible while
   Steam runs, and the client log records
   `client_dbus_session_status=pass` plus the actual address.
3. The native Steam window is discovered, Android and X11 captures remain
   valid/changed after the same three Enter events, and the throbber remains
   active.
4. The observer completes with `network_observer_status=pass`, retaining
   Android validated-network state, chroot resolver/HTTPS checks, per-process
   sockets, and fresh D-Bus/NetworkManager endpoint state.
5. Compare fresh Steam logs and the final visual state with run
   `termux-x11-20260809T180325Z-network-inventory-3`. Specifically record
   whether the session-bus error disappears, whether the `NMClient` error
   remains, whether the `SteamClient.User` bridge becomes available, and
   whether the UI reaches a real QR/login surface.
6. Cleanup proves the Steam/X11 processes, private bus process, socket, mount,
   and temporary observer artifacts are absent. A leaked bus invalidates the
   run even if Steam displays.

## Interpretation

* If the session-bus error disappears but `NMClient` and the login wait remain,
  the session bus is useful prior art but not the blocker; proceed to a
  separately declared system-bus/NetworkManager service experiment only after
  locating a compatible service implementation.
* If the Steam login bridge changes or reaches QR/login, preserve the result
  as a minimal control-plane fix and rerun it once with the same profile for
  confirmation.
* If Steam cannot start with the private bus, document the failure and keep
  the proven inherited Android data plane unchanged. Do not compensate with a
  route/NAT/proxy or a UI monkey patch.

The experiment is complete only after its result is documented, committed, and
pushed before another device hypothesis begins.
