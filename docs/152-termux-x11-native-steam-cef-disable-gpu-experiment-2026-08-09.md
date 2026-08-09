# Termux:X11 native ARM64 Steam `-cef-disable-gpu` experiment — 2026-08-09

Status: completed; see the [device result](153-termux-x11-native-steam-cef-disable-gpu-result-2026-08-09.md).

## Why this is next

The [native baseline](151-termux-x11-native-steam-cleanup-control-result-2026-08-09.md)
proved native Steam stays alive, its Big Picture and `steamwebhelper` windows
map through Termux:X11, Steam UI logic reaches `OOBE Store: keyboards 1`, and
the physical surface is still solid white. The fresh CEF report identifies
software ANGLE/softpipe X11 composition and an early CEF crash-reporting
assertion. GameNative prior art uses `-cef-disable-gpu` in its Steam profile.

## One-variable change

Add only this Steam command-line flag:

```text
-cef-disable-gpu
```

All mounts (`/dev`, `/dev/shm`, `/proc`), UID/GID, Steam flags, existing
software-renderer environment, network compatibility patch, Termux:X11 APK,
window gate, timeout, and cleanup harness remain unchanged.

## Acceptance and interpretation

Require complete client logs, viewable Steam/webhelper windows, X11 capture,
physical Android capture, and automatic cleanup. Compare the actual pixels and
the fresh `steamwebhelper` GPU report with the baseline. A non-white screen is
progress toward OOBE; a white screen with changed GPU mode is a useful
negative result. Do not combine additional CEF flags in this run.
