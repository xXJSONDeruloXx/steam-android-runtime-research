# Termux:X11 native ARM64 Steam OOBE timezone Enter experiment — 2026-08-09

Status: predeclared; no device launch has run for this profile.

## Why this is next

The [Enter retry result](159-termux-x11-native-steam-oobe-timezone-result-2026-08-09.md)
proved that one focused Android `KEYCODE_ENTER` reaches the X11 Steam UI and
advanced the OOBE from language selection to `Choose your timezone`. The next
fresh session should preserve that progress and presents `Pacific Standard
Time` highlighted.

## One controlled action

Repeat the exact direct-X11 native Steam profile with a fresh run ID and send
exactly one focused event:

```text
NOVA_TERMUX_X11_INPUT_MODE=android-keyevent
NOVA_TERMUX_X11_INPUT_KEYCODE=66
NOVA_TERMUX_X11_INPUT_KEY_NAME=KEYCODE_ENTER
```

Keep `-cef-disable-gpu`, the eight-second startup delay, rootfs `/dev`,
`/dev/shm`, and `/proc` mounts, UID/GID, APK, display, software renderer,
timeout, focus guard, and cleanup unchanged. Do not send a second event in
this run.

## Acceptance

Require the before-input frame to be a fresh Steam OOBE page, the authoritative
`dumpsys input` focus gate to name Termux:X11, successful Enter injection, the
same viewable X11 window after input, paired post-input captures, and clean
teardown. The expected stronger pass is movement past timezone selection into
the next OOBE/network stage. If the fresh session returns to language instead,
record that persistence boundary rather than treating it as a failed input
event.
