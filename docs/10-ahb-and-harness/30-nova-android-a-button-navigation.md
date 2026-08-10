# Nova Android A-button mapping and feedback-loop checkpoint

Test date: 2026-08-08 (device report timestamps are UTC)

Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740

ADB serial: `675a2365`

This checkpoint corrects the Nova ABXY semantic table and proves that Android
`KEYCODE_BUTTON_A` reaches the rooted helper as Linux `BTN_SOUTH`. It also
proves the Android app does not feed its own rooted virtual-device echo back
into the bridge. It is a transport/mapping result, not an accepted A-button
Steam UI-navigation result.

## Corrected semantic mapping

The initial helper table was shifted for the Nova's controller. [Doc
20](20-nova-physical-controller-dispatch.md) showed that Linux `BTN_EAST`
(305) arrives in Android as keycode 97 (`KEYCODE_BUTTON_B`), so the
Xbox-shaped mapping was corrected to:

| Android key | Linux code | Linux event |
| --- | ---: | --- |
| `KEYCODE_BUTTON_A` (96) | 304 | `BTN_SOUTH` |
| `KEYCODE_BUTTON_B` (97) | 305 | `BTN_EAST` |
| `KEYCODE_BUTTON_C` (98) | 306 | `BTN_C` |
| `KEYCODE_BUTTON_X` (99) | 307 | `BTN_NORTH` |
| `KEYCODE_BUTTON_Y` (100) | 308 | `BTN_WEST` |

The relay emits a per-event marker, so the requested mapping remains provable
even when unrelated Android controller events arrive later.

## Virtual-device feedback fix

The first corrected A attempt exposed a real Android integration issue: the
rooted `Nova Virtual Xbox Controller` is itself visible to Android. Forwarding
its echoed `KEYCODE_BUTTON_A` back into the same uinput node created a feedback
loop. `MainActivity` now filters that exact relay-device identity in both key
and motion dispatch, consumes forwarded bridge events, and leaves shell-injected
events and the attached `Xbox Wireless Controller` eligible for forwarding.

## Mapping smoke evidence

The bounded A run that established the mapping produced these valid lower-level
markers. Its old hash-only navigation result is not treated as Steam UI proof:

```text
controller_ui_input_mode=android-keyevent
controller_ui_android_event=KEYCODE_BUTTON_A code=96 maps_to=BTN_SOUTH code=304
headless_gamescope_ahb=pass
native_steam_smoke=pass
controller_ui_run_status=0
controller_ui_helper_status=0
controller_ui_fd_status=0
controller_ui_android_input_bridge=pass
```

The app report showed the requested A event and the feedback-loop filter. The
extra Android keycode 23 entries were observed companion events from that
shell-injected run; they are why the acceptance harness now consumes bridge
events and filters the virtual-device identity:

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

The rooted helper received the exact semantic event pair:

