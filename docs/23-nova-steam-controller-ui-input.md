# Nova controlled Steam Gamepad UI input boundary

Test date: 2026-08-08 (device report timestamps are UTC)  
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740  
ADB serial: `675a2365`

This checkpoint combines the rooted physical-controller relay, the native
Steam/AHardwareBuffer smoke, and the process-level FD probe. It injects one
controlled Linux `BTN_SOUTH` (the Xbox-style A button) after the pre-login
Gamepad UI is visibly present, then records separate surface and navigation
region artifacts.

## Reproducible test

The wrapper requires host `ffmpeg` for surface-region extraction:

```sh
android/nova-lab/deploy-native-steam-controller-ui-input-smoke-test.sh
```

Its default profile is the known-good long native-session profile:
(120 AHardwareBuffer frames, 180-second Steam client timeout, and
220-second Gamescope timeout). Set
`NOVA_CONTROLLER_UI_EXPECT_NAVIGATION=1` when a future run should fail unless
the semantic navigation region changes.

The wrapper:

1. starts native ARM64 Steam before creating the virtual controller;
2. starts the rooted relay in `relay-once` mode;
3. waits for SteamUI readiness and a non-black Steam surface;
4. injects `BTN_SOUTH` into the physical `/dev/input/event7`;
5. captures the before/after surface and the right-hand language-selector
   region; and
6. verifies that native Steam holds an FD for the exact virtual event node.

## Accepted transport result

The final Nova run returned:

```text
controller_ui_source_ready=1
controller_ui_relay_ready=1
controller_ui_surface=pass
controller_ui_surface_yhigh=48
controller_ui_event=BTN_SOUTH
uinput_source=/dev/input/event7
uinput_source_name=Xbox Wireless Controller
uinput_device=/dev/input/event10
uinput_event_forwarded=pass
uinput_control_event=BTN_SOUTH
steam_input_process pid=636 name=steam fd=/proc/636/fd/93 target=/data/local/tmp/nova-holo-rootfs/dev/input/event10
steam_input_fd=pass
steam_input_fd_probe=pass
headless_gamescope_ahb=pass
native_steam_smoke=pass
native_steam_controller_ui_input_smoke=pass
```

This is stronger than an isolated uinput or SDL3 check: the exact physical
button event was observed by the ARM64 relay, and the live native Steam
process retained an FD for the virtual event node during the same session.

## UI result

The before surface was a visible Steam Gamepad UI language selector. The
20-second after capture showed another localized greeting, but the selector
panel itself was unchanged:

```text
controller_ui_after_delay=20
controller_ui_navigation_panel_before_sha256=ce05521bd0d993a868eceb4b8d5981633314257fc5d3f0571bc913ef85cfdd1b
controller_ui_navigation_panel_after_sha256=ce05521bd0d993a868eceb4b8d5981633314257fc5d3f0571bc913ef85cfdd1b
controller_ui_navigation=none
```

The full surface hash changed because the center greeting cycles through
localized strings. That is presentation animation, not evidence that Steam
accepted A or advanced the OOBE. The before/after screenshots remain in the
ignored build directory:

```text
android/nova-lab/build/native-steam-controller-ui-before.png
android/nova-lab/build/native-steam-controller-ui-after.png
```

The current boundary is therefore: virtual-device creation, SDL3 discovery,
native Steam FD ownership, and exact event forwarding pass; Steam Input/Gamepad
UI consumption and navigation are still unproven. The D-pad follow-up in
[doc 24](24-nova-steam-dpad-input.md) also leaves the selector unchanged, so the
next investigation should move above uinput creation toward Steam's
higher-level input path or an alternative compositor/keyboard route.
