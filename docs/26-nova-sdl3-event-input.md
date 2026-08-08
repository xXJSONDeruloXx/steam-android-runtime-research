# Nova SDL3 virtual-controller event delivery

Test date: 2026-08-08

Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740

ADB serial: `675a2365`

This checkpoint moves one layer below the native Steam UI comparison. It
opens Valve's shipped ARM64 `libSDL3.so.0` directly, discovers and opens the
rooted virtual Xbox-shaped device, then waits for SDL3's event queue. The
rooted helper injects one exact Linux `BTN_DPAD_DOWN` press/release through
the attached physical controller source. The probe accepts only a joystick
event whose SDL instance ID matches the virtual device it opened.

This proves SDL3 discovery, open, and event delivery for the virtual device.
It does not prove that Steam's separate SDL instance, Steam Input mapping, or
the SteamUI language selector consumes the event as navigation. The event is
reported by its raw SDL event type (`0x606`); this document intentionally does
not assign that type a semantic button name.

## Reproducible test

```sh
NOVA_INPUT_SDL3_PROBE=1 \
NOVA_SDL3_EVENT_PROBE=1 \
NOVA_SDL3_EVENT_CODE=545 \
NOVA_SDL3_EVENT_TIMEOUT=10000 \
NOVA_INPUT_UDEV_MODE=enabled \
NOVA_INPUT_UDEV_RELAY_TIMEOUT=10000 \
android/nova-lab/deploy-native-steam-input-device-probe.sh
```

The probe was built with:

```sh
android/nova-lab/build-sdl3-joystick-probe.sh
```

## Accepted evidence

The live SDL3 probe reported both the physical and virtual devices, opened
the virtual instance, and matched the post-injection event to that instance:

```text
sdl3_dlopen=pass
sdl3_init=pass
sdl3_joystick_count=2
sdl3_joystick id=1 name=Xbox Wireless Controller path=/dev/input/event7 vendor=0x2022 product=0x3002
sdl3_joystick id=2 name=Nova Virtual Xbox Controller path=/dev/input/event10 vendor=0x2022 product=0x3001
sdl3_virtual_open=pass
sdl3_virtual_id=2
sdl3_event_ready=pass
sdl3_joystick_event=pass type=0x606 which=2
sdl3_virtual_joystick=pass
sdl3_event_probe=pass
sdl3_probe=pass
```

The surrounding rooted-device checks also passed in the same run:

```text
udev_smoke_udevd=pass
udev_smoke_sdl3_event_sent=pass
uinput_event_forwarded=pass
uinput_control_event_code=545
uinput_control_event=BTN_DPAD_DOWN
input_nonroot_uid=501
input_nonroot_open=pass
udev_probe=pass
native_steam_input_device_probe=pass
```

The virtual node was therefore visible to Holo `libudev`, readable as uid
501, opened by SDL3, and the exact injected event reached the matching SDL3
joystick instance. The next input investigation is the SDL3 Gamepad API and
Steam's own consumer, not another uinput-permission check.
