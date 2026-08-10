# Termux:X11 native ARM64 Steam OOBE network-select experiment — 2026-08-09

Status: completed; see the [network-selection result](165-termux-x11-native-steam-oobe-login-wait-result-2026-08-09.md).

## Why this is next

The [two-Enter result](163-termux-x11-native-steam-oobe-network-result-2026-08-09.md)
reached `Choose your network` with `Continue with Android host network`
highlighted while the same Steam/X11 session remained alive. The next action
is to select that already-highlighted network option.

## Controlled sequence

Use a fresh session and send exactly three focused Enter events:

```text
NOVA_TERMUX_X11_INPUT_MODE=android-keyevent-sequence
NOVA_TERMUX_X11_INPUT_KEYCODES=66,66,66
NOVA_TERMUX_X11_INPUT_KEY_NAME=KEYCODE_ENTER
```

The first two events are the fixed setup (language and timezone); only the
third event extends the prior sequence. Capture each step independently. Keep
the Steam flags, `-cef-disable-gpu`, eight-second startup delay, rootfs mounts,
UID/GID, APK, display, software renderer, timeout, and cleanup unchanged.

## Acceptance

Require focus and successful injection at all three steps, a stable viewable
Steam X11 window, paired Android/X11 captures after every event, and exact
cleanup. The expected stronger pass is `Choose your network` after step two
and a subsequent Steam login/OOBE page after step three. If network selection
stalls or opens a different page, retain the frame and logs as the next
state-specific boundary.

Do not send a fourth event in this run. Document, commit, and push the result
before extending the sequence toward QR login.
