# Nova optimal-tiling Steam-surface experiment — 2026-08-09

Status: completed; see [the valid device result](110-nova-optimal-tiling-steam-surface-result-2026-08-09.md).

## Question

The output-tiling A/B in [doc 108](108-nova-ahb-output-tiling-ab-result-2026-08-09.md)
changed the Android pre-marker AHardwareBuffer from all zero to nonzero
diagnostic content, but did not produce frame-variable Steam pixels. This run
asks whether the same `VK_IMAGE_TILING_OPTIMAL` mode is sufficient for the
full native Steam/Xwayland session to become visible in the end-user Android
surface at native 1280×960, with a frame-correlated screenshot and a working
Android gamepad event.

## One-variable presentation change

Keep the current tracked Gamescope patch stack, Android APK, Steam/Xwayland
profile, valid-content cadence, three-buffer AHB protocol, SurfaceControl
geometry, frame marker, input mapping, timeout split, settled X11 capture, and
cleanup contract fixed. Change only:

```text
NOVA_AHB_OUTPUT_TILING=optimal
```

The linear mode remains the control/default elsewhere. This run uses the
current libei-enabled binary and records its exact path, SHA-256, source
commit, patch-stack hashes, and APK hash in the fresh run manifest.

## Run contract

```text
run_id=controller-ui-20260809T-optimal-tiling-steam-1280x960
profile=controller-ui-optimal-tiling-steam-1280x960
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
gamescope=/tmp/nova-gamescope-ahb-tiling-libei-20260809-out/src/gamescope
gamescope_sha256=29c62f0b19aee09e111909cf6bee0c3df8b306380d93e133a1affa22b83bcfc0
fullscreen_presentation=1
fullscreen=1280x960
ahb_buffer=1280x960
ahb_usage=0x333
ahb_frames=240
NOVA_AHB_OUTPUT_TILING=optimal
NOVA_AHB_FRAME_IDENTITY=1
NOVA_AHB_FRAME_MARKER=1
NOVA_AHB_CONTENT_PROBE=1
NOVA_AHB_TRACE=1
NOVA_AHB_SOCKET_TRACE=1
NOVA_AHB_SCHEDULER_TRACE=1
NOVA_AHB_ACK_POLL_TIMEOUT_MS=0
NOVA_STEAM_CLIENT_TIMEOUT=180
NOVA_STEAM_GAMESCOPE_TIMEOUT=300
NOVA_CONTROLLER_UI_WAIT_TIMEOUT=240
NOVA_CONTROLLER_UI_SETTLE_DELAY=30
NOVA_CONTROLLER_UI_INPUT_MODE=android-keyevent
NOVA_CONTROLLER_UI_ANDROID_KEYCODE=96
NOVA_CONTROLLER_UI_ANDROID_KEY_NAME=KEYCODE_BUTTON_A
NOVA_CONTROLLER_UI_EVENT_CODE=304
NOVA_CONTROLLER_UI_EVENT_NAME=BTN_SOUTH
NOVA_CONTROLLER_UI_X11_CAPTURE=1
NOVA_CONTROLLER_UI_X11_CAPTURE_AFTER_SETTLE=1
NOVA_CONTROLLER_UI_OVERLAY_GUARD=1
NOVA_CONTROLLER_UI_EXPECT_NAVIGATION=1
```

The session retains the established software CEF/GL profile (`swrast`,
`softpipe`) so hardware-accelerated graphics is not silently mixed into this
presentation experiment. Networking, audio, touchscreen, hardware GL, and
standalone-app acceptance remain downstream gates.

Before launch, run the exact-scope Nova cleanup helper, force-stop the test
APK, clear app-owned sockets/reports, and verify no matching process remains.
Readiness must use fresh Steam log baselines from this run. On every exit,
capture, interruption, or manual stop, run the same cleanup and the explicit
post-stop verifier.

## Acceptance gate

Accept the Android presentation and gamepad-navigation boundary only if the
same run records all of the following:

```text
controller_ui_ready=1
controller_ui_surface=pass
controller_ui_steam_surface=pass
controller_ui_navigation=pass
controller_ui_android_input_bridge=pass
ahb_double_buffer_frames=240 releases=239
ahb_frame_marker_capture=pass frame=239
native_steam_smoke=pass
post_stop_verification=pass
```

The native-resolution Android screenshot must visibly contain the fresh Steam
surface and correlate to the producer frame marker. The settled X11 capture
must independently show the same Steam scene. A successful AHB frame count,
ACK/fence sequence, X11-only screenshot, or stable green-line diagnostic
pattern is not sufficient.

## Decision branches

- If the optimal AHB is nonzero and frame-variable, the Android screenshot is
  native-resolution Steam UI, the marker correlates, and A-button navigation
  changes the Steam panel, record the presentation/gamepad gate as passed and
  move to touchscreen, login/network, audio, hardware-GL, and standalone-app
  gates in that order.
- If the AHB remains nonzero but stable diagnostic content while settled X11
  remains Steam UI, retain the lower-level tiling result and inspect the
  Gamescope output write/transition and Android SurfaceControl content path.
- If the AHB is zero or the optimal import fails, retain the exact Vulkan log
  and reject optimal as an end-user fix; do not advance to input or login.
- If setup, provenance, fresh readiness, or cleanup fails, mark the run
  invalid rather than interpreting it as a presentation result.
