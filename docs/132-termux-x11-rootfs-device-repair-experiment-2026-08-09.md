# Termux:X11 rootfs device-namespace repair experiment — 2026-08-09

Status: predeclared repair; the device result is recorded in
`docs/133-termux-x11-rootfs-device-repair-result-2026-08-09.md`.

## Hypothesis

The first direct Steam launch failed before X11 window creation because the
chrooted rootfs had no usable `/dev/urandom`. The Android host has the device,
but the private X11 namespace cannot bind-mount Android `/dev` because the
attached root environment exposes no mount capability. The next bounded run
will create the minimum character devices directly in the disposable rootfs.

## One-variable repair

`android/nova-lab/device/nova-termux-x11-rootfs-devices.sh` will run as root
before the Termux:X11 Activity/server launch and verify these exact nodes:

```text
null   c 1,3
zero   c 1,5
full   c 1,7
random c 1,8
urandom c 1,9
tty    c 5,0
```

Malformed regular files at those exact paths are replaced; `/dev/input` and
`/dev/shm` are left untouched. The helper emits a pass/fail marker and its
SHA-256 is recorded with the run provenance. The host harness also now honors
an explicitly empty `NOVA_TERMUX_X11_WINDOW_NAME`, allowing the Steam profile
to select any viewable depth-1 X11 child instead of silently restoring the
synthetic name.

Everything else remains fixed from the failed direct-Steam run:

```text
display=:0
steam_flags=-gamepadui -steamos3 -steampal -steamdeck -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox
steam_renderer=swrast + softpipe + LIBGL_ALWAYS_SOFTWARE=1
steam_uid=501:20
steam_timeout=60s
x11_window_wait_seconds=25
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
```

## Acceptance and interpretation

The next run must first prove `nova_rootfs_devices=pass`. Then the existing
direct-Steam gates apply: fresh Termux:X11 socket, viewable Steam X11 child,
Android screenshot if a window appears, fresh Steam/SteamUI evidence, and
exact cleanup. If Steam advances beyond the `/dev/urandom` assertion, that is
a new result boundary; do not combine it with a graphics or input change.
