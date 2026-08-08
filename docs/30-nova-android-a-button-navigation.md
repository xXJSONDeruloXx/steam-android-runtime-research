# Nova Android input A-button navigation acceptance

Test date: 2026-08-08 (device report timestamps are UTC)

Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740

ADB serial: `675a2365`

This is the first accepted Android-app ABXY mapping result. It follows [doc
29](29-nova-android-input-steam-ui-navigation.md), which accepted Android
`KEYCODE_DPAD_DOWN`, and proves that Android `KEYCODE_BUTTON_A` can cross the
app socket and rooted ARM64 helper as Linux `BTN_SOUTH` while changing the live
Steam Gamepad UI navigation panel.

## Corrected semantic mapping

The initial helper table was shifted for the Nova's controller. [Doc
20](20-nova-physical-controller-dispatch.md) showed that Linux `BTN_EAST`
(305) arrives in Android as keycode 97 (`KEYCODE_BUTTON_B`), so the Xbox-shaped
mapping was corrected to:

| Android key | Linux code | Linux event |
| --- | ---: | --- |
| `KEYCODE_BUTTON_A` (96) | 304 | `BTN_SOUTH` |
| `KEYCODE_BUTTON_B` (97) | 305 | `BTN_EAST` |
| `KEYCODE_BUTTON_C` (98) | 306 | `BTN_C` |
| `KEYCODE_BUTTON_X` (99) | 307 | `BTN_NORTH` |
| `KEYCODE_BUTTON_Y` (100) | 308 | `BTN_WEST` |

The relay now emits a per-event marker, so the requested mapping remains
provable even when unrelated Android controller events arrive later.

## Virtual-device feedback fix

The first corrected A attempt exposed a real Android integration issue: the
rooted `Nova Virtual Xbox Controller` is itself visible to Android. Forwarding
the virtual device's echoed `KEYCODE_BUTTON_A` back into the same uinput node
created a feedback loop (about 800 repeated dispatches in the failed run).
`MainActivity` now filters that exact relay-device identity in both key and
motion dispatch. Shell-injected events with no device and the attached
`Xbox Wireless Controller` continue through the bridge.

## Reproducible test

The accepted run used a 60-frame bounded presentation profile. The 120-frame
D-pad acceptance remains in [doc 29](29-nova-android-input-steam-ui-navigation.md)'s
baseline; a later 120-frame A retry hit Steam startup readiness zero before
input injection and is not counted as an A result.

```sh
NOVA_CONTROLLER_UI_INPUT_MODE=android-keyevent \
NOVA_CONTROLLER_UI_ANDROID_KEYCODE=96 \
NOVA_CONTROLLER_UI_ANDROID_KEY_NAME=KEYCODE_BUTTON_A \
NOVA_CONTROLLER_UI_EVENT_CODE=304 \
NOVA_CONTROLLER_UI_EVENT_NAME=BTN_SOUTH \
NOVA_CONTROLLER_UI_ANDROID_KEY_ONLY=1 \
NOVA_CONTROLLER_UI_EXPECT_NAVIGATION=1 \
INSTALL_HOLO_GAMESCOPE=0 \
NOVA_AHB_FRAME_COUNT=60 \
NOVA_CONTROLLER_UI_STABLE_ATTEMPTS=10 \
NOVA_CONTROLLER_UI_SETTLE_DELAY=10 \
NOVA_CONTROLLER_UI_AFTER_DELAY=10 \
NOVA_CONTROLLER_UI_WAIT_TIMEOUT=140 \
NOVA_CONTROLLER_UI_RELAY_TIMEOUT=120000 \
NOVA_STEAM_CLIENT_TIMEOUT=120 \
NOVA_STEAM_GAMESCOPE_TIMEOUT=160 \
android/nova-lab/deploy-native-steam-controller-ui-input-smoke-test.sh
```

## Accepted result

```text
controller_ui_source_ready=1
controller_ui_input_mode=android-keyevent
controller_ui_relay_ready=1
controller_ui_ready=1 app_pid=26559
controller_ui_surface=pass
controller_ui_dismissed_overlay=com.rp.settings
controller_ui_android_event=KEYCODE_BUTTON_A code=96 maps_to=BTN_SOUTH code=304
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

The cropped Steam navigation panel changed:

```text
controller_ui_navigation_panel_before_sha256=a8a4983bd0723270ff16051de2bac1c486d70a190cb3ac62a79a5d0206b6d6e4
controller_ui_navigation_panel_after_sha256=66fe559c92ea9fec3c470098b13e78b22d899fe3175fe4f75859cd3f86092f0b
```

The settled presentation surface and screenshots were also captured:

```text
controller_ui_screenshot_sha256=4e8a240c418da3a1450b2b1dd7e227c731c480c255a7388f2ae4fa52eb344270
controller_ui_after_surface_sha256=6fc140af124bc682e6cf77f530653848eaf4e5ac0699684066c6f4f11c0cc3a4
controller_ui_after_screenshot_sha256=b67c6ac8d9179692b08db8ebe2a6b4b465bd39a7b6367d721529f0acceeb67e4
```

## Exact app and rooted-helper evidence

The Android app report recorded controller enumeration, the shell-injected
key, and the feedback filter:

```text
android_input_device_controller=pass count=7
android_input_socket=listening
android_input_socket=connected
android_input_key_forwarded=pass
android_input_key_dispatch keycode=96 action=0 source=0x0
android_input_key_dispatch keycode=23 action=0 source=0x0
android_input_key_dispatch keycode=96 action=1 source=0x0
android_input_key_dispatch keycode=23 action=1 source=0x0
android_input_relay_loop_filtered device=221 name=Nova Virtual Xbox Controller
```

The rooted helper created the exact node and received only the requested A
down/up pair:

```text
uinput_source=/dev/input/event7
uinput_source_name=Xbox Wireless Controller
uinput_open=pass
uinput_sysname=input206
uinput_device_permissions=pass
uinput_device=/dev/input/event9
uinput_device_ready=pass
android_input_socket_connected=pass
android_input_key_received code=96 linux_code=304 event=BTN_SOUTH action=0
android_input_key_received code=96 linux_code=304 event=BTN_SOUTH action=1
android_key_forwarded=pass
android_input_keycode=96
android_input_linux_code=304
android_input_linux_event=BTN_SOUTH
android_input_forwarded=pass
uinput_probe=pass
```

Steam held the exact virtual event node by path and Xbox identity:

```text
steam_input_fd_target_name=Nova Virtual Xbox Controller
steam_input_fd_target_vendor=045e
steam_input_fd_target_product=028e
steam_input_fd_target=/data/local/tmp/nova-holo-rootfs/dev/input/event9
steam_input_process pid=26804 name=steam exe=/data/local/tmp/nova-holo-rootfs/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam fd=/proc/26804/fd/96 target=/data/local/tmp/nova-holo-rootfs/dev/input/event9
steam_input_fd=pass
steam_input_fd_probe=pass
```

## Boundary and next steps

The accepted Android A path is:

```text
Android KEYCODE_BUTTON_A
  -> app dispatch with source=0x0
  -> abstract LocalServerSocket
  -> rooted ARM64 helper
  -> BTN_SOUTH on exact /dev/input/event9
  -> Steam process FD
  -> Steam Gamepad UI navigation
  -> Android AHardwareBuffer/SurfaceControl presentation
```

This proves A-button transport and Steam UI consumption, not B/X/Y acceptance,
axes, rumble, login, game launch, hardware CEF rendering, or lifecycle cleanup.
The next input iteration should run the corrected B/X/Y mappings, then add
Start/Back/Guide and axis/hold semantics.
