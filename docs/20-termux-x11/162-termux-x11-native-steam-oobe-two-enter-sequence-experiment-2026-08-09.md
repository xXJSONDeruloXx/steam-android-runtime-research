# Termux:X11 native ARM64 Steam OOBE two-Enter sequence experiment — 2026-08-09

Status: completed; see the [two-step sequence result](163-termux-x11-native-steam-oobe-network-result-2026-08-09.md).

## Why this is next

The [persistence result](161-termux-x11-native-steam-oobe-timezone-persistence-result-2026-08-09.md)
shows that a fresh bounded Steam launch returns to the language selector, so
the OOBE must be advanced without tearing down the session. The next harness
mode keeps one Steam/X11 session alive and sends a short, explicit sequence:

```text
NOVA_TERMUX_X11_INPUT_MODE=android-keyevent-sequence
NOVA_TERMUX_X11_INPUT_KEYCODES=66,66
NOVA_TERMUX_X11_INPUT_KEY_NAME=KEYCODE_ENTER
```

The first Enter should accept English and move to timezone selection. The
second should accept the highlighted Pacific timezone and move to the next
OOBE/network stage. The harness captures focus, X11, and Android state before
and after each step and logs each event separately.

## Fixed variables and acceptance

Keep the exact Steam flags, `-cef-disable-gpu`, startup delay, rootfs mounts,
UID/GID, APK, display, software renderer, and 60-second client bound fixed.
Only the input mode changes from one event to a two-event in-session sequence.

Require a fresh language-page baseline, Termux:X11 focus before each event,
successful keyevent status for both events, a stable viewable X11 window, a
fresh capture after each step, and exact-scope cleanup. The stronger pass is a
visible timezone page after step one and a further OOBE/network page after
step two. If step two does not advance, preserve its capture and logs for the
next isolated input or OOBE-state experiment.

No third event belongs in this run. Commit and push the result before extending
the sequence.
