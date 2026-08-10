# Nova runtime cleanup process diagnostic — 2026-08-10

Status: predeclared; this run is limited to identifying the process that makes
the exact Nova cleanup helper fail during Gamescope/AHB preflight.

## Question

When `nova-runtime-cleanup.sh` reports a matching PID after its three TERM/KILL
cycles, what are the process arguments at the TERM, KILL, and residual checkpoints?
The answer will distinguish a real runtime respawn from a short-lived wrapper or
an over-broad process matcher.

This run must stop at preflight. It is not a Gamescope, Steam, AHB, touch, game,
network, audio, or product-APK acceptance run.

## Fixed run identity and inputs

- Device: Retroid Pocket Nova, `kalama`, ADB serial `675a2365`.
- Run ID: `nova-runtime-cleanup-process-diagnostic-20260810T065951Z`.
- Run directory:
  `android/nova-lab/build/runs/nova-runtime-cleanup-process-diagnostic-20260810T065951Z`.
- Existing preflight retry repair: `2c877e7`.
- Gamescope source commit: `fb9f84ee247a1f02b1a132da60e94585db84bf61`.
- Explicit Gamescope SHA-256:
  `cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca`.
- AHB output: `1280x960`, fullscreen presentation enabled.
- Input setup: Android touch socket and libei helper enabled, but no touch event
  is valid unless the nested preflight passes and a compositor is actually run.

## Diagnostic acceptance gates

1. The metadata must record the expected binary and `gamescope_libei_build=enabled`.
2. The preflight must preserve the exact cleanup result and include process
   argument snapshots for every non-empty TERM/KILL/residual PID list.
3. A failed cleanup must remain fail-closed even if a later external audit sees
   no residual process.
4. The final outer cleanup and device audit must leave no matching process,
   mount, socket, or app bridge file.

## Planned command

```sh
NOVA_RUN_ID=nova-runtime-cleanup-process-diagnostic-20260810T065951Z \
NOVA_RUN_DIR=android/nova-lab/build/runs/nova-runtime-cleanup-process-diagnostic-20260810T065951Z \
NOVA_GAMESCOPE_HEADLESS=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/gamescope-headless-libei-build-v2/src/gamescope \
GAMESCOPE_HEADLESS_SOURCE=/Users/kurt/Developer/gamescope-valve \
NOVA_FULLSCREEN_PRESENTATION=1 NOVA_FULLSCREEN_WIDTH=1280 NOVA_FULLSCREEN_HEIGHT=960 \
NOVA_AHB_WIDTH=1280 NOVA_AHB_HEIGHT=960 NOVA_AHB_FRAME_COUNT=30 \
NOVA_TOUCH_REQUIRE_STEAM_SURFACE=0 NOVA_TOUCH_REQUIRE_VISUAL_CHANGE=0 \
NOVA_TOUCH_WAIT_TIMEOUT=30 NOVA_STEAM_CLIENT_TIMEOUT=60 NOVA_STEAM_GAMESCOPE_TIMEOUT=75 \
  android/nova-lab/deploy-native-steam-touch-input-smoke-test.sh
```
