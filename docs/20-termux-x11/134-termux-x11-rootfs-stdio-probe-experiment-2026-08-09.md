# Termux:X11 rootfs stdio probe experiment — 2026-08-09

Status: completed; the device result is recorded in
`docs/20-termux-x11/135-termux-x11-rootfs-stdio-probe-result-2026-08-09.md`.

## Why this is next

The preceding [rootfs device repair result](133-termux-x11-rootfs-device-repair-result-2026-08-09.md)
proved that root can create `/dev/null`, `/dev/zero`, `/dev/random`,
`/dev/urandom`, `/dev/full`, and `/dev/tty`, but the direct Steam launcher
failed while Bash set up a background command and tried to use `/dev/null`.
A minimal uid-501 chroot probe could open `/dev/null` and `/dev/urandom` in a
foreground shell. The remaining uncertainty is therefore the shell's
implicit asynchronous-stdin path, the explicit redirection path, or the
`timeout` wrapper—not Steam rendering.

## One-variable boundary

This experiment launches no Termux:X11 Activity, X11 server, Steam process,
Gamescope process, AHardwareBuffer bridge, or SurfaceControl path. It only
executes harmless `/bin/true` and `/usr/bin/timeout` commands inside the
existing rootfs as uid 501, with a fresh run identity.

The checked-in probe compares:

```text
foreground_explicit_null
background_implicit_stdin
background_explicit_null
background_explicit_zero
timeout_explicit_null
timeout_background_explicit_null
urandom_explicit_fd
```

Each case has separate stdout, stderr, and exit-status artifacts. The probe
also verifies the six expected character devices and records their Android
SELinux labels. The exact Nova runtime cleanup helper runs before and after
the probe even though the profile is not expected to start a Nova process.

## Expected interpretation

The most useful result is the pattern where the implicit-background case
fails, while the explicit-null, explicit-zero, `timeout`, and urandom cases
pass. That would justify one launcher-only repair: give the Steam background
command an explicit safe stdin and remove diagnostic redirections that depend
on `/dev/null`. If explicit-null also fails, the next repair must use the
successful alternative identified by the probe; no Steam launch should be
combined with that diagnosis.

If all cases pass, the prior failure is not reproduced and the next direct
Steam retry must first re-establish a fresh run identity and capture the
launcher stderr again. If device-node or foreground cases fail, the current
device namespace remains the blocker.

## Fixed boundaries

```text
uid_gid=501:20
rootfs=/data/local/tmp/nova-holo-rootfs
termux_x11_server=not_launched
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
```

No OOBE, login, QR, or Android-screen claim can be made from this probe. Its
purpose is only to make the next native Steam launch causally interpretable.
