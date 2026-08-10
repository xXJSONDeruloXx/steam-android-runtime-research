# Nova native Steam input process FD probe

Test date: 2026-08-08 (device report timestamps are UTC)
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740
ADB serial: `675a2365`

This checkpoint advances the input result from “Holo `libudev` and Valve SDL3
can see/open the node” to an observation inside the live native Steam session.
The test starts the existing rooted physical-controller-to-uinput relay and
the accepted native Steam/AHardwareBuffer smoke, then scans the rooted Android
process table for the exact virtual event node. It does not inject or preload
anything into Steam.

## Reproducible test

```sh
android/nova-lab/deploy-native-steam-input-fd-probe.sh
```

The wrapper keeps Holo package installation disabled by default, runs the
existing gamepad smoke, and starts
`device/nova-steam-input-fd-probe.sh` as root. The device probe discovers every
`Nova Virtual Xbox Controller` event node and checks the FDs of `steam` and
`steamwebhelper` until it finds an exact path match.

## Accepted result

The Nova run returned:

```text
steam_input_fd_target=/data/local/tmp/nova-holo-rootfs/dev/input/event10
steam_input_process pid=10104 name=steam exe=/data/local/tmp/nova-holo-rootfs/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam fd=/proc/10104/fd/94 target=/data/local/tmp/nova-holo-rootfs/dev/input/event10
steam_input_fd=pass
steam_input_fd_probe=pass
headless_gamescope_ahb=pass
native_steam_smoke=pass
native_steam_gamepad_input_smoke=pass
native_steam_input_fd_probe=pass
```

This is process-level evidence that the native Steam ARM64 client retains an
open FD for the rooted virtual controller while the Steam session is alive.
Together with [doc 21](21-nova-input-udev-device-visibility.md), it closes
the node visibility/open boundary that was previously only tested by isolated
probes.

It still does not prove that a button/axis event reaches Steam Input, that
Steam maps the device to a controller profile, that Gamepad UI navigation
changes state, or that rumble returns to Android. The next test should pair
this FD observation with a controlled event and a before/after SteamUI artifact.
