# Nova libei-enabled Gamescope touch/fullscreen matcher-fix run — 2026-08-10

Status: predeclared; this run verifies the cleanup matcher repair and, only if
preflight passes, proceeds to the existing AHB/Steam/touch acceptance gates.

## Question

Does excluding the observed Magisk `com.android.commands.content.Content` policy
log wrappers let the exact Nova cleanup gate pass while preserving detection of
real Gamescope, Steam, Xwayland, relay, and libei descendants?

If it passes, the run evaluates the same explicit libei-enabled Gamescope binary
at 1280×960 with the Android touch → libei path. It remains a transport and
presentation experiment, not proof of a finished product APK, audio, hardware
CEF acceleration, or physical controller input.

## Fixed run identity and inputs

- Device: Retroid Pocket Nova, `kalama`, ADB serial `675a2365`.
- Run ID: `gamescope-libei-touch-fullscreen-matcher-fix-20260810T070303Z`.
- Run directory:
  `android/nova-lab/build/runs/gamescope-libei-touch-fullscreen-matcher-fix-20260810T070303Z`.
- Matcher fix commit: `e3065c1`.
- Gamescope source commit: `fb9f84ee247a1f02b1a132da60e94585db84bf61`.
- Explicit Gamescope binary:
  `android/nova-lab/build/gamescope-headless-libei-build-v2/src/gamescope`.
- Expected Gamescope SHA-256:
  `cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca`.
- AHB output: `1280x960`, 120 frames, linear tiling.
- Android presentation: fullscreen mode enabled, Vulkan layout usage `0x333`.
- Input path: Android touch socket → ARM64 libei helper → Gamescope EIS.
- Steam client: native ARM64 Steam/Gamepad UI with software GL explicitly retained.

## Acceptance gates

1. Metadata records the exact binary SHA-256 and `gamescope_libei_build=enabled`.
2. Both preflight cleanup attempts accept only a genuinely clean final state;
   policy-log wrappers must not appear as runtime residuals.
3. The same run records Gamescope/AHB frames and a live Steam surface.
4. The touch helper records socket, seat, device, resume, down/up, and probe
   markers, plus a Gamescope EIS touch-event marker.
5. Exact teardown leaves no matching process, rootfs mount, socket, or app bridge
   file.

Any failure before launch is documented as a harness/device boundary and is not
interpreted as a rendering or input result.

## Planned command

```sh
NOVA_RUN_ID=gamescope-libei-touch-fullscreen-matcher-fix-20260810T070303Z \
NOVA_RUN_DIR=android/nova-lab/build/runs/gamescope-libei-touch-fullscreen-matcher-fix-20260810T070303Z \
NOVA_GAMESCOPE_HEADLESS=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/gamescope-headless-libei-build-v2/src/gamescope \
GAMESCOPE_HEADLESS_SOURCE=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/gamescope-headless-libei-source-v2 \
NOVA_FULLSCREEN_PRESENTATION=1 NOVA_FULLSCREEN_WIDTH=1280 NOVA_FULLSCREEN_HEIGHT=960 \
NOVA_AHB_WIDTH=1280 NOVA_AHB_HEIGHT=960 NOVA_AHB_FRAME_COUNT=120 \
NOVA_TOUCH_REQUIRE_STEAM_SURFACE=1 NOVA_TOUCH_REQUIRE_VISUAL_CHANGE=0 \
NOVA_TOUCH_WAIT_TIMEOUT=150 NOVA_TOUCH_SETTLE_DELAY=20 NOVA_TOUCH_AFTER_DELAY=8 \
NOVA_STEAM_CLIENT_TIMEOUT=180 NOVA_STEAM_GAMESCOPE_TIMEOUT=220 \
  android/nova-lab/deploy-native-steam-touch-input-smoke-test.sh
```
