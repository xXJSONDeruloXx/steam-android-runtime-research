# Nova Gamescope libei input seam

Test date: 2026-08-07
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740
ADB serial: `675a2365`

This is the first live input-control result for the rooted Nova session. The
patched ARM64 Gamescope build can enable its existing libei server, the Holo
rootfs contains the matching runtime libraries, and a small ARM64 sender can
connect to Gamescope's EIS socket, discover a keyboard device, send an evdev
scancode, and receive a protocol round trip.

It does not yet prove Android controller navigation. Gamescope's current libei
server exposes keyboard, pointer, button, scroll, and absolute-pointer
capabilities; the probe deliberately exercises only the keyboard capability.
The next controller-specific boundary is an Android input mapping to a Linux
gamepad/HID or an equivalent Steam-compatible path.

## Build and run

The existing Gamescope build keeps input emulation disabled by default. Enable
it explicitly when building the disposable binary:

```sh
NOVA_GAMESCOPE_INPUT_EMULATION=enabled \
  android/nova-lab/build-gamescope-headless.sh
android/nova-lab/build-libei-key-probe.sh
```

The Holo `gamescope` package closure already supplies `libei.so`/`libeis.so`
inside the rootfs. The repeatable smoke deploys the probe, starts the native
ARM64 Steam session, waits for `gamescope-0-ei`, sends Enter (`KEY_ENTER`,
scancode 28 by default), and then lets the normal Gamescope/AHardwareBuffer
report finish:

```sh
NOVA_AHB_FRAME_COUNT=60 \
NOVA_STEAM_CLIENT_TIMEOUT=45 \
NOVA_STEAM_GAMESCOPE_TIMEOUT=55 \
android/nova-lab/deploy-native-steam-input-smoke-test.sh
```

Set `NOVA_STEAM_INPUT_KEYCODE` to another Linux evdev scancode for a focused
probe. The raw outputs are written under the ignored `android/nova-lab/build/`
directory:

```text
native-steam-input-smoke.log
nova-libei-key-probe.log
device-gamescope-headless-ahb-report.txt
device-gamescope-headless-ahb-logcat.txt
```

## Accepted run

The accepted run returned the existing presentation result plus the new input
markers:

```text
headless_gamescope_ahb=pass
native_steam_smoke=pass
libei_socket=/tmp/gamescope-0-ei
libei_connect=pass
libei_keyboard_seat=pass
libei_keyboard_device=pass
libei_device_resumed=pass
libei_key_sent=pass
libei_roundtrip=pass
libei_probe=pass
native_steam_input_smoke=pass
```

Gamescope independently logged:

```text
Successfully initialized libei for input emulation!
```

The client still starts as uid 501, reaches the native Steam smoke timeout
normally, and retains the same software CEF boundary documented in
[doc 15](15-nova-steam-ui-ahb-smoke.md). The EIS round trip proves that an
app-side control client can reach the compositor while the Steam session is
alive; it does not prove that the Enter event changed Steam's UI state.

## Remaining input work

- Map Android `InputDevice` and touch events into a long-lived app-owned input
  client instead of a one-shot diagnostic process.
- Exercise a Steam Gamepad UI navigation action and capture before/after UI
  state.
- Add a Linux gamepad/HID path for D-pad, face buttons, analog axes, and rumble;
  EIS keyboard events are not a substitute for those controls.
- Tie input-client start/stop to the Android Linux-session supervisor and prove
  cleanup when Gamescope or Steam exits.
