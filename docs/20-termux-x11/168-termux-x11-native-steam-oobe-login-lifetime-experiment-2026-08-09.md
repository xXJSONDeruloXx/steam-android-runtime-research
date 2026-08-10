# Termux:X11 native ARM64 Steam OOBE login-lifetime experiment — 2026-08-09

Status: predeclared; no device launch has run for this profile.

## Why this is next

The [12-second settle result](167-termux-x11-native-steam-oobe-login-settle-result-2026-08-09.md)
shows that the Android and X11 frames remain synchronized on
`Waiting for network...` even after Steam reports connected local UI transport,
successful basic connectivity, and `WaitingForCredentials`. The prior client
bound ended at 60 seconds, so the next test extends the process lifetime and
the per-event visual settle together.

## One-variable experiment

Keep the same fresh three-Enter sequence, namespace, software-rendered CEF
flags, APK, display, and capture paths. Change only the bounded session timing:

```text
NOVA_TERMUX_X11_STEAM_TIMEOUT_SECONDS=180
NOVA_TERMUX_X11_INPUT_AFTER_DELAY_SECONDS=30
```

The timeout override is a harness observability control; its default remains
60 seconds for existing profiles. No additional input event is permitted.

## Acceptance

Require all three focus/injection gates, the same X11 window ID at every step,
paired Android/X11 captures, and clean exact-scope teardown. The stronger pass
is a visible Steam QR/login surface on both the physical Nova display and the
paired X11 frame. If the final frame remains `Waiting for network...`, correlate
the longer run with `connection_log.txt`, `steamui_login.txt`,
`webhelper_js.txt`, and the client timeout boundary before changing Steam
flags, network setup, or rendering.
