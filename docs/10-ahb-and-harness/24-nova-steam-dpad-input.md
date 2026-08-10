# Nova D-pad semantic Steam UI input probe

Test date: 2026-08-08 (device report timestamps are UTC)

Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740
ADB serial: `675a2365`

The A-button probe in [doc 23](23-nova-steam-controller-ui-input.md)
could have failed because of an A/B or button-label mapping issue. This
follow-up uses Linux `BTN_DPAD_DOWN` (code 545), which should move the
language-list selection if Steam's Gamepad UI is consuming the virtual
controller.

## Reproducible test

```sh
NOVA_CONTROLLER_UI_EVENT_CODE=545 \
NOVA_CONTROLLER_UI_EVENT_NAME=BTN_DPAD_DOWN \
NOVA_CONTROLLER_UI_EXPECT_NAVIGATION=1 \
android/nova-lab/deploy-native-steam-controller-ui-input-smoke-test.sh
```

The harness now accepts any bounded Linux key code through
`NOVA_CONTROLLER_UI_EVENT_CODE`, makes the relay stop on that exact key-down,
and checks the same right-hand navigation region before and after.

## Result

The run's lower-level markers passed:

```text
controller_ui_source_ready=1
controller_ui_relay_ready=1
controller_ui_surface=pass
controller_ui_event=BTN_DPAD_DOWN code=545
uinput_source=/dev/input/event7
uinput_device=/dev/input/event10
uinput_event_forwarded=pass
uinput_control_event_code=545
uinput_control_event=BTN_DPAD_DOWN
steam_input_process pid=8782 name=steam fd=/proc/8782/fd/93 target=/data/local/tmp/nova-holo-rootfs/dev/input/event10
steam_input_fd=pass
steam_input_fd_probe=pass
headless_gamescope_ahb=pass
native_steam_smoke=pass
```

The explicit semantic assertion failed as expected:

```text
controller_ui_navigation_panel_before_sha256=ce05521bd0d993a868eceb4b8d5981633314257fc5d3f0571bc913ef85cfdd1b
controller_ui_navigation_panel_after_sha256=ce05521bd0d993a868eceb4b8d5981633314257fc5d3f0571bc913ef85cfdd1b
controller_ui_navigation=none
expected controller UI navigation was not observed
```

The center greeting continued to rotate through localized strings, but the
language-list panel did not move. This rejects the narrow “the A mapping is
wrong” hypothesis: both a face-button event and a D-pad event reach the
virtual node while Steam owns its FD, yet Steam Gamepad UI navigation remains
unproven. The next seam is Steam's higher-level input consumption, not uinput
device creation. [Doc 25](25-nova-android-input-steam-ui.md) also exercises the
Android app's abstract input bridge with motion forwarding disabled and reaches
the same negative UI boundary.
