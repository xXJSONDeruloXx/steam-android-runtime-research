# Nova one-click X11 pointer probe predeclaration — 2026-08-10

Status: predeclared; no device result is claimed by this document.

## Question

The direct one-click Steam path reaches a signed-in 1280x960 Big Picture
surface, but a fresh synthetic Android tap did not navigate the selected Steam
tab. The next narrow question is whether the tap reaches the Termux:X11 X11
server as a pointer position change, and if so what coordinate X11 observes.

This separates three possibilities that a screenshot alone cannot distinguish:

1. Android input never reaches the X11 pointer;
2. it reaches X11 with a rotation or scale transformation; or
3. X11 receives the expected position and Steam/CEF does not act on the click.

## Planned run

- Run ID: `nova-one-click-x11-pointer-probe-20260810T153333Z`
- Branch: `main`
- Baseline source: `0b3ed8b`; the probe implementation and this
  predeclaration will be committed before device launch.
- Path: APK LauncherActivity → visible Start button → root-side native ARM64
  Steam → Termux:X11 `DISPLAY=:0`.
- Presentation: direct X11 fullscreen at the existing 1280x960 target; this
  is not a Gamescope/AHardwareBuffer run.
- Input under test: one synthetic `adb shell input tap 620 545` after the
  signed-in Steam home surface is settled. No physical input is required.
- Audio: not an acceptance gate for this run; the latest user observation
  establishes playback as audible but delayed, so this run must not relabel
  it as an absent-device failure.

The existing exact-scope Nova cleanup helper will run before launch and after
the bounded session. The session will start with the APK's default prepared
profile and no diagnostic intent overrides. The helper will sample X11's root
pointer every 50 ms for 10 seconds while the tap is sent during the probe.

## Instrumentation

`android/nova-lab/device/nova-x11-capture.c` will gain a read-only
`--pointer-probe SECONDS` mode. It uses `XQueryPointer` on the X11 root window
and records elapsed time, root/window coordinates, child window, button/modifier
mask, and the X11 same-screen result. It does not inject or select input events.

The run will retain:

- the exact helper and APK SHA-256 values;
- the fresh launcher, client, D-Bus, and Steam logs;
- the pointer-probe output and the timing of the Android tap;
- before/after Android screenshots and focused-window dumps;
- the X11 window tree and any discovered Steam window identity; and
- exact stop, rootfs D-Bus cleanup, and residual-process results.

## Acceptance and interpretation

This experiment passes only as an instrumentation run if the helper completes
with a fresh `nova_x11_pointer_probe=pass` marker and the session teardown
passes. The pointer result is interpreted separately:

- no coordinate change: investigate Android/Termux:X11 pointer forwarding;
- a change to an unexpected coordinate: derive one coordinate transformation
  and repeat with that single variable changed; or
- a change to the expected Steam target: investigate X11 focus, button
  delivery, or Steam/CEF handling rather than changing presentation code.

A pointer movement alone is not evidence that Steam navigation succeeded. The
result document must correlate the pointer samples with the screenshots and
must state whether the selected Steam tab actually changed.

## Out of scope

This run does not change Gamescope, AHardwareBuffer, Vulkan WSI, Steam input,
audio buffering, network setup, or the product APK architecture. It is a
diagnostic bridge experiment intended to identify the next smallest fix for
touchscreen input on the currently working direct-display path.
