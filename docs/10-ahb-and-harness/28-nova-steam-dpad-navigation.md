# Nova Steam Gamepad UI D-pad navigation acceptance

Test date: 2026-08-08 (device report timestamps are UTC)

Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740

ADB serial: `675a2365`

This is the first end-to-end input result that crosses the Steam UI boundary.
It follows the exact-path SDL3 result in [doc 27](27-nova-sdl3-gamepad-event.md)
and injects Linux `BTN_DPAD_DOWN` (code 545) into the live pre-login Steam
Gamepad UI. The right-hand navigation panel changed, so the event was
accepted by Steam's own input/UI path rather than only by the lower-level
uinput, libudev, or SDL3 probes.

The earlier negative physical and Android-keyevent comparisons in [doc 24](24-nova-steam-dpad-input.md)
and [doc 25](25-nova-android-input-steam-ui.md) remain useful historical
experiments, but they ran before the relay's exact sysname/path selection and
mount cleanup hardening. This run is the physical-input acceptance boundary;
the Android app-side acceptance is now recorded in [doc 29](29-nova-android-input-steam-ui-navigation.md).

## Reproducible test

The accepted run used the bounded 120-frame presentation profile and skipped
reinstalling the already-staged Holo gamescope package:

```sh
NOVA_CONTROLLER_UI_INPUT_MODE=physical \
NOVA_CONTROLLER_UI_EVENT_CODE=545 \
NOVA_CONTROLLER_UI_EVENT_NAME=BTN_DPAD_DOWN \
NOVA_CONTROLLER_UI_EXPECT_NAVIGATION=1 \
INSTALL_HOLO_GAMESCOPE=0 \
NOVA_AHB_FRAME_COUNT=120 \
NOVA_CONTROLLER_UI_STABLE_ATTEMPTS=20 \
NOVA_CONTROLLER_UI_SETTLE_DELAY=20 \
NOVA_CONTROLLER_UI_AFTER_DELAY=20 \
NOVA_CONTROLLER_UI_WAIT_TIMEOUT=140 \
NOVA_CONTROLLER_UI_RELAY_TIMEOUT=180000 \
NOVA_STEAM_CLIENT_TIMEOUT=180 \
NOVA_STEAM_GAMESCOPE_TIMEOUT=220 \
android/nova-lab/deploy-native-steam-controller-ui-input-smoke-test.sh
```

The wrapper waits for SteamUI readiness and a stable non-black Android surface,
injects one down/up event into the attached Xbox controller's `/dev/input/event7`,
then checks the cropped navigation panel before and after the event. The relay
creates a fresh virtual node and stops without draining that node's event
descriptor, leaving the descriptor available to Steam.

## Accepted result

The visual assertion and native presentation completed successfully:

```text
controller_ui_source_ready=1
controller_ui_input_mode=physical
controller_ui_relay_ready=1
controller_ui_ready=1 app_pid=8757
controller_ui_surface=pass
controller_ui_surface_yhigh=223
controller_ui_event=BTN_DPAD_DOWN code=545
controller_ui_screen_changed=pass
controller_ui_navigation=pass
headless_gamescope_ahb=pass
native_steam_smoke=pass
controller_ui_run_status=0
controller_ui_helper_status=0
controller_ui_fd_status=0
native_steam_controller_ui_input_smoke=pass
```

The before/after panel hashes were different:

```text
controller_ui_navigation_panel_before_sha256=158d11e4c1ec13f2a4b49ba99c4bba5cce3ed3273a50c3e55a56e7e3bca28f4c
controller_ui_navigation_panel_after_sha256=dbdeb1fc4dc59791b9bcb6dc2937b0453c3c917b8bd585fd644ee018591f7af2
```

The full-screen surface also changed as expected:

```text
controller_ui_screenshot_sha256=959f7b10a181528d7c6b32475ff6fbc59699eab3d4120c1dc13cc3750ea23abe
controller_ui_after_surface_sha256=c842083313d6a3fca0e619ab9f76ba43e3242b46a8a135bae74e687314c2215b
controller_ui_after_screenshot_sha256=5d4173190da6000dd1c0c1876fba2eafa4e5a0e48f71e821a9b65ed4718f71db
```

## Exact device and process evidence

The relay selected the fresh Xbox 360-shaped virtual node by its creation
sysname and verified its identity. A stale app-owned duplicate remained at a
different event number but was not selected:

```text
uinput_source=/dev/input/event7
uinput_source_name=Xbox Wireless Controller
uinput_open=pass
uinput_sysname=input166
uinput_device_permissions=pass
uinput_device=/dev/input/event9
uinput_device_ready=pass
uinput_event_forwarded=pass
uinput_control_event_code=545
uinput_control_event=BTN_DPAD_DOWN
uinput_probe=pass
```

The native ARM64 Steam process held an open FD for that exact path and
identity, not merely for a same-name device:

```text
steam_input_fd_target_name=Nova Virtual Xbox Controller
steam_input_fd_target_vendor=045e
steam_input_fd_target_product=028e
steam_input_fd_target=/data/local/tmp/nova-holo-rootfs/dev/input/event9
steam_input_process pid=9007 name=steam exe=/data/local/tmp/nova-holo-rootfs/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam fd=/proc/9007/fd/95 target=/data/local/tmp/nova-holo-rootfs/dev/input/event9
steam_input_fd=pass
steam_input_fd_probe=pass
```

## AHB evidence capture hardening

The Android bridge now writes the exact native double-buffer return string to
`files/dmabuf-double-buffer-report.txt`. The Gamescope AHB harness captures
that sandbox report as `device-gamescope-headless-ahb-app-report.txt` and
accepts each required marker from either the report or filtered `NovaLab`
logcat. This keeps the check strict while avoiding a false negative when the
Android log buffer is empty after a long Steam/Xwayland session. The accepted
run still passed the Vulkan/Gamescope report, filtered logcat, app report,
native Steam smoke, exact relay, and exact Steam FD checks.

## What this proves and what remains open

Proven on the Nova:

```text
physical Android controller
  -> Android-visible Xbox evdev source
  -> rooted exact `/dev/uinput` virtual Xbox node
  -> Holo/uid-501 visibility and Steam FD ownership
  -> Steam Gamepad UI D-pad navigation
  -> Android SurfaceControl/AHardwareBuffer presentation
```

This does not yet prove hardware CEF rendering, account login, a launched
game, rumble, axes, or clean suspend/resume. The current UI rendering path
still reports software CEF/ANGLE rendering as described in [doc 15](15-nova-steam-ui-ahb-smoke.md).
The Android-keyevent D-pad path is accepted in [doc 29](29-nova-android-input-steam-ui-navigation.md),
including the strict Steam-surface visual gate. The corrected Android A-button
mapping and feedback-loop filter are recorded as a transport checkpoint in
[doc 30](30-nova-android-a-button-navigation.md); A-button UI consumption is
still open. The next input work is B/X/Y, Start, Back, Guide, axes, and
repeat/hold behavior before attempting login or a game launch.
