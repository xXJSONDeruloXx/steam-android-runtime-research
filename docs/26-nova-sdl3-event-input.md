# Nova SDL3 joystick event delivery: target-selection pitfall

Test date: 2026-08-08

Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740

ADB serial: `675a2365`

This file preserves the first SDL3 event experiment from commit `58d8848`,
but its result is superseded by [doc 27](27-nova-sdl3-gamepad-event.md).

The original probe selected a device by the human-readable name
`Nova Virtual Xbox Controller`. The Nova lab can contain two nodes with that
same name: the deterministic relay-created node and a second node left by the
Android input activity. In the affected run the probe reported `/dev/input/event10`,
so the output did not prove that SDL observed the relay-created instance. A
device name is not a sufficient identity key for this test.

The relay and SDL probe now resolve and pass the exact event path. The current
identity-safe semantic result is recorded in [doc 27](27-nova-sdl3-gamepad-event.md).

## Historical command

```sh
NOVA_INPUT_SDL3_PROBE=1 \
NOVA_SDL3_EVENT_PROBE=1 \
NOVA_SDL3_EVENT_CODE=545 \
NOVA_SDL3_EVENT_TIMEOUT=10000 \
NOVA_INPUT_UDEV_MODE=enabled \
NOVA_INPUT_UDEV_RELAY_TIMEOUT=10000 \
android/nova-lab/deploy-native-steam-input-device-probe.sh
```

The historical result was useful for finding the SDL3 boundary, but it is not
the accepted proof for Steam input. The remaining question is whether Steam's
own SDL/Gamepad consumer consumes the exact event and turns it into SteamUI
navigation.
