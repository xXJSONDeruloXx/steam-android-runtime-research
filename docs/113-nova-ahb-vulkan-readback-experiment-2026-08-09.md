# Nova Vulkan AHardwareBuffer readback experiment — 2026-08-09

Status: completed; the first device invocation was invalid because the native
Steam control-script variant did not propagate the opt-in readback variables;
see [the invalid-run result](114-nova-ahb-vulkan-readback-result-2026-08-09.md).

## Question

The optimal-tiling run in [doc 110](110-nova-optimal-tiling-steam-surface-result-2026-08-09.md)
produced a native Steam scene in settled X11 but only the green diagnostic
surface in the Android screenshot. The raw AHardwareBuffer snapshot in
[doc 112](112-nova-ahb-raw-snapshot-result-2026-08-09.md) also contained the
green diagnostic pattern. This run adds one bounded Gamescope-side Vulkan
readback of the imported output image after composition and compares its
logical RGBA8 FNV-1a checksum with the APK's same-frame raw AHardwareBuffer
capture.

The readback is opt-in and runs only for frame 239. It copies the selected
external output image into Gamescope's host-visible upload buffer after the
composition wait, hashes tightly packed logical RGBA rows, and records the
dimensions, byte count, per-channel extrema, and first/center/last pixels.
The Android probe captures the same buffer before its marker write. Neither
instrument changes the normal readback-disabled path.

## One-variable diagnostic change

Keep the 1280×960 optimal-tiling Steam/Xwayland session, software CEF/GL
profile, AHB protocol, frame identity/marker/content probes, settled X11
capture, input mapping, timeout split, and lifecycle cleanup fixed. Enable only
the new producer-side readback and the already-established raw capture at the
same frame:

```text
NOVA_AHB_VULKAN_READBACK=1
NOVA_AHB_VULKAN_READBACK_FRAME=239
NOVA_AHB_RAW_CAPTURE=1
NOVA_AHB_RAW_CAPTURE_FRAME=239
```

The readback build was compiled successfully before this predeclaration. Its
source tree contains the full tracked Gamescope patch stack, so the source is
intentionally dirty; the exact status, diff, and submodule fingerprints below
are part of the run provenance.

## Run contract

```text
predeclared_utc=2026-08-09T13:45:28Z
run_id=controller-ui-20260809T134528Z-vulkan-readback-1280x960
profile=controller-ui-vulkan-readback-1280x960
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
gamescope_binary=/tmp/nova-gamescope-ahb-vulkan-readback-202609-out2/src/gamescope
gamescope_binary_sha256=12a19e022aad45ae3468530a9ea9ed79a2d8f404ce8649457733aa5fc53b5308
gamescope_libei_build=required
gamescope_input_emulation=enabled
gamescope_source_tree=/tmp/nova-gamescope-ahb-vulkan-readback-source2-20260809
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
gamescope_source_dirty=1
gamescope_source_status_sha256=d9b8c97ca8b3bfbbde55efd827ddce8472c5354594f56e41818a1420a2f6806c
gamescope_source_diff_sha256=a42cbbdbfcf24bbd08a7bfe8689ebbc8306f3b384c0b3fe7f252d2ce88a46af9
gamescope_source_submodules_sha256=b88eda83c6a88296d83d675ec0abae0dde5dec66901ebea4827844c857f8c0ed
nova_apk=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/nova-lab-debug.apk
nova_apk_sha256_predeploy=916a059cb884ddd09dd3583ff793e55a2bdb97588d7850e3f53416eb17c95ff2
fullscreen_presentation=1
fullscreen=1280x960
ahb_buffer=1280x960
ahb_usage=0x333
ahb_frames=240
NOVA_AHB_OUTPUT_TILING=optimal
NOVA_AHB_VULKAN_READBACK=1
NOVA_AHB_VULKAN_READBACK_FRAME=239
NOVA_AHB_RAW_CAPTURE=1
NOVA_AHB_RAW_CAPTURE_FRAME=239
NOVA_AHB_FRAME_IDENTITY=1
NOVA_AHB_FRAME_MARKER=1
NOVA_AHB_CONTENT_PROBE=1
NOVA_AHB_TRACE=1
NOVA_AHB_SOCKET_TRACE=1
NOVA_AHB_SCHEDULER_TRACE=1
NOVA_AHB_ACK_POLL_TIMEOUT_MS=0
NOVA_CAPTURE_PRESENTATION_DIAGNOSTICS=1
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
NOVA_CONTROLLER_UI_REQUIRE_STEAM_SURFACE=1
NOVA_STEAM_CLIENT_TIMEOUT=180
NOVA_STEAM_GAMESCOPE_TIMEOUT=300
NOVA_STEAM_BOOTSTRAP_MODE=skip
NOVA_STEAM_PRELOAD_PROFILE=sysv
NOVA_STEAM_MESA_DRIVER=swrast
NOVA_STEAM_GALLIUM_DRIVER=softpipe
NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE=1
NOVA_STEAM_NO_CEF_SANDBOX=1
NOVA_GAMESCOPE_AHB_SKIP_WAYLAND=1
NOVA_GAMESCOPE_AHB_SKIP_WAYLAND_SHM=1
NOVA_GAMESCOPE_AHB_XWAYLAND=1
INSTALL_HOLO_GAMESCOPE=0
```

