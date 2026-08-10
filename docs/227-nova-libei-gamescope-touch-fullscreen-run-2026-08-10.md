# Nova libei-enabled Gamescope touch/fullscreen run — 2026-08-10

Status: predeclared; no device session has been launched under this run.

## Question

Does the freshly rebuilt, explicitly deployed libei-enabled Gamescope binary close
the input gap seen in run 223 while retaining the native ARM64 Steam and 1280×960
AHardwareBuffer presentation path?

This is a bounded transport/presentation run. A successful result proves Android
touch reaches Gamescope through libei and that Steam remains visible; it does not by
itself prove touch-driven Steam navigation, hardware CEF rendering, audio, or product
APK promotion.

## Run identity and fixed inputs

- Device: Retroid Pocket Nova, `kalama`, ADB serial `675a2365`.
- Run ID: `gamescope-libei-touch-fullscreen-20260810T065012Z`.
- Run directory:
  `android/nova-lab/build/runs/gamescope-libei-touch-fullscreen-20260810T065012Z`.
- Gamescope binary:
  `android/nova-lab/build/gamescope-headless-libei-build-v2/src/gamescope`.
- Expected Gamescope SHA-256:
  `cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca`.
- Gamescope source: `/Users/kurt/Developer/gamescope-valve`, commit
  `fb9f84ee247a1f02b1a132da60e94585db84bf61`, checked-in patch stack, libei enabled.
- Output: `NOVA_FULLSCREEN_PRESENTATION=1`, `1280x960`, three AHB buffers,
  `NOVA_GAMESCOPE_AHB_REQUIRE_TARGET=0`.
- Input: Android touch tap `(1100,100)` → app socket → ARM64 libei helper →
  Gamescope EIS; the separate physical controller run remains pending.
- Steam client: native ARM64 Gamepad UI, software GL in the client, no claim of
  hardware CEF acceleration.

## Acceptance gates

Require a fresh preflight and all of the following:

1. metadata records the expected binary SHA-256 and `gamescope_libei_build=enabled`;
2. `headless_gamescope_ahb=pass` and `native_steam_smoke=pass` in the same run;
3. `android_touch_socket_connected=pass`, libei device-resumed/down/up/probe
   markers, and a Gamescope `EIS touch event` marker;
4. a current-run `1280x960` Steam surface is visible; and
5. exact cleanup leaves no matching runtime process, mount, socket, or app bridge
   file.

The run must fail closed if the metadata reports the old disabled binary or if the
Gamescope report contains `Gamescope built without libei` or `No touch support yet`.

## Planned command

```sh
NOVA_RUN_ID=gamescope-libei-touch-fullscreen-20260810T065012Z \
NOVA_RUN_DIR=android/nova-lab/build/runs/gamescope-libei-touch-fullscreen-20260810T065012Z \
NOVA_GAMESCOPE_HEADLESS=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/gamescope-headless-libei-build-v2/src/gamescope \
GAMESCOPE_HEADLESS_SOURCE=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/gamescope-headless-libei-source-v2 \
NOVA_FULLSCREEN_PRESENTATION=1 NOVA_FULLSCREEN_WIDTH=1280 NOVA_FULLSCREEN_HEIGHT=960 \
NOVA_AHB_WIDTH=1280 NOVA_AHB_HEIGHT=960 NOVA_AHB_FRAME_COUNT=120 \
NOVA_TOUCH_REQUIRE_STEAM_SURFACE=1 NOVA_TOUCH_REQUIRE_VISUAL_CHANGE=0 \
NOVA_TOUCH_WAIT_TIMEOUT=150 NOVA_TOUCH_SETTLE_DELAY=20 NOVA_TOUCH_AFTER_DELAY=8 \
NOVA_STEAM_CLIENT_TIMEOUT=180 NOVA_STEAM_GAMESCOPE_TIMEOUT=220 \
  android/nova-lab/deploy-native-steam-touch-input-smoke-test.sh
```
