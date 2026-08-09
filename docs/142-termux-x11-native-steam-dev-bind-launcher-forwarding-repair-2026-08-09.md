# Termux:X11 native ARM64 Steam bind-launcher forwarding repair — 2026-08-09

Status: completed; the device result is recorded in
`docs/143-termux-x11-native-steam-dev-bind-result-2026-08-09.md`.

## Reason

The previous [bind profile preflight](141-termux-x11-native-steam-dev-bind-preflight-result-2026-08-09.md)
never reached the private namespace because the client launcher hard-coded
`chroot` and discarded the new `chroot-dev` mode. The mount probe itself had
already passed, so this repair changes only argument forwarding.

## One-variable repair

`nova-termux-x11-client-launcher.sh` will now accept and validate the explicit
namespace mode supplied by the host harness:

```text
chroot       -> existing rootfs behavior
chroot-dev   -> private Android-/dev bind behavior
```

It passes the remaining rootfs and command arguments unchanged to
`nova-x11-private-namespace.sh`. The direct Steam profile remains:

```text
NOVA_TERMUX_X11_BIND_ANDROID_DEV=1
uid_gid=501:20
display=:0
steam_renderer=swrast + softpipe + LIBGL_ALWAYS_SOFTWARE=1
gamescope=not_used
ahb_bridge=not_used
surfacecontrol=not_used
```

The next run gets a fresh run ID. Its acceptance gate is first a successful
`chroot-dev` namespace launch, then the same native Steam/X11 window and
Android screenshot gates. No UID, Steam flag, renderer, or compositor change
is combined with this repair.