The fresh run directory is:

```text
/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/manual-runs/controller-ui-20260809T134528Z-vulkan-readback-1280x960/
```

The invocation must use `env -u NOVA_FORCE_GPU_COMPOSITION` so no inherited
composition override is mistaken for an explicit experiment variable. The
full command is:

```sh
env -u NOVA_FORCE_GPU_COMPOSITION \
  ADB=/Users/kurt/.local/bin/adb \
  GAMESCOPE_HEADLESS_SOURCE=/tmp/nova-gamescope-ahb-vulkan-readback-source2-20260809 \
  NOVA_GAMESCOPE_HEADLESS=/tmp/nova-gamescope-ahb-vulkan-readback-202609-out2/src/gamescope \
  NOVA_RUN_ID=controller-ui-20260809T134528Z-vulkan-readback-1280x960 \
  NOVA_RUN_PROFILE=controller-ui-vulkan-readback-1280x960 \
  NOVA_RUN_DIR=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/manual-runs/controller-ui-20260809T134528Z-vulkan-readback-1280x960 \
  NOVA_REQUIRE_RUN_MANIFEST=1 NOVA_REQUIRE_GAMESCOPE_PROVENANCE=1 \
  NOVA_REQUIRE_GAMESCOPE_LIBEI=1 NOVA_GAMESCOPE_INPUT_EMULATION=enabled \
  NOVA_AHB_FRAME_COUNT=240 NOVA_AHB_WIDTH=1280 NOVA_AHB_HEIGHT=960 \
  NOVA_FULLSCREEN_PRESENTATION=1 NOVA_FULLSCREEN_WIDTH=1280 NOVA_FULLSCREEN_HEIGHT=960 \
  NOVA_AHB_OUTPUT_TILING=optimal NOVA_AHB_VULKAN_READBACK=1 \
  NOVA_AHB_VULKAN_READBACK_FRAME=239 NOVA_AHB_RAW_CAPTURE=1 \
  NOVA_AHB_RAW_CAPTURE_FRAME=239 NOVA_AHB_FRAME_IDENTITY=1 \
  NOVA_AHB_FRAME_MARKER=1 NOVA_AHB_CONTENT_PROBE=1 NOVA_AHB_TRACE=1 \
  NOVA_AHB_SOCKET_TRACE=1 NOVA_AHB_SCHEDULER_TRACE=1 \
  NOVA_AHB_ACK_POLL_TIMEOUT_MS=0 NOVA_CAPTURE_PRESENTATION_DIAGNOSTICS=1 \
  NOVA_CONTROLLER_UI_WAIT_TIMEOUT=240 NOVA_CONTROLLER_UI_SETTLE_DELAY=30 \
  NOVA_CONTROLLER_UI_INPUT_MODE=android-keyevent \
  NOVA_CONTROLLER_UI_ANDROID_KEYCODE=96 NOVA_CONTROLLER_UI_ANDROID_KEY_NAME=KEYCODE_BUTTON_A \
  NOVA_CONTROLLER_UI_EVENT_CODE=304 NOVA_CONTROLLER_UI_EVENT_NAME=BTN_SOUTH \
  NOVA_CONTROLLER_UI_X11_CAPTURE=1 NOVA_CONTROLLER_UI_X11_CAPTURE_AFTER_SETTLE=1 \
  NOVA_CONTROLLER_UI_OVERLAY_GUARD=1 NOVA_CONTROLLER_UI_EXPECT_NAVIGATION=1 \
  NOVA_CONTROLLER_UI_REQUIRE_STEAM_SURFACE=1 NOVA_STEAM_CLIENT_TIMEOUT=180 \
  NOVA_STEAM_GAMESCOPE_TIMEOUT=300 NOVA_STEAM_BOOTSTRAP_MODE=skip \
  NOVA_STEAM_PRELOAD_PROFILE=sysv NOVA_STEAM_MESA_DRIVER=swrast \
  NOVA_STEAM_GALLIUM_DRIVER=softpipe NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE=1 \
  NOVA_STEAM_NO_CEF_SANDBOX=1 NOVA_GAMESCOPE_AHB_SKIP_WAYLAND=1 \
  NOVA_GAMESCOPE_AHB_SKIP_WAYLAND_SHM=1 NOVA_GAMESCOPE_AHB_XWAYLAND=1 \
  INSTALL_HOLO_GAMESCOPE=0 \
  android/nova-lab/deploy-native-steam-controller-ui-input-smoke-test.sh
```

