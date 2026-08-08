# Nova physical controller dispatch through the Android app

Test date: 2026-08-07 (device report timestamps are UTC)
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740
ADB serial: `675a2365`

This is the next input checkpoint after [doc 19](19-nova-android-input-uinput-bridge.md).
It verifies that a Linux evdev event from the attached controller is delivered to
the Android activity as a controller-class `KeyEvent`, then crosses the app-owned
abstract socket into the rooted ARM64 uinput helper.

The event is injected with root using Android's `sendevent` command. That is a
controlled kernel-input test, not a claim that a human physically pressed the
button during the run. It exercises the same evdev-to-Android input dispatch path
that a physical button press uses.

## Build and run

Build the updated app and rooted relay:

```sh
android/nova-lab/build-uinput-gamepad-relay.sh
android/nova-lab/build.sh
```

Run the bounded physical-dispatch smoke:

```sh
NOVA_STEAM_ANDROID_INPUT_MODE=physical \
NOVA_STEAM_CLIENT_TIMEOUT=5 \
NOVA_STEAM_GAMESCOPE_TIMEOUT=15 \
android/nova-lab/deploy-native-steam-android-input-bridge-smoke-test.sh
```

The wrapper uses the attached controller node `/dev/input/event7` by default
and injects Linux code `305` (`BTN_EAST`). On this Nova that event is delivered
to the activity as Android keycode `97`. Override the source node with
`NOVA_STEAM_GAMEPAD_SOURCE` and the injected Linux code with
`NOVA_STEAM_ANDROID_INPUT_EVENT_CODE` when reproducing on another setup.

The native Steam/AHardwareBuffer smoke is run first in the same workflow. The
rooted input helper is then started while the Nova Lab activity remains alive;
this ordering avoids the full Gamescope workload starving the app's socket
accept thread.

## Accepted Nova evidence

The app enumerated the attached controller as an Android controller-class device:

```text
android_input_device id=8 name=Xbox Wireless Controller sources=0x1000511
android_input_device_controller=pass count=7
```

The controlled evdev event reached `Activity.dispatchKeyEvent` with a real
controller device id and controller source bits:

```text
android_input_key_event device=8 keycode=97 source=0x501
```

The app report recorded the socket handoff and Android key write:

```text
android_input_socket=listening
android_input_socket=connected
android_input_key_forwarded=pass
```

The rooted ARM64 helper recorded the virtual-device handoff:

```text
uinput_source=/dev/input/event7
uinput_source_name=Xbox Wireless Controller
uinput_open=pass
uinput_device_permissions=pass
uinput_device=/dev/input/event10
uinput_device_ready=pass
android_input_socket_connected=pass
android_key_forwarded=pass
android_input_forwarded=pass
uinput_probe=pass
```

The same bounded workflow returned the already-accepted presentation markers:

```text
headless_gamescope_ahb=pass
native_steam_smoke=pass
native_steam_android_input_bridge_smoke=pass
```

## Exact boundary

This proves the physical-controller-shaped kernel event path:

```text
evdev BTN_EAST
  -> Android InputReader/InputDevice
  -> Activity.dispatchKeyEvent
  -> Android abstract Unix socket
  -> rooted ARM64 helper
  -> virtual Linux uinput gamepad
```

It does not yet prove that Steam uid 501 opens the virtual device, that Steam
Input maps it, that the Gamepad UI changes state, or that rumble returns through
the helper. The accepted run does not inject axes, and it does not replace a
real human-button test. Those are the next input/session gates.
