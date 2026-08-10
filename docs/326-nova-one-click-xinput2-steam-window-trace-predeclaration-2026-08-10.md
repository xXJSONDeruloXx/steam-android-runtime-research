# Nova one-click XInput2 Steam-window trace predeclaration — 2026-08-10

Status: predeclared; no device result is claimed by this document.

## Question

The root-window XI2 trace in [run 325](325-nova-one-click-xinput2-touch-trace-result-2026-08-10.md)
selected XInput2 successfully but observed zero events during the tap. The
remaining diagnostic ambiguity is event-selection scope: the X server may
deliver events only to the discovered `Steam Big Picture Mode` window rather
than to the root selection.

This run repeats the same input with the tracer selecting both the X11 root and
the fresh Steam window. It changes only the observation target, not the input
coordinate or Steam session profile.

## Planned run

- Run ID: `nova-one-click-xinput2-steam-window-trace-20260810T160142Z`
- Branch: `main`
- The optional `--window WINDOW_ID` tracer support and this predeclaration will
  be committed before device launch.
- Path: the prepared APK one-click profile → Termux:X11 `DISPLAY=:0` → signed-
  in Steam Big Picture.
- Input: one synthetic `adb shell input tap 620 545`.
- Target: the fresh window ID discovered from the same run's X11 tree; the
  tracer will be invoked as `--xi2-trace 10 --window WINDOW_ID`.
- Audio: not an acceptance gate; playback remains audible but delayed.

## Acceptance and interpretation

The tracer must report XInput2 extension/version pass, independent root and
Steam-window selection pass, and `nova_xi2_trace=pass` after 10 seconds. The
event count is interpreted separately:

- events on the explicit Steam-window selection: Android touch reaches that
  X11 client boundary, so investigate Steam/CEF handling or a touch-to-pointer
  adapter;
- zero events on both selections: close the Termux:X11 touch-delivery
  hypothesis for this synthetic tap and implement an Android MotionEvent bridge
  or promote the existing Gamescope/libei touch path.

Before/after focus, screenshots, session ID, helper hashes, exact cleanup,
rootfs D-Bus state, and targeted process audit are required. A UI screenshot
alone cannot qualify input success.

## Out of scope

This run does not modify Gamescope, AHardwareBuffer, Vulkan WSI, Steam profile,
audio buffering, networking, or APK defaults. It is the final scope check for
the current Termux:X11 observation path.