The lifecycle contract in [doc 34](34-nova-runtime-harness-lifecycle.md)
must be read in full immediately before launch. The exact-scope cleanup helper
must run before launch and on every exit; the explicit post-stop verifier is
required after teardown. A missing Android Steam surface intentionally prevents
the key event from being sent, even though the outer controller wrapper then
returns a strict-gate failure. Lower-level report lines and the post-stop
verifier remain authoritative for this diagnostic.

## Acceptance gate

The diagnostic is valid only if one fresh run records all of the following:

```text
android_ahb_vulkan_readback_239=pass
ahb_double_buffer_raw_capture_239=pass
ahb_raw_capture=pass frame=239 bytes=4915200
nova_ahb_raw_decode=pass
ahb_double_buffer_frames=240 releases=239
native_steam_smoke=pass
post_stop_verification=pass
```

The Gamescope readback must report a 1280×960, 4,915,200-byte logical RGBA
image. The result document must record both FNV-1a values, SHA-256 hashes for
the retained raw/decoded/X11/Android artifacts, the complete run manifest, and
the explicit cleanup result. This experiment does not claim Android
presentation, gamepad navigation, touchscreen input, login, networking,
audio, hardware acceleration, or standalone-app acceptance.

## Decision branches

- If the Gamescope Vulkan readback FNV-1a value equals the APK raw-capture
  value and both are the green pattern, the Vulkan and CPU AHB views agree;
  investigate external-image write/format/stride/layout/synchronization and
  then SurfaceControl/HWC with a more discriminating producer pattern.
- If the Gamescope readback contains Steam or otherwise differs materially
  from the green raw capture, the Vulkan view has the scene while the CPU/HWC
  representation is wrong; focus on image export, cache visibility, physical
  tiling, or Android consumer synchronization.
- If the readback fails, retain the exact Vulkan transfer/import failure and
  diagnose transfer support or image-layout transitions before changing the
  Android consumer.
- If provenance, fresh readiness, raw correlation, or cleanup fails, reject
  the run as invalid and do not advance to input or login.
