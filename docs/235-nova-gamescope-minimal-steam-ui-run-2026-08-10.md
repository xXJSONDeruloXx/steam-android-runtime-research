# Nova Gamescope minimal Steam UI run — 2026-08-10

Status: predeclared; this run changes only the Steam client flags from the last
full AHB run to isolate the `-gamepadui` startup boundary.

## Question

Can native ARM64 Steam reach and display its UI inside the already-proven
libei-enabled Gamescope/AHardwareBuffer path when the Steam Deck GamepadUI flag
is removed, while retaining the same software-GL client isolation?

A pass would establish a minimal Steam UI rendering baseline inside Gamescope;
it would not yet prove GamepadUI, gamepad navigation, touch navigation, audio,
or end-user APK promotion. A failure keeps the blocker at Steam/X11/runtime
startup rather than blaming GamepadUI alone.

## Fixed run identity and inputs

- Device: Retroid Pocket Nova, `kalama`, ADB serial `675a2365`.
- Run ID: `gamescope-minimal-steam-ui-20260810T071304Z`.
- Run directory:
  `android/nova-lab/build/runs/gamescope-minimal-steam-ui-20260810T071304Z`.
- Gamescope source commit: `fb9f84ee247a1f02b1a132da60e94585db84bf61`.
- Explicit Gamescope binary:
  `android/nova-lab/build/gamescope-headless-libei-build-v2/src/gamescope`.
- Expected Gamescope SHA-256:
  `cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca`.
- Steam flags: `-steamos3 -steampal -steamdeck`, with `-gamepadui` omitted.
- Steam client: `swrast`/`softpipe`, `LIBGL_ALWAYS_SOFTWARE=1`, no CEF sandbox.
- Presentation: fullscreen Android activity, `1280x960`, 120 AHB frames,
  linear tiling, explicit Turnip ICD for Gamescope.
- Input: no gesture is issued in this isolating run.

## Acceptance gates

1. Fresh cleanup, artifact metadata, and preflight pass.
2. The report records `vulkaninfo_status=0`, three imported `1280x960`
   AHardwareBuffers, and 120 composited frames.
3. Steam starts with the exact minimal flag set, and fresh Steam/webhelper or
   equivalent UI evidence identifies whether a visible Steam surface exists.
4. The screenshot is tied to this run ID and is not reused from the direct X11
   session.
5. Teardown leaves no matching Nova process, mount, socket, or app bridge file.

## Planned command

```sh
NOVA_RUN_ID=gamescope-minimal-steam-ui-20260810T071304Z \
NOVA_RUN_DIR=android/nova-lab/build/runs/gamescope-minimal-steam-ui-20260810T071304Z \
NOVA_GAMESCOPE_HEADLESS=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/gamescope-headless-libei-build-v2/src/gamescope \
GAMESCOPE_HEADLESS_SOURCE=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/gamescope-headless-libei-source-v2 \
NOVA_FULLSCREEN_PRESENTATION=1 NOVA_FULLSCREEN_WIDTH=1280 NOVA_FULLSCREEN_HEIGHT=960 \
NOVA_AHB_WIDTH=1280 NOVA_AHB_HEIGHT=960 NOVA_AHB_FRAME_COUNT=120 \
NOVA_STEAM_CLIENT_FLAGS='-steamos3 -steampal -steamdeck' \
NOVA_STEAM_BOOTSTRAP_MODE=skip NOVA_STEAM_MESA_DRIVER=swrast \
NOVA_STEAM_GALLIUM_DRIVER=softpipe NOVA_STEAM_LIBGL_ALWAYS_SOFTWARE=1 \
NOVA_STEAM_NO_CEF_SANDBOX=1 NOVA_STEAM_CLIENT_TIMEOUT=180 \
NOVA_STEAM_GAMESCOPE_TIMEOUT=220 \
  android/nova-lab/deploy-native-steam-smoke-test.sh
```
