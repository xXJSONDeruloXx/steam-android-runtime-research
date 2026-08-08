# Nova virtual gamepad udev visibility

Test date: 2026-08-08 (device report timestamps are UTC)
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740
ADB serial: `675a2365`

This checkpoint isolates the Linux device-discovery contract beneath native
Steam. The ARM64 Holo helper creates the virtual Xbox-shaped uinput device,
then a second ARM64 process uses Holo's `libudev` against the Android kernel's
mounted sysfs tree and opens the resulting event node as Steam uid 501.

Native Steam's existing console log says it selects **udev for HIDAPI joystick
device discovery**. This probe tests the prerequisite independently so a later
Steam run can distinguish “the node is invisible/unreadable” from “Steam's
HIDAPI/Steam Input layer rejected a visible node.”

## Build and run

Build and run the bounded probe:

```sh
android/nova-lab/build-uinput-gamepad-relay.sh
android/nova-lab/build-input-udev-probe.sh
android/nova-lab/deploy-native-steam-input-device-probe.sh
```

The device-side script creates a private mount namespace, makes Android's
`/dev`, `/sys`, and `/proc` visible inside the Holo rootfs, starts the rooted
uinput helper, and runs the libudev probe while the virtual event node exists.
The probe also performs a direct evdev ioctl name check and forks a child that
drops to uid 501 before opening the node.

## Accepted boundary

The accepted markers are:

```text
udev_context=pass
udev_virtual_sysfs=pass
udev_virtual_discoverable=pass
input_ioctl_name=pass
input_nonroot_uid=501
input_nonroot_open=pass
udev_probe=pass
```

This proves that the rooted Linux session can create a virtual controller,
discover it through the Holo `libudev`/sysfs path, and make it readable by the
same non-root uid used by the native Steam launcher.

The probe also records whether the udev database supplies `ID_INPUT_JOYSTICK`,
`ID_INPUT_GAMEPAD`, vendor, and model properties. Those properties are
diagnostic context, not part of the current pass condition: a node can be
visible and readable while still lacking the metadata that HIDAPI expects.

Set `NOVA_INPUT_UDEV_MODE=enabled` for the experimental comparison that starts
Holo's `systemd-udevd` inside the same namespace before creating the virtual
device. The default remains `disabled` so the baseline does not claim a udev
service is required. The enabled comparison adds these observed markers:

```text
udev_smoke_udevd=pass
udev_virtual_id_input_joystick=1
udev_virtual_id_input_gamepad=missing
udev_virtual_properties=present
```

The Holo rules therefore classify the node as a joystick once a udev daemon is
running, but they do not supply the complete gamepad/vendor property set in
this Android-backed session. That is a concrete follow-up for Steam HIDAPI,
not a reason to claim Steam navigation yet.

It does not yet prove that Steam's HIDAPI enumerator accepts the device, that
Steam Input maps it, or that Gamepad UI navigation changes state. The probe is
the next diagnostic boundary before adding udev rules or a udev daemon to the
Android session. The current Holo rootfs also has no Android udev daemon
running; this result intentionally tests direct enumeration and permissions
without claiming a complete udev service.
