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

It does not yet prove that Steam's HIDAPI enumerator accepts the device, that
Steam Input maps it, or that Gamepad UI navigation changes state. The probe is
the next diagnostic boundary before adding udev rules or a udev daemon to the
Android session. The current Holo rootfs also has no Android udev daemon
running; this result intentionally tests direct enumeration and permissions
without claiming a complete udev service.
