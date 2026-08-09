# Termux:X11 native ARM64 Steam OOBE Enter retry experiment — 2026-08-09

Status: predeclared; no device launch has run for this profile.

## Why this is next

The [first Enter experiment](156-termux-x11-native-steam-oobe-enter-experiment-2026-08-09.md)
reached the live OOBE selector but failed before sending its event because the
focus guard searched the wrong Android service output. The [result](157-termux-x11-native-steam-oobe-enter-focus-guard-result-2026-08-09.md)
shows that Android 13 reports the authoritative focused window through
`dumpsys input`:

```text
FocusedWindows:
    displayId=0, name='... com.termux.x11/com.termux.x11.MainActivity'
```

## One harness-observability repair

The harness now uses the `FocusedWindows` record from `dumpsys input` for its
pre-input and post-input focus gate. It still captures `dumpsys window windows`
for the full Android window inventory. The only intended device action remains
one focused Android keyevent:

```text
NOVA_TERMUX_X11_INPUT_MODE=android-keyevent
NOVA_TERMUX_X11_INPUT_KEYCODE=66
NOVA_TERMUX_X11_INPUT_KEY_NAME=KEYCODE_ENTER
```

All Steam flags, `-cef-disable-gpu`, startup delay, rootfs mounts, display,
APK, software renderer, timeout, and cleanup behavior remain unchanged from
the first attempt. This run must use a fresh run ID.

## Acceptance

Before injection, require `dumpsys input` to name `com.termux.x11` as the
focused window and record the exact input command/status. After injection,
require the same X11 window ID to remain viewable and capture both X11 and
Android frames. The strongest pass is a changed OOBE page showing that English
was accepted; an unchanged page with valid input provenance is an input-path
negative that determines the next mapping experiment.

No second key, controller event, or touch action belongs in this run. Commit
and push the result before selecting the next OOBE action.
