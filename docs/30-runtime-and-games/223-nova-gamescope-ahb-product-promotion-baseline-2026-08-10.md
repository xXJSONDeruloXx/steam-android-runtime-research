# Nova Gamescope/AHardwareBuffer product-promotion baseline — 2026-08-10

Status: predeclared; no device session has been launched under this run.

## Question

Can the currently deployed, libei-enabled Gamescope/AHardwareBuffer path sustain a
fresh native ARM64 Steam session at the Nova's full `1280x960` 4:3 geometry while
the Android lab app is the visible fullscreen surface? This is the closest existing
test-bench path to the end-user product goal, so it is the baseline before promoting
that path into the one-click launcher.

This run deliberately keeps the current test-bench launcher unchanged. It is not a
claim that the APK is already a standalone Gamescope product, and it does not replace
the direct Termux:X11 software-GL fallback.

## Run identity

- Device: Retroid Pocket Nova, `kalama`, ADB serial `675a2365`.
- Run ID: `gamescope-product-baseline-20260810T063853Z`.
- Host profile: `NOVA_RUN_PROFILE=manual-bounded`.
- Android presentation: `MainActivity`, `fullscreen_presentation=1`,
  `fullscreen_width=1280`, `fullscreen_height=960`.
- Gamescope/AHB output: `NOVA_AHB_WIDTH=1280`, `NOVA_AHB_HEIGHT=960`,
  continuous manual-session frame mode.
- Input bridges: physical uinput relay and continuous Android-touch → libei bridge.
- Steam client: native ARM64 Steam Gamepad UI, software GL inside the client,
  hardware-backed Android Termux/X11 display is not used in this profile.
- Cleanup: exact `nova-runtime-cleanup.sh`, app-owned bridge-file cleanup, and the
  manual-session stop path are required before and after the run.

## Artifact provenance

The intended host artifacts are the current local build outputs:

```text
gamescope: android/nova-lab/build/gamescope-headless-build/src/gamescope
libei helper: android/nova-lab/build/nova-libei-input-bridge
uinput helper: android/nova-lab/build/nova-uinput-gamepad-relay
```

The run log must record each artifact SHA-256, the Gamescope source commit and
libei build marker, the APK identity, the rootfs path, and the presentation/input
flags. All run-specific logs and captures belong under a fresh ignored
`android/nova-lab/build/runs/<run-id>/` directory.

## Acceptance gates

The result is accepted only if the fresh run records:

1. a clean preflight and a fresh Steam/UI log baseline;
2. a visible, live `1280x960` Android surface with Gamescope/AHB frame and fence
   evidence;
3. current-run Steam readiness and a screenshot captured while the session is live;
4. the physical relay and Android touch/libei bridges reaching their current
   transport markers; and
5. exact teardown with no matching Gamescope, Steam, webhelper, relay, touch helper,
   mount, or bridge-socket residue.

Failure must identify the first failed layer. A pass still proves only the test-bench
presentation/input baseline; product promotion remains a separate implementation
step because the APK does not yet launch this Gamescope path.

## Planned command

```sh
NOVA_RUN_PROFILE=manual-bounded \
NOVA_RUN_ID=gamescope-product-baseline-20260810T063853Z \
NOVA_RUN_DIR=android/nova-lab/build/runs/gamescope-product-baseline-20260810T063853Z \
NOVA_AHB_WIDTH=1280 NOVA_AHB_HEIGHT=960 \
NOVA_FULLSCREEN_PRESENTATION=1 \
NOVA_FULLSCREEN_WIDTH=1280 NOVA_FULLSCREEN_HEIGHT=960 \
NOVA_CONTROLLER_UI_INPUT_MODE=physical \
NOVA_CONTROLLER_UI_X11_CAPTURE=1 \
NOVA_X11_CAPTURE=android/nova-lab/build/nova-x11-capture \
NOVA_ANDROID_TOUCH_BRIDGE=1 NOVA_EIS_TOUCH_BRIDGE=1 \
NOVA_EIS_TOUCH_CONTINUOUS=1 \
android/nova-lab/deploy-native-steam-manual-session.sh
```

The command is bounded by the manual profile. If it is interrupted, run the matching
stop command and verify the exact cleanup markers before any replacement run.
