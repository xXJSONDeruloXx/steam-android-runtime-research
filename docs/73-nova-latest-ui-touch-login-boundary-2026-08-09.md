# Nova latest Steam UI, touch, and login boundary — 2026-08-09

Device: Retroid Pocket Nova, Snapdragon `kalama`, Adreno 740

ADB serial: `675a2365`

This checkpoint records the first fresh validation after removing the global
Gamescope repaint trigger. It separates the accepted software Steam UI/input
path from the still-unresolved event-driven AHardwareBuffer presentation and
end-user product gates.

## Fresh bounded controller run

Run:
`android/nova-lab/build/manual-runs/controller-20260809T052828Z-current/`

The run used the no-global-repaint Gamescope artifact:

```text
gamescope=android/nova-lab/build/gamescope-headless-build-repaintfix-no-vblank-libei/src/gamescope
gamescope_sha256=fd86ba1d81f502d7ef05b17ef150193926e91008538185cccfe9473557aa7325
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
apk_sha256=123289f01bd778a05cfd0581c0db9410ef5dd76c9f81ba07d9da347bddf3f45e
fullscreen=1280x960
ahb=960x540
input=android-keyevent KEYCODE_DPAD_DOWN -> BTN_DPAD_DOWN
cef=software
```

The strict run passed the fullscreen surface and Steam panel gates, changed
the navigation crop after the D-pad event, observed Android press/release
dispatch, found Steam holding the virtual event-node FD, and completed exact
runtime and app-file cleanup. The AHB report reached frame 120 and its target
marker. The trigger-enabled artifact from `335c600` still fails the Android
surface gate, so the no-trigger result remains the retained implementation.

The authoritative metadata and report are kept in the run directory rather
than inferred from the global build logs.

## Fresh manual touch/OOBE run

Run:
`android/nova-lab/build/manual-runs/manual-20260809T053357Z-touch-timeout-fix/`

This run used the same no-trigger Gamescope stack with a continuous AHB window,
1280x960 fullscreen presentation, Android touch plus key input, and
`NOVA_EIS_TOUCH_TIMEOUT=900000` milliseconds. The touch bridge reached
Gamescope with EIS touchdown/motion/up events and advanced the visible OOBE
flow through language, timezone, and network interactions. The same-run X11
window capture was successful.

The timeout value exposed a harness bug: the libei helper accepts milliseconds,
while the outer `/usr/bin/timeout` command accepts seconds. The manual default
and bounded validation now use milliseconds, while the Gamescope wrapper
converts only the outer timeout to seconds. The previous 900-millisecond
default could terminate the helper before the first real touch event.

## Login and presentation boundary

The fresh Steam log recorded:

```text
SetOOBEComplete
OOBE Stage 2: completed
No restart requested
Login: OnLoginStateChange  1 1 0 0
```

That proves the updater shim and Nova-only OOBE completion path reached the
client's login-state transition. It does not prove that the Android user saw
the corresponding login surface. After the network interaction, the Android
capture remained on the network page. A same-run X11 capture of the mapped
`Steam Big Picture Mode` window showed the live Steam Internet settings page.
The two images therefore disagree downstream of the live Steam/Xwayland state.

This is a presentation-state failure, not evidence that the touch socket or
Steam network reachability failed. Login acceptance must wait for a frame
identity or visual-checksum correlation between the live X11/Gamescope output
and the Android AHB/SurfaceControl image.

## Quiet-scene AHB behavior

The manual run intentionally removed the global repaint trigger. Once the
scene became quiet, the test-bench producer waited for another release and the
bounded app report could not write its normal final marker. On teardown,
Gamescope reported the expected release-message wait boundary. This is a
test-bench lifetime mismatch with event-driven presentation; restoring a
global repaint would reintroduce the already-rejected dark-surface regression.

The product-facing presenter therefore needs to retain the last displayed AHB
buffer and wait for explicit new-frame or shutdown events, rather than treating
the absence of another repaint as a failed frame loop.

## Remaining gates

The accepted profile still uses software CEF. Sound has no accepted Linux
audio-server path: the rootfs `pactl` client has no reachable server and the
recorded Steam webhelper diagnostics report missing ALSA `default` devices.
The native `msm` and explicit `freedreno` hardware-GL probes remain negative.
The diagnostic `MainActivity` is not yet the independent end-user launcher.

The next implementation checkpoint is the event-driven AHB presenter and its
frame-identity acceptance test, followed by an Android audio bridge, native
hardware-GL isolation, and the standalone fullscreen launcher.
