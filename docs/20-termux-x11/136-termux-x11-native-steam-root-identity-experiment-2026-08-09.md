# Termux:X11 native ARM64 Steam root-identity experiment — 2026-08-09

Status: completed; the device result is recorded in
`docs/20-termux-x11/137-termux-x11-native-steam-root-identity-result-2026-08-09.md`.

## Why this is next

The controlled [stdio probe result](135-termux-x11-rootfs-stdio-probe-result-2026-08-09.md)
shows that uid 501 cannot open the character devices created inside the
`/data/local/tmp` rootfs, even when the nodes are mode `666`. The first direct
Steam attempt therefore cannot be repaired by changing only Bash stdin
redirection: Steam still needs `/dev/urandom`.

This experiment asks one diagnostic A/B question: does the same native ARM64
Steam executable advance when the rootfs process remains uid 0 and can access
the root-created device nodes?

## One-variable change

The direct launcher now accepts `NOVA_TERMUX_X11_STEAM_UID` and
`NOVA_TERMUX_X11_STEAM_GID`; its default remains `501:20`. This run sets only:

```text
NOVA_TERMUX_X11_STEAM_UID=0
NOVA_TERMUX_X11_STEAM_GID=0
```

Everything else remains fixed from the failed uid-501 profile:

```text
display=:0
presentation=Termux:X11 Android SurfaceView
apk=official Termux:X11 universal debug APK
steam_flags=-gamepadui -steamos3 -steampal -steamdeck -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox
steam_renderer=swrast + softpipe + LIBGL_ALWAYS_SOFTWARE=1
steam_timeout=60s
x11_window_wait_seconds=25
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
```

The existing rootfs device helper still runs before the server, and the
existing exact cleanup gates still run before and after the session. The run
must record the fresh Steam stderr, X11 tree, Android screenshot if a window
appears, and the uid/gid in metadata.

## Acceptance and interpretation

- A Steam X11 child plus fresh Steam/SteamUI evidence would confirm that uid
  501's rootfs device boundary is the current blocker. It would be a
  diagnostic success, not a proposed root-run product design.
- A root process that still dies before an X11 child rejects the simple uid
  explanation and moves the investigation to the Steam loader/runtime or
  another rootfs dependency.
- A visible Android Steam frame is required before any OOBE, login, or QR
  interpretation. No Gamescope/AHardwareBuffer conclusion is allowed from
  this direct-X11 A/B.

The rootfs is disposable and the profile is bounded; any root-owned files
created by this diagnostic are cleaned or remain confined to that rootfs.
