# Termux:X11 display bring-up partial result — 2026-08-09

Status: partial device result. The official Termux:X11 Android process reached
its Android `SurfaceView`, native EGL, and XCB setup on the Retroid Pocket
Nova. The external synthetic client did not run because a direct `chroot`
from the restricted `su` shell returned `Operation not permitted`. No claim is
made yet for a mapped synthetic X11 window, an X11 pixel capture, Steam, OOBE,
or QR login.

The first private-namespace retry is documented in
[doc 120](120-termux-x11-private-namespace-client-retry-2026-08-09.md); it
found a second Android-shell launch/identity issue and is also not a rendering
acceptance.

This is the first result in the open-ended X11/Termux track. The result and
the private-namespace/teardown harness repair must be pushed before repeating
the synthetic client or launching Steam.

## Experiment identity

The first three run directories were staging or server-start failures and did
not launch a usable display boundary:

| Run | First failed boundary | Classification |
|---|---|---|
| `termux-x11-20260809T142104Z-display-0` | Nested rootfs staging under `/opt` | Harness staging failure; no server launch |
| `termux-x11-20260809T143453Z-display-0` | Root-owned state directory could not accept PID/log writes | Harness state-path failure; no server launch |
| `termux-x11-20260809T143645Z-display-0` | Termux:X11 server created no socket | `su` reset `TMPDIR`; subsequent foreground probes also exposed APK classpath and rootfs XKB-path issues |

The first useful server/Activity run was:

```text
run_id=termux-x11-20260809T144317Z-display-0
repo_commit=acd73d68098344dc9ada4f267167c7b46582816e
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
device_root=/data/local/tmp/nova-holo-rootfs
display=:0
termux_x11_source_commit=d8013ac5d174bb16120f915c10a7255948c59c17
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
x11_animate_sha256=884853cdc47c0d10a644153404fcd25e155b8784e24903f3ced568649b10bc04
x11_capture_sha256=a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206a3efb4b017
presentation=Termux:X11 Android SurfaceView
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
```

The run artifact directory is
`android/nova-lab/build/manual-runs/termux-x11-20260809T144317Z-display-0/`.

## Observed evidence

The fresh logcat baseline and server log contain the official Termux:X11
revision, the intended rootfs `TMPDIR`, Adreno EGL initialization, a native
X11 client connection from the Activity, `rendererSetWindow` at 1280x864, and
the Activity-side `XCB connection is successfull` marker. The X11 helper saw a
live root display:

```text
nova_x11_display=pass display=:0 screen=0 root=0x511
nova_x11_window id=0x511 parent=0x0 depth=0 map_state=viewable x=0 y=0 width=1280 height=714 border=0 name="<none>" res_name="<none>" res_class="<none>"
nova_x11_tree=pass root=0x511
```

That tree contains only the root window. The expected synthetic window named
`Nova animated Xwayland Gamescope probe` is absent. The run therefore stopped
before producing `x11-window.ppm` or `android-screenshot.png`; it is not an
accepted rendering result.

The external client launch used plain `chroot` and failed on the device with:

```text
chroot: /data/local/tmp/nova-holo-rootfs: Operation not permitted
```

The root probe in [doc 7](07-nova-rooted-bridge-smoke-test.md) already showed
that this Nova requires `/system/bin/unshare -m` before chroot. This result
therefore resolves the next harness hypothesis without changing Gamescope or
the Android presentation path.

## Teardown finding and repair

The first run's teardown also attempted to remove the root-owned X11 socket
and lock from the ordinary `su` shell. That shell has UID 0 but
`CapEff=0000000000000000`, so the cleanup reported:

```text
rm: /data/local/tmp/nova-holo-rootfs/tmp/.X11-unix/X0: Permission denied
rm: /data/local/tmp/nova-holo-rootfs/tmp/.X0-lock: Operation not permitted
server_state=absent client_state=absent socket_state=present
```

The recorded server PID also did not uniquely identify the live
`termux-x11` process; the process was visible by its exact `/proc/*/comm`
identity. The residual server and socket were then removed with exact PIDs
and a private `unshare -m` namespace, and the device was rechecked with no
matching Termux:X11 process and no `X0` socket remaining.

The durable repair adds two run-scoped device helpers:

- `nova-x11-private-namespace.sh` enters `unshare -m` for both chroot client
  and X11 capture commands, and removes rootfs-owned files in that namespace.
- `nova-termux-x11-cleanup.sh` identifies the exact `termux-x11` and
  `nova-x11-animate` process names, handles the server's shell parent, stops
  the Activity, removes only this run's staged paths/socket/lock, and verifies
  the named processes and socket are absent.

The harness now also pulls client stdout/stderr even when the window gate
fails, and records the helper hashes and remote paths in `run-metadata.txt`.

## Result and next gate

The Android display boundary is promising but incomplete:

1. Official Termux:X11 installation and `CmdEntryPoint` startup pass.
2. Android Activity EGL/XCB initialization and a live root X display pass.
3. The external Linux X11 client and pixel-level presentation remain
   untested because direct chroot is invalid on this device.
4. Steam must not be launched until the corrected namespace-backed synthetic
   client maps and both same-run X11/Android captures pass.

The next device run changes only the client/teardown entry path to the
committed private-namespace helpers. If that passes, the following experiment
can predeclare native ARM64 Steam over direct Termux:X11. Every subsequent
OOBE, login, and QR-display attempt remains separately documented, committed,
and pushed.
