# Termux:X11 native ARM64 Steam OOBE login settle experiment — 2026-08-09

Status: predeclared; no device launch has run for this profile.

## Why this is next

The [network-selection result](165-termux-x11-native-steam-oobe-login-wait-result-2026-08-09.md)
shows a same-run split: Steam logs completed OOBE Stage 2 and entered
`WaitingForCredentials`, but the four-second physical/X11 capture still showed
`Waiting for network...`. The next test changes only the time allowed after
each event so the third-step frame can settle.

## One-variable change

Keep the fresh three-event sequence and all rendering/session variables fixed,
but set:

```text
NOVA_TERMUX_X11_INPUT_AFTER_DELAY_SECONDS=12
```

The input remains:

```text
NOVA_TERMUX_X11_INPUT_MODE=android-keyevent-sequence
NOVA_TERMUX_X11_INPUT_KEYCODES=66,66,66
NOVA_TERMUX_X11_INPUT_KEY_NAME=KEYCODE_ENTER
```

The total sequence remains within the native client's 60-second bound. No
additional key or touch event is permitted.

## Acceptance

Require all three focus/injection gates, same-window per-step captures, and
clean teardown. The stronger pass is the Steam login surface with a visible
QR code on both the physical Nova display and the paired X11 capture. If the
frame remains `Waiting for network...`, preserve that result and correlate it
with the fresh `SetOOBEComplete`/`WaitingForCredentials` logs before changing
network or login behavior.
