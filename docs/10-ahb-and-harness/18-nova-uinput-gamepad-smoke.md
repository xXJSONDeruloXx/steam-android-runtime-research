# Nova rooted uinput gamepad smoke

Test date: 2026-08-07 (device report timestamps are UTC)
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740
ADB serial: `675a2365`

This is the first controller-shaped Linux input result for the rooted Nova
session. Android already exposes an attached `Xbox Wireless Controller` as
`/dev/input/event7`; root can read that node and `/dev/uinput` is writable. A
small ARM64 Holo-rootfs helper creates a virtual Xbox-style event device,
copies the physical controller's key/axis capabilities, makes the new node
readable by the non-root Steam uid, and forwards evdev events into it.

This proves the kernel-side input bridge only. It does not yet prove that Steam
opens the virtual device, that Steam Input maps the controller, or that a
Gamepad UI action changes the rendered screen.

## Build and run

Build the disposable ARM64 helper:

```sh
android/nova-lab/build-uinput-gamepad-relay.sh
```

Run the relay alongside the accepted native Steam session:

```sh
android/nova-lab/deploy-native-steam-gamepad-input-smoke-test.sh
```

The wrapper defaults to a non-synthetic relay. For the kernel read-back
self-test, use `NOVA_STEAM_GAMEPAD_MODE=self-test`; it emits and reads back the
known-present `BTN_EAST` code. To test physical-to-virtual forwarding
deterministically, inject a `BTN_EAST` event into the attached controller event
node as root:

```sh
NOVA_STEAM_GAMEPAD_MODE=relay \
NOVA_STEAM_GAMEPAD_INJECT=1 \
android/nova-lab/deploy-native-steam-gamepad-input-smoke-test.sh
```

`NOVA_STEAM_GAMEPAD_SOURCE` selects another evdev node, and
`NOVA_STEAM_GAMEPAD_INJECT_CODE` selects the Linux evdev code used by the
diagnostic injection. The raw helper and session logs are kept under the
ignored `android/nova-lab/build/` directory.

## Accepted kernel-side evidence

The helper self-test returned:

```text
uinput_source=/dev/input/event7
uinput_source_name=Xbox Wireless Controller
uinput_open=pass
uinput_device_permissions=pass
uinput_device=/dev/input/event10
uinput_device_ready=pass
uinput_self_test=pass
uinput_probe=pass
```

The deterministic forwarding run returned the same device markers plus:

```text
uinput_event_forwarded=pass
uinput_probe=pass
headless_gamescope_ahb=pass
native_steam_smoke=pass
```

The virtual device advertised the source controller's four axes, two hat
axes, and Xbox-style buttons. The new node was `/dev/input/event10` during
the run and was given mode `0666` so Steam uid 501 is not blocked by Android's
`root:input` event-node permissions.

## Exact boundary and next step

The physical-to-uinput seam is now a repeatable rooted diagnostic. The
`sendevent` injection is deliberately not an Android app input bridge and the
run does not claim Steam navigation; it only proves that a Linux-compatible
gamepad device can be created and fed while the Steam session is alive. The
app-side Android key/socket extension is recorded separately in
[doc 19](19-nova-android-input-uinput-bridge.md).

The controlled physical-controller dispatch checkpoint is now recorded in
[doc 20](20-nova-physical-controller-dispatch.md). Next, test whether Steam uid
501 actually enumerates the virtual device and whether rumble can return through
the same root helper.
