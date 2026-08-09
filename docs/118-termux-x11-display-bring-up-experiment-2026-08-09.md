# Termux:X11 display bring-up experiment — 2026-08-09

Status: predeclared; no device result yet.

This is experiment 1 of the maximum-five ladder in
[`docs/117-x11-android-forwarding-experiment-plan-2026-08-09.md`](117-x11-android-forwarding-experiment-plan-2026-08-09.md).
It tests only the Android X11 display boundary. It does not launch Steam,
Gamescope, the Nova APK, the AHardwareBuffer bridge, or `SurfaceControl`.

## One-variable question

Can a fresh official Termux:X11 Android server display a synthetic X11 client
from the existing Nova ARM64 chroot on the attached Retroid Pocket Nova?

The device has no Termux package installed at preflight, so this experiment
uses the official APK plus Termux:X11’s documented rooted chroot entrypoint:
`CmdEntryPoint` launched with `app_process`, `TMPDIR` pointed at the chroot’s
shared `/tmp`, and `XKB_CONFIG_ROOT` pointed at the chroot XKB tree. This is a
deliberate direct-entrypoint bring-up, not a claim that the full Termux app and
companion-package product flow has been validated.

## Artifact identity

```text
termux_x11_release=nightly
termux_x11_release_tag=20260809
termux_x11_source_commit=d8013ac5d174bb16120f915c10a7255948c59c17
termux_x11_apk=termux-x11-universal-debug.apk
termux_x11_apk_url=https://github.com/termux/termux-x11/releases/download/nightly/termux-x11-universal-debug.apk
termux_x11_apk_sha256=6718ed4e5c11c1a718effa3dae14622575da6f87ef935fa12e4595aea761f705
termux_x11_apk_size=14574938
adb_serial=675a2365
device=Retroid Pocket Nova
android=13
rootfs=/data/local/tmp/nova-holo-rootfs
display=:0
```

The client is the existing checked-in ARM64 `nova-x11-animate` build. Its
binary hash, the exact run ID, and all pulled device artifacts must be written
to the result document.

## Pre-run staging constraint

The first harness attempt stopped before launching `CmdEntryPoint`: copying a
client into a nested directory under the chroot failed with `Permission denied`.
The device reports `uid=0(root)` through `su`, but `CapEff=0000000000000000`,
and both `mount` and `umount` fail. A run-specific direct file in the existing
chroot `/tmp` can be written with `adb push`, so the harness stages the client
and capture helper as direct `/tmp/nova-x11-*-<run-id>` files and removes those
exact files during cleanup. No bind mount is part of this experiment.

The first post-staging rerun also showed that directories created by the
restricted `su` shell become `root:root` and cannot receive its own log/PID
writes. The harness therefore creates a run-specific state directory through
the regular shell transport, makes only that directory writable, and records
its path in `run-metadata.txt`.

The next fresh run reached `app_process` but never created the X11 socket. A
foreground reproduction captured `$TMPDIR is not set. Normally it is pointing
to /tmp of a container.`: this device's `su -c` wrapper resets an in-shell
`export TMPDIR=...` to `/data/local/tmp`, which Termux:X11 intentionally
rejects. The harness now applies `TMPDIR`, `XKB_CONFIG_ROOT`, and `CLASSPATH`
with `/system/bin/env` on the `app_process` command itself.

That environment fix then loaded `CmdEntryPoint` but reported the official
commit and rejected the rootfs-visible XKB symlink: its
`/usr/share/X11/xkb` target resolves to device `/usr/share/xkeyboard-config-2`.
The real rootfs directory exists at `/usr/share/xkeyboard-config-2`, so the
harness now uses that non-symlink path. The APK path is resolved with a
separate `pm path` call before entering `su`; command substitution inside the
`adb shell su -c` payload was empty on this device. The run also clears
logcat immediately before Activity/server launch and records the device APK
path, establishing a fresh log baseline.

## Procedure and gates

`android/nova-lab/deploy-termux-x11-forwarding-smoke-test.sh` must:

1. Verify the APK and client/helper hashes and create a fresh run directory.
2. Stop only the prior X11 server/client recorded by the lab PID files, force-
   stop the Termux:X11 Activity, and verify the display socket is absent.
3. Install the named APK, launch the documented `CmdEntryPoint` server with
   the shared chroot `/tmp`, and open the Termux:X11 Activity.
4. Run the synthetic X11 animation from the chroot with `DISPLAY=:0`.
5. Pull an Android `screencap`, an X11 window tree, and a same-run X11 PPM
   capture while the animation is mapped. Record logcat and focused-window
   state.
6. Stop the exact client/server, close the Activity, remove only this run’s
   temporary files/sockets, and verify no matching process or display socket
   remains.

Pass requires all of the following:

- the Termux:X11 server starts from the fresh run;
- the synthetic X11 window is mapped and the X11 PPM is non-empty/non-uniform;
- the Android-side screenshot is non-empty/non-uniform and is captured while
  the Termux:X11 Activity is foreground;
- the run records the X display/socket, server/client PIDs, APK/client/helper
  SHA-256 values, and the exact run ID; and
- post-stop process/socket cleanup passes.

If the result fails, classify the first failed boundary as APK install,
`app_process`/server startup, shared `/tmp` socket visibility, X11 client
connection, X11 rendering, or Android Activity rendering. Do not install a
different X server or launch Steam under this experiment.

## Expected artifacts

```text
run-metadata.txt
termux-x11-apk.sha256
nova-x11-animate.sha256
nova-x11-capture.sha256
nova-runtime-cleanup-preflight.txt
termux-x11-server.log
termux-x11-client.log
x11-tree.txt
x11-capture.txt
x11-window.ppm
android-screenshot.png
android-window-state.txt
android-logcat.txt
nova-runtime-cleanup.txt
post-stop-verification.txt
```
