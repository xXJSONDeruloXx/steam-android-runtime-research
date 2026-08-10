# Termux:X11 native ARM64 Steam delayed CEF capture experiment — 2026-08-09

Status: completed; see the [device result](155-termux-x11-native-steam-cef-delayed-capture-result-2026-08-09.md).

## Why this is next

The [`-cef-disable-gpu` result](153-termux-x11-native-steam-cef-disable-gpu-result-2026-08-09.md)
changed the physical output from white to a SteamOS splash. Its fresh CEF/UI
logs reached `OOBE Store: keyboards 1` several seconds after the X11 window
was first discoverable, so the existing immediate capture sampled startup and
the paired X11/Android images disagreed.

## One-variable capture change

The harness gains a run-scoped delay before X11 and Android capture:

```text
NOVA_TERMUX_X11_CAPTURE_DELAY_SECONDS=8
```

The default remains zero. This run keeps `-cef-disable-gpu`, all rootfs
mounts, Steam flags, software environment, APK, UID/GID, timeout, and cleanup
harness unchanged. The delay is recorded in run metadata.

## Acceptance and interpretation

Require complete client logs, a viewable Steam/webhelper window, clean
cleanup, and paired X11/Android captures after the delay. The target is any
actual Steam UI beyond the splash, especially OOBE/login/QR. If the delayed
capture is still blank or splash-only, retain the flag result and move to the
next isolated CEF mode; do not combine flags in this run.
