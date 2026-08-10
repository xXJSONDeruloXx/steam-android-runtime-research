# Nova libei-enabled Gamescope touch/fullscreen retry — 2026-08-10

Status: predeclared; this run exists to verify the preflight retry repair before
evaluating touch, AHardwareBuffer presentation, or Steam visibility.

## Question

Does the same explicit libei-enabled Gamescope artifact pass the device harness
after a transient first-attempt cleanup failure, allowing the actual 1280×960
touch/fullscreen test to run?

This is a retry-harness verification run. It is not a product-APK acceptance
run and does not claim gamepad navigation, audio, network control UI, or hardware
CEF acceleration.

## Fixed run identity and inputs

- Device: Retroid Pocket Nova, `kalama`, ADB serial `675a2365`.
- Run ID: `gamescope-libei-touch-fullscreen-retry-20260810T065557Z`.
- Run directory:
  `android/nova-lab/build/runs/gamescope-libei-touch-fullscreen-retry-20260810T065557Z`.
- Harness fix commit: `2c877e7`.
- Gamescope source commit: `fb9f84ee247a1f02b1a132da60e94585db84bf61`.
- Gamescope binary:
  `android/nova-lab/build/gamescope-headless-libei-build-v2/src/gamescope`.
- Expected Gamescope SHA-256:
  `cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca`.
- AHB output: `1280x960`, three buffers, linear output tiling.
- Android presentation: fullscreen mode enabled, Vulkan layout usage `0x333`.
- Input path: Android touch socket → ARM64 libei helper → Gamescope EIS.
- Steam client: native ARM64 Steam/Gamepad UI; software GL remains explicit in
  this path and no hardware-CEF claim is permitted.

## Acceptance gates

The run must record:

1. the expected Gamescope SHA-256 and `gamescope_libei_build=enabled`;
2. `preflight_manifest=pass`, including the retry-state result;
3. fresh Gamescope/AHB frames and a live Steam surface in the same run;
4. Android touch socket, libei seat/device/resume, touch event, and any
   touch-driven Steam surface evidence; and
5. exact cleanup with no matching Nova process, mount, socket, or app bridge
   file.

If preflight fails again, the run must stop before launch and document the exact
gate instead of interpreting a stale or partial display as a compositor result.

## Planned command

```sh
NOVA_RUN_ID=gamescope-libei-touch-fullscreen-retry-20260810T065557Z \
NOVA_RUN_DIR=android/nova-lab/build/runs/gamescope-libei-touch-fullscreen-retry-20260810T065557Z \
NOVA_GAMESCOPE_HEADLESS=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/gamescope-headless-libei-build-v2/src/gamescope \
GAMESCOPE_HEADLESS_SOURCE=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/gamescope-headless-libei-source-v2 \
NOVA_FULLSCREEN_PRESENTATION=1 NOVA_FULLSCREEN_WIDTH=1280 NOVA_FULLSCREEN_HEIGHT=960 \
NOVA_AHB_WIDTH=1280 NOVA_AHB_HEIGHT=960 NOVA_AHB_FRAME_COUNT=120 \
NOVA_TOUCH_REQUIRE_STEAM_SURFACE=1 NOVA_TOUCH_REQUIRE_VISUAL_CHANGE=0 \
NOVA_TOUCH_WAIT_TIMEOUT=150 NOVA_TOUCH_SETTLE_DELAY=20 NOVA_TOUCH_AFTER_DELAY=8 \
NOVA_STEAM_CLIENT_TIMEOUT=180 NOVA_STEAM_GAMESCOPE_TIMEOUT=220 \
  android/nova-lab/deploy-native-steam-touch-input-smoke-test.sh
```
