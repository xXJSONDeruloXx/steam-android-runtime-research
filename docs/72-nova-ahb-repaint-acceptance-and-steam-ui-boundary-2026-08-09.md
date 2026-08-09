# Nova AHB repaint A/B and Steam UI acceptance — 2026-08-09

Device: Retroid Pocket Nova, Snapdragon `kalama`, Adreno 740

ADB serial: `675a2365`

This document resolves the current repaint question against the exact
Gamescope source and patch stack. The six-line global `hasRepaint` trigger
from commit `335c600` is not retained: it is unnecessary for the current AHB
transport and regresses the Android presentation surface.

## A/B artifacts

Both artifacts use Gamescope source commit
`fb9f84ee247a1f02b1a132da60e94585db84bf61`, the same headless, AHB transport,
clock-trace, and libei patches, and ARM64 debug builds. The trigger-enabled
artifact is:

```text
gamescope=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/gamescope-headless-build-repaintfix-reportcap-libei/src/gamescope
gamescope_sha256=ed45595515e34e80ff10fd92d492d14d75f1f9cde8bf2aa224e835ada491aa7e
```

The exact-stack no-trigger artifact is:

```text
gamescope=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/gamescope-headless-build-repaintfix-no-vblank-libei/src/gamescope
gamescope_sha256=fd86ba1d81f502d7ef05b17ef150193926e91008538185cccfe9473557aa7325
gamescope_source=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/gamescope-headless-source-repaintfix-no-vblank
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
```

The no-trigger source snapshot differs from the trigger-enabled source only
by the six-line `steamcompmgr.cpp` hunk. The test-bench APK also contains the
report-capacity repair in `ahbbridge.c` so bounded reports retain their final
summary.

## AHB-only result

Run: `ahb-only-20260809T043714Z-no-vblank`
Artifacts:
`android/nova-lab/build/manual-runs/ahb-only-20260809T043714Z-no-vblank/`

```text
ahb_double_buffer_frames=240 releases=239
ahb_double_buffer=pass
android_ahb_composite_frame=240
android_ahb_target_reached=240
headless_gamescope_ahb=pass
headless_ahb_residual_processes=pass
nova_app_runtime_files_cleanup=pass
```

This disproves the need for the global repaint trigger in the current
transport stack; removing it does not reproduce the old frame-149 stall.

## Full Steam/controller result

Run: `controller-20260809T043310Z-no-vblank-reportfix`
Artifacts:
`android/nova-lab/build/manual-runs/controller-20260809T043310Z-no-vblank-reportfix/`

The profile used 1280x960 fullscreen presentation, fresh Steam log baselines,
Xwayland, software CEF diagnostics, Android key-only input bridging, and
blocking AHB ACK waits. It passed:

```text
controller_ui_surface=pass
controller_ui_steam_surface=pass
controller_ui_surface_yhigh=48
controller_ui_navigation=pass
controller_ui_android_input_marker=press_release
controller_ui_android_input_bridge=pass
steam_input_fd_probe=pass
native_steam_smoke=pass
native_steam_controller_ui_input_smoke=pass
native_steam_runtime_cleanup=pass
controller_ui_app_files_cleanup=pass
```

The before/after screenshots have SHA-256 values
`58f29a0b583d747ed3fe6e7f3e7ae2a0a14186e0fb632c55cfa2ec823f23befd` and
`69e42ce0986f81678201e19f60594f9be11a873cd58de09f856fc1819a6513ac`.
The navigation crop changed after `KEYCODE_DPAD_DOWN`, while the strict Steam
panel statistics remained valid.

The trigger-enabled artifact passed the AHB ring but failed the same Android
surface gate. In the corresponding X11 diagnostic run, the Steam window was
visible and the SurfaceFlinger AHB layer was active while Android capture was
dark. This localizes the regression to the forced global repaint behavior,
not Steam launch, Xwayland readiness, SurfaceControl layer creation, or input
forwarding.

## Harness repair

The controller test previously checked `files/android-input-bridge-report.txt`
after the nested bounded deploy had already removed it during required
cleanup. The deploy now snapshots that report into the run directory before
cleanup, and the controller test consumes that run-scoped artifact. This is
why the second no-trigger controller run is fully green rather than relying
on relay logs alone.

## Remaining product gates

This resolves only the repaint/transport/UI comparison. The end-user target
still requires a fresh acceptance of the login screen in the final launcher
profile, touchscreen input, networking, sound, hardware-accelerated Vulkan/
CEF, and an independent fullscreen launcher application alongside the test
bench APK. The current controller profile intentionally uses software CEF and
therefore does not satisfy the hardware-acceleration requirement.
