# Nova Android input bridge Steam UI navigation acceptance

Test date: 2026-08-08 (device report timestamps are UTC)

Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740

ADB serial: `675a2365`

This is the Android-app follow-up to [doc 28](28-nova-steam-dpad-navigation.md).
The test sends Android `KEYCODE_DPAD_DOWN` through `MainActivity.dispatchKeyEvent`,
the app's abstract `LocalServerSocket`, and the rooted ARM64 helper. The helper
maps it to Linux `BTN_DPAD_DOWN` (code 545) on the exact virtual Xbox-shaped
uinput device. The strict visual gate requires the actual Steam Gamepad UI
navigation panel, and the panel changes after the event.

The app also normalizes an Android key-up that arrives without a matching key-down:
it synthesizes the missing Linux press before forwarding the release. The accepted
run below delivered a normal pair; the defensive normalization is covered by the
app code and the harness checks it when the device exhibits the up-only behavior.

## Reproducible test

```sh
NOVA_CONTROLLER_UI_INPUT_MODE=android-keyevent \
NOVA_CONTROLLER_UI_ANDROID_KEYCODE=20 \
NOVA_CONTROLLER_UI_ANDROID_KEY_NAME=KEYCODE_DPAD_DOWN \
NOVA_CONTROLLER_UI_EVENT_CODE=545 \
NOVA_CONTROLLER_UI_EVENT_NAME=BTN_DPAD_DOWN \
NOVA_CONTROLLER_UI_ANDROID_KEY_ONLY=1 \
NOVA_CONTROLLER_UI_EXPECT_NAVIGATION=1 \
INSTALL_HOLO_GAMESCOPE=0 \
NOVA_AHB_FRAME_COUNT=120 \
NOVA_CONTROLLER_UI_STABLE_ATTEMPTS=60 \
NOVA_CONTROLLER_UI_SETTLE_DELAY=20 \
NOVA_CONTROLLER_UI_AFTER_DELAY=5 \
NOVA_CONTROLLER_UI_WAIT_TIMEOUT=140 \
NOVA_CONTROLLER_UI_RELAY_TIMEOUT=180000 \
NOVA_STEAM_CLIENT_TIMEOUT=180 \
NOVA_STEAM_GAMESCOPE_TIMEOUT=220 \
android/nova-lab/deploy-native-steam-controller-ui-input-smoke-test.sh
```

The wrapper clears any prior lab Activity before the background Steam launch,
dismisses the Nova `com.rp.settings` overlay when it owns focus, waits for
SteamUI readiness, and requires the settled screenshot crop to match the Steam
side-panel luminance signature. This avoids accepting the lab UI, Steam splash
animation, or a settings/USB overlay as navigation.

## Accepted result

```text
controller_ui_source_ready=1
controller_ui_input_mode=android-keyevent
controller_ui_relay_ready=1
controller_ui_ready=1 app_pid=3655
controller_ui_surface=pass
controller_ui_screenshot_sha256=b1304c8e7909232fdc4c970e071acf65cfd02fb9d8acaf7b829e3b61718675c4
controller_ui_surface_sha256=08a6f0ca7f390dfe894b2ab2133b43e533888b2868d5d4a0ec31bab277567bbf
controller_ui_surface_yhigh=48
controller_ui_steam_surface=pass
controller_ui_steam_panel_ymin=26
controller_ui_steam_panel_ylow=48
controller_ui_steam_panel_yavg=62
controller_ui_steam_panel_ymax=235
controller_ui_android_event=KEYCODE_DPAD_DOWN code=20 maps_to=BTN_DPAD_DOWN code=545
controller_ui_after_delay=5
controller_ui_after_surface_sha256=35c3d8f807368eea30451a72c4d54d5c91ee28331d3a93059048a3935eb71a7f
controller_ui_navigation_panel_before_sha256=ce05521bd0d9933a868eceb4b8d5981633314257fc5d3f0571bc913ef85cfdd1b
controller_ui_navigation_panel_after_sha256=dd1ecb09838cd1da3068c93de394e0da33d0495796e668b091b610d169b58c14
controller_ui_after_screenshot_sha256=5f533a286fe45fe2a5d4964f1dfb8ce8110de3c937fee2128c5d2a68784665d2
controller_ui_screen_changed=pass
controller_ui_navigation=pass
headless_gamescope_ahb=pass
native_steam_smoke=pass
controller_ui_run_status=0
controller_ui_helper_status=0
controller_ui_fd_status=0
controller_ui_android_input_marker=press_release
controller_ui_android_input_bridge=pass
native_steam_controller_ui_input_smoke=pass
```

