# Nova Vulkan AHardwareBuffer readback rerun — 2026-08-09

Status: completed; see [the Vulkan/raw comparison result](116-nova-ahb-vulkan-readback-rerun-result-2026-08-09.md).

## Purpose

The first invocation in [doc 114](114-nova-ahb-vulkan-readback-result-2026-08-09.md)
was invalid because the native Steam control-script variant did not export the
opt-in Vulkan readback variables. Commit `65a2786` fixes that exact alternate
path. This rerun repeats the same producer/raw comparison with a fresh run
identity and no presentation-variable changes.

## Fixed contract

The 1280×960 optimal-tiling Steam/Xwayland session, software CEF/GL profile,
three-buffer AHB protocol, frame identity/marker/content probes, raw capture,
settled X11 capture, input mapping, timeouts, and lifecycle cleanup remain
fixed. The selected Gamescope binary is unchanged; only the already-committed
native-Steam control-script propagation fix is now included.

```text
predeclared_utc=2026-08-09T13:57:26Z
run_id=controller-ui-20260809T135726Z-vulkan-readback-rerun-1280x960
profile=controller-ui-vulkan-readback-rerun-1280x960
repo_commit=45644d3
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
gamescope_binary=/tmp/nova-gamescope-ahb-vulkan-readback-202609-out2/src/gamescope
gamescope_binary_sha256=12a19e022aad45ae3468530a9ea9ed79a2d8f404ce8649457733aa5fc53b5308
gamescope_libei_build=required
gamescope_input_emulation=enabled
gamescope_source_tree=/tmp/nova-gamescope-ahb-vulkan-readback-source2-20260809
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
gamescope_source_dirty=1
gamescope_source_status_sha256=d8554a591ad45ff80921c48b581bb32857b4e365c978e1b963002ab242c306d3
gamescope_source_diff_sha256=a42cbbdbfcf24bbd08a7bfe8689ebbc8306f3b384c0b3fe7f252d2ce88a46af9
gamescope_source_submodules_sha256=ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
nova_apk=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/nova-lab-debug.apk
nova_apk_sha256_predeploy=255db3949ef690c489f184ee7a2d2d141ab6b4ffd44fa5772ac2ef54f5e637b8
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

Fresh artifacts must go under:

```text
/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/manual-runs/controller-ui-20260809T135726Z-vulkan-readback-rerun-1280x960/
```

Use `env -u NOVA_FORCE_GPU_COMPOSITION` and the following exact invocation
(with the fixed run identity above):

```sh
env -u NOVA_FORCE_GPU_COMPOSITION \
  ADB=/Users/kurt/.local/bin/adb \
  GAMESCOPE_HEADLESS_SOURCE=/tmp/nova-gamescope-ahb-vulkan-readback-source2-20260809 \
  NOVA_GAMESCOPE_HEADLESS=/tmp/nova-gamescope-ahb-vulkan-readback-202609-out2/src/gamescope \
  NOVA_RUN_ID=controller-ui-20260809T135726Z-vulkan-readback-rerun-1280x960 \
  NOVA_RUN_PROFILE=controller-ui-vulkan-readback-rerun-1280x960 \
  NOVA_RUN_DIR=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/manual-runs/controller-ui-20260809T135726Z-vulkan-readback-rerun-1280x960 \
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

Read [the full lifecycle contract](34-nova-runtime-harness-lifecycle.md)
immediately before launch. The exact-scope cleanup helper must run before and
after the run, and the explicit post-stop verifier is mandatory. A missing
Android surface still suppresses the key event; it must not invalidate the
lower-level readback/raw comparison if the bounded report and cleanup pass.

## Acceptance gate

The rerun is valid only if it records:

```text
android_ahb_vulkan_readback_239=pass
ahb_double_buffer_raw_capture_239=pass
ahb_raw_capture=pass frame=239 bytes=4915200
nova_ahb_raw_decode=pass
ahb_double_buffer_frames=240 releases=239
native_steam_smoke=pass
post_stop_verification=pass
```

The Vulkan line must report a 1280×960, 4,915,200-byte logical RGBA image and
an FNV-1a checksum. Compare it directly with the APK raw-capture checksum and
retain SHA-256 hashes for both raw/decoded artifacts, the Android screenshot,
settled X11 capture, reports, metadata, and post-stop verifier. This rerun
does not claim Android presentation, input, login, networking, audio,
hardware acceleration, or standalone-app acceptance unless those separate
gates also pass.
