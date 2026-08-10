# Nova one-click XInput2 touch trace predeclaration — 2026-08-10

Status: predeclared; no device result is claimed by this document.

## Question

The [core-pointer probe](322-nova-one-click-x11-pointer-probe-result-2026-08-10.md)
showed that one Android `input tap` did not move the Termux:X11 core pointer or
set a core button mask. That does not distinguish complete input loss from a
touch-only XInput2 path. Termux:X11 may expose Android touch as XI2 touch
events without synthesizing a core pointer click.

This run asks only whether the X server emits XI2 touch, motion, or button
events while one tap is sent to the same working Steam surface.

## Planned run

- Run ID: `nova-one-click-xinput2-touch-trace-20260810T154904Z`
- Branch: `main`
- The read-only tracer and this predeclaration will be committed before device
  launch.
- Path: the existing prepared APK one-click profile → Termux:X11 `DISPLAY=:0`
  → signed-in Steam Big Picture at the current 1280x960 Android surface.
- Input: one synthetic `adb shell input tap 620 545`; no physical input is
  required and no coordinate change is introduced.
- Audio: not an acceptance gate; playback remains classified as audible but
  delayed based on the user's latest observation.

## Instrumentation

`nova-x11-input-trace` will query the XInput2 extension and select, on the X11
root window, only XI2 touch begin/update/end, motion, and button press/release
events. It will print device/source IDs, event detail, root/window coordinates,
and elapsed time for each received event. It does not inject, grab, or alter
events. A 10-second trace samples the event queue every 50 ms.

The run will retain the exact ARM64 tracer and APK hashes, fresh session ID,
focused-window dumps before and after the tap, before/after screenshots, the
raw XI2 trace, and exact cleanup/process/D-Bus results.

## Acceptance and interpretation

The tracer must complete with a fresh `nova_xi2_trace=pass` marker and the
one-click session must stop with exact cleanup pass markers. Event count is
interpreted separately:

- XI2 touch events present: Android touch reaches X11, so the next fix belongs
  at the Steam/CEF touch contract or in a touch-to-pointer/button adapter;
- XI2 events absent: Android/Termux:X11 is not delivering the tap to the X11
  server, so the product path needs an Android MotionEvent bridge or the
  existing app-owned Gamescope/libei touch path.

No event result alone proves Steam navigation. The result must correlate the
trace with focus and before/after UI evidence.

## Out of scope

This experiment does not change Gamescope, AHardwareBuffer, Vulkan WSI, Steam
profile, audio buffering, networking, or the APK's default launcher. It is a
single bridge-observation experiment following the core-pointer failure.