The before/after panel hashes are the strict Steam crop, not the full animated
surface. The screenshots show the live pre-login Steam Gamepad UI language
selector, with the highlighted language moving after `BTN_DPAD_DOWN`.

## Android app and rooted helper evidence

The helper received a complete Linux press/release pair from the app socket:

```text
uinput_source=/dev/input/event7
uinput_source_name=Xbox Wireless Controller
uinput_open=pass
uinput_sysname=input265
uinput_device_permissions=pass
uinput_device=/dev/input/event9
uinput_device_ready=pass
android_input_socket=@/data/user/0/com.xjsonderulo.steamandroid.novalab/files/nova-input.sock
android_input_socket_connected=pass
uinput_relay=begin
android_input_key_received code=20 linux_code=545 event=BTN_DPAD_DOWN action=0
android_input_key_received code=20 linux_code=545 event=BTN_DPAD_DOWN action=1
uinput_event_forwarded=none
android_key_forwarded=pass
android_input_keycode=20
android_input_linux_code=545
android_input_linux_event=BTN_DPAD_DOWN
android_axis_forwarded=none
android_input_forwarded=pass
uinput_relay=end
uinput_probe=pass
```

The app's persisted bridge report recorded controller enumeration, socket
connection, Android dispatch, and filtering of the helper's virtual-device echo:

```text
android_input_device_controller=pass count=7
android_input_socket=listening
android_input_socket=connected
android_input_key_forwarded=pass
android_input_key_dispatch keycode=20 action=0 source=0x0
android_input_key_dispatch keycode=20 action=1 source=0x0
android_input_relay_loop_filtered device=284 name=Nova Virtual Xbox Controller
android_input_key_event device=284 keycode=0 source=0x501
```

Steam held the matching event FD and identity:

```text
steam_input_fd_target_name=Nova Virtual Xbox Controller
steam_input_fd_target_vendor=045e
steam_input_fd_target_product=028e
steam_input_fd_target=/data/local/tmp/nova-holo-rootfs/dev/input/event9
steam_input_process pid=4035 name=steam exe=/data/local/tmp/nova-holo-rootfs/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam fd=/proc/4035/fd/92 target=/data/local/tmp/nova-holo-rootfs/dev/input/event9
steam_input_fd=pass
steam_input_fd_probe=pass
```

## Boundary and next steps

The accepted Android path is:

```text
Android key dispatch
  -> app-side LocalServerSocket
  -> rooted ARM64 helper
  -> Linux BTN_DPAD_DOWN press/release on exact /dev/input/event9
  -> Steam process FD
  -> Steam Gamepad UI navigation
  -> Android AHardwareBuffer/SurfaceControl presentation
```

This proves the app-side D-pad path, not hardware CEF rendering, login, game
launch, rumble, axes, or lifecycle cleanup. The corrected ABXY mapping and
virtual-device feedback-loop guard are documented in [doc 30](30-nova-android-a-button-navigation.md);
the A-button UI effect remains an open acceptance item. The next input work is
to accept B/X/Y, Start, Back, Guide, axis, and hold/repeat mappings, then use
the same Android bridge while advancing Steam OOBE/login and a first game.