```text
uinput_source=/dev/input/event7
uinput_source_name=Xbox Wireless Controller
uinput_open=pass
uinput_sysname=input206
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

Steam also held the exact virtual event node during the run:

```text
steam_input_fd_target_name=Nova Virtual Xbox Controller
steam_input_fd_target_vendor=045e
steam_input_fd_target_product=028e
steam_input_fd_target=/data/local/tmp/nova-holo-rootfs/dev/input/event9
steam_input_process pid=26804 name=steam exe=/data/local/tmp/nova-holo-rootfs/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam fd=/proc/26804/fd/96 target=/data/local/tmp/nova-holo-rootfs/dev/input/event9
steam_input_fd=pass
steam_input_fd_probe=pass
```

## SDL3 semantic mapping check

The same `BTN_SOUTH` code was tested independently against Valve's shipped
SDL3 Gamepad API, using the exact relay-created `event9` path. The generalized
probe accepts an expected SDL button number; SDL Gamepad button 0 is the
Xbox-style A/SOUTH button.

```sh
NOVA_INPUT_UDEV_MODE=enabled \
NOVA_SDL3_GAMEPAD_EVENT_PROBE=1 \
NOVA_SDL3_GAMEPAD_EXPECT_BUTTON=0 \
NOVA_SDL3_EVENT_CODE=304 \
NOVA_SDL3_EVENT_TIMEOUT=10000 \
NOVA_INPUT_UDEV_RELAY_TIMEOUT=10000 \
android/nova-lab/deploy-native-steam-input-device-probe.sh
```

The accepted SDL3 result was:

```text
udev_smoke_virtual_device=/dev/input/event9
udev_smoke_udevd=pass
udev_smoke_sdl3_gamepad_probe=0
udev_smoke_sdl3_gamepad_event_mode=1
udev_smoke_sdl3_gamepad_event_code=304
udev_smoke_sdl3_gamepad_expected_button=0
udev_smoke_sdl3_gamepad_event_sent=pass
sdl3_gamepad id=2 name=Xbox 360 Controller path=/dev/input/event9 vendor=0x045e product=0x028e type=2
sdl3_virtual_gamepad_open=pass
sdl3_gamepad_event_ready=pass
sdl3_gamepad_expected_button=0
sdl3_gamepad_button_event=pass type=0x651 which=2 button=0 state=down
sdl3_gamepad_button_event=pass type=0x652 which=2 button=0 state=up
sdl3_virtual_gamepad=pass id=2
sdl3_gamepad_probe=pass
sdl3_gamepad_event_probe=pass
sdl3_probe=pass
udev_probe=pass
native_steam_input_device_probe=pass
```

This proves the corrected A/SOUTH mapping through Android, the rooted virtual
Xbox node, and SDL3's Xbox 360 semantic layer. It still does not prove that
Steam's current language-selector page activates on A; the strict live Steam
probe above remains unchanged.

The same parameterized SDL3 probe also passed the rest of the corrected ABXY
matrix, with a down/up event for each semantic button on the exact `event9`
node:

| Android key | Linux event | SDL3 button | Result |
| --- | --- | ---: | --- |
| `KEYCODE_BUTTON_A` (96) | `BTN_SOUTH` (304) | 0 | pass |
| `KEYCODE_BUTTON_B` (97) | `BTN_EAST` (305) | 1 | pass |
| `KEYCODE_BUTTON_X` (99) | `BTN_NORTH` (307) | 2 | pass |
| `KEYCODE_BUTTON_Y` (100) | `BTN_WEST` (308) | 3 | pass |

## Visual reassessment

The earlier A run used only a panel hash difference and was recorded as
`controller_ui_navigation=pass`. Visual inspection showed that its before/after
images could be the lab surface, an Android overlay, or launcher/animation
changes, so that claim is withdrawn.

A later strict Steam-surface A attempt did show the real pre-login Steam
Gamepad UI, but the cropped navigation panel remained unchanged:

```text
controller_ui_navigation_panel_before_sha256=ce05521bd0d9933a868eceb4b8d5981633314257fc5d3f0571bc913ef85cfdd1b
controller_ui_navigation_panel_after_sha256=ce05521bd0d9933a868eceb4b8d5981633314257fc5d3f0571bc913ef85cfdd1b
```

Therefore A-button Steam UI consumption remains open. The strict Android
D-pad acceptance, including the real Steam visual gate, is in [doc
29](29-nova-android-input-steam-ui-navigation.md).

## Boundary and next steps

Proven here:

```text
Android KEYCODE_BUTTON_A
  -> corrected app/helper mapping
  -> BTN_SOUTH on the exact virtual Xbox node
  -> Steam process FD ownership
  -> no Android feedback loop
```

Not yet proven for A: Steam UI navigation, login, game launch, axes, rumble,
hardware CEF rendering, or lifecycle cleanup. Next, run strict visual tests for
B/X/Y, then add Start/Back/Guide and axis/hold semantics.
