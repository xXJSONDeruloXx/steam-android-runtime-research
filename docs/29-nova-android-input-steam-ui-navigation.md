# Nova Android input bridge Steam UI navigation acceptance

Test date: 2026-08-08 (device report timestamps are UTC)

Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740

ADB serial: `675a2365`

This is the Android-app follow-up to [doc 28](28-nova-steam-dpad-navigation.md).
The test sends Android `KEYCODE_DPAD_DOWN` through `MainActivity.dispatchKeyEvent`,
the app's abstract `LocalServerSocket`, and the rooted ARM64 helper. The helper
maps it to Linux `BTN_DPAD_DOWN` (code 545) on the exact virtual Xbox-shaped
uinput device. The live Steam Gamepad UI navigation panel changes, so the
Android app path now crosses the same Steam consumer boundary as the direct
physical path.

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
NOVA_CONTROLLER_UI_STABLE_ATTEMPTS=20 \
NOVA_CONTROLLER_UI_SETTLE_DELAY=20 \
NOVA_CONTROLLER_UI_AFTER_DELAY=20 \
NOVA_CONTROLLER_UI_WAIT_TIMEOUT=140 \
NOVA_CONTROLLER_UI_RELAY_TIMEOUT=180000 \
NOVA_STEAM_CLIENT_TIMEOUT=180 \
NOVA_STEAM_GAMESCOPE_TIMEOUT=220 \
android/nova-lab/deploy-native-steam-controller-ui-input-smoke-test.sh
```

The Nova wrapper dismisses the device's `com.rp.settings` system-alert
overlay if it owns input focus before sending the synthetic key. Without that
guard, `adb shell input keyevent` can be consumed by the overlay even though
the lab activity remains the resumed Android activity.

## Accepted result

```text
controller_ui_source_ready=1
controller_ui_input_mode=android-keyevent
controller_ui_relay_ready=1
controller_ui_ready=1 app_pid=18225
controller_ui_surface=pass
controller_ui_dismissed_overlay=com.rp.settings
controller_ui_android_event=KEYCODE_DPAD_DOWN code=20 maps_to=BTN_DPAD_DOWN code=545
controller_ui_screen_changed=pass
controller_ui_navigation=pass
headless_gamescope_ahb=pass
native_steam_smoke=pass
controller_ui_run_status=0
controller_ui_helper_status=0
controller_ui_fd_status=0
controller_ui_android_input_bridge=pass
native_steam_controller_ui_input_smoke=pass
```

The cropped navigation panel changed between the settled before and after
captures:

```text
controller_ui_navigation_panel_before_sha256=a8a4983bd0723270ff16051de2bac1c486d70a190cb3ac62a79a5d0206b6d6e4
controller_ui_navigation_panel_after_sha256=dd1ecb09838cd1da3068c93de394e0da33d0495796e668b091b610d169b58c14
```

The presentation and full-screen artifacts were also captured:

```text
controller_ui_screenshot_sha256=03051c06d261616a621d15157e9f7da037add4020e4533c0080aa8f84bff7dd7
controller_ui_after_surface_sha256=9c78cd2bac7578098e0737c1f1d5f2bbe961806ce839830b025a38d2901e11b1
controller_ui_after_screenshot_sha256=8857a96a7c12aa417bd1d793f1089e3bdd0a671d8c43e9882eaa1a0cd3fee5d8
```

## Android app and rooted helper evidence

The helper created the exact relay node and received the app's key stream. The
absence of `uinput_event_forwarded` is expected here: this mode deliberately
does not inject a second physical evdev event; the accepted event came from
the Android socket.

```text
uinput_source=/dev/input/event7
uinput_source_name=Xbox Wireless Controller
uinput_open=pass
uinput_sysname=input188
uinput_device_permissions=pass
uinput_device=/dev/input/event9
uinput_device_ready=pass
android_input_socket=@/data/user/0/com.xjsonderulo.steamandroid.novalab/files/nova-input.sock
android_input_socket_connected=pass
uinput_event_forwarded=none
android_key_forwarded=pass
android_input_keycode=20
android_input_linux_code=545
android_input_linux_event=BTN_DPAD_DOWN
android_axis_forwarded=none
android_input_forwarded=pass
uinput_probe=pass
```

The app's persisted bridge report provides the exact dispatch and enumeration
markers independently of long-session logcat retention:

```text
android_input_device_controller=pass count=7
android_input_socket=listening
android_input_socket=connected
android_input_key_forwarded=pass
android_input_key_dispatch keycode=20 action=0 source=0x0
android_input_key_dispatch keycode=20 action=1 source=0x0
```

The native Steam process held the matching event FD and identity:

```text
steam_input_fd_target_name=Nova Virtual Xbox Controller
steam_input_fd_target_vendor=045e
steam_input_fd_target_product=028e
steam_input_fd_target=/data/local/tmp/nova-holo-rootfs/dev/input/event9
steam_input_process pid=18468 name=steam exe=/data/local/tmp/nova-holo-rootfs/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam fd=/proc/18468/fd/95 target=/data/local/tmp/nova-holo-rootfs/dev/input/event9
steam_input_fd=pass
steam_input_fd_probe=pass
```

## Boundary and next steps

The accepted Android path is:

```text
Android key dispatch
  -> app-side LocalServerSocket
  -> rooted ARM64 helper
  -> Linux BTN_DPAD_DOWN on exact /dev/uinput node
  -> Steam process FD
  -> Steam Gamepad UI navigation
  -> Android AHardwareBuffer/SurfaceControl presentation
```

This proves the app-side D-pad path, not hardware CEF rendering, login, game
launch, rumble, axes, or lifecycle cleanup. The corrected A-button mapping and
the virtual-device feedback-loop guard are accepted in [doc 30](30-nova-android-a-button-navigation.md).
The next input work is to accept B/X/Y, Start, Back, Guide, axis, and
hold/repeat mappings, then use the same Android bridge while advancing Steam
OOBE/login and a first game.
