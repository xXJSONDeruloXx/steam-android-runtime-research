# Termux:X11 native ARM64 Steam OOBE Enter-input experiment — 2026-08-09

Status: completed; the first launch exposed a focus-observation bug before
the keyevent was sent. See the [focus-guard result](157-termux-x11-native-steam-oobe-enter-focus-guard-result-2026-08-09.md)
and the [authoritative-focus retry](158-termux-x11-native-steam-oobe-enter-retry-experiment-2026-08-09.md).

## Why this is next

The [delayed CEF result](155-termux-x11-native-steam-cef-delayed-capture-result-2026-08-09.md)
reached the actual Steam OOBE language selector on both the physical Android
screen and the paired X11 capture. `English` is highlighted and the footer
identifies the select action as `A SELECT`.

Termux:X11's Android-side input implementation converts focused Android
`KeyEvent`s into X-server keyboard events. This experiment adds only a
run-scoped, focus-guarded Android keyevent to the existing direct-X11 harness:

```text
NOVA_TERMUX_X11_INPUT_MODE=android-keyevent
NOVA_TERMUX_X11_INPUT_KEYCODE=66
NOVA_TERMUX_X11_INPUT_KEY_NAME=KEYCODE_ENTER
```

The action is intended to accept the already-highlighted English choice. It
is deliberately a single event, not a scripted OOBE sequence. The existing
Steam command, `-cef-disable-gpu`, rootfs mounts, UID/GID, display, delayed
startup capture, APK, renderer environment, and 60-second bound remain fixed.

## Focus and evidence contract

Immediately before injection, the harness must capture Android window state
and Android input-dispatch state, then require `com.termux.x11` to own focus
in the `dumpsys input` `FocusedWindows` record. If the known Nova settings overlay
owns focus, the harness may dismiss it with Back, record the refreshed focus
state, and then recheck the guard. Any other focus loss fails the run before
the target event is sent.

The run records:

- the exact Android keycode/name and command status;
- before/after Android window focus state;
- before/after Android screenshots;
- before/after X11 window captures and the stable X11 window ID;
- fresh Steam/UI logs and the standard exact-scope cleanup markers.

Acceptance is a valid focused input injection with complete paired captures
and clean teardown. A changed OOBE page is the stronger pass. An unchanged
page is still a useful input-path result and determines whether the next
experiment should use a different X11 key mapping, Android controller event,
or direct touch coordinate.

Do not send a second input in this run and do not start a new device run until
the result is documented, committed, and pushed.
