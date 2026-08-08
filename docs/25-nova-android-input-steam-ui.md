# Nova Android input bridge in the live Steam UI session

Test date: 2026-08-08

Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740

ADB serial: `675a2365`

This is the first live UI test driven through the Android app's input bridge
rather than by writing directly to the physical evdev node. The Nova Lab
activity receives Android `KEYCODE_DPAD_DOWN`, writes it to its abstract Unix
socket, and the rooted ARM64 helper maps it to Linux `BTN_DPAD_DOWN` (code
545) on the virtual Xbox-shaped uinput device.

This document preserves the earlier negative comparison. The corrected
identity-safe and focus-safe Android acceptance is recorded in
[doc 29](29-nova-android-input-steam-ui-navigation.md).

The test uses key-only bridge mode so background Android controller motion
cannot explain a UI change. The harness also waits for both the app socket and
the Holo chroot's bind-mounted physical source before creating the virtual
device; either prerequisite alone is an invalid setup.

## Reproducible test

```sh
NOVA_CONTROLLER_UI_INPUT_MODE=android-keyevent \
NOVA_CONTROLLER_UI_ANDROID_KEYCODE=20 \
NOVA_CONTROLLER_UI_ANDROID_KEY_NAME=KEYCODE_DPAD_DOWN \
NOVA_CONTROLLER_UI_EVENT_CODE=545 \
NOVA_CONTROLLER_UI_EVENT_NAME=BTN_DPAD_DOWN \
NOVA_CONTROLLER_UI_ANDROID_KEY_ONLY=1 \
NOVA_CONTROLLER_UI_EXPECT_NAVIGATION=1 \
android/nova-lab/deploy-native-steam-controller-ui-input-smoke-test.sh
```

`NOVA_CONTROLLER_UI_EXPECT_NAVIGATION=1` intentionally makes the run fail
when the selector region is unchanged. The nonzero status is therefore the
semantic result, not a transport failure.

## Accepted transport evidence

The rooted helper recorded the exact Android-to-Linux mapping:

```text
uinput_source=/dev/input/event7
uinput_source_name=Xbox Wireless Controller
uinput_open=pass
uinput_device=/dev/input/event10
uinput_device_ready=pass
android_input_socket=@/data/user/0/com.xjsonderulo.steamandroid.novalab/files/nova-input.sock
android_input_socket_connected=pass
android_key_forwarded=pass
android_input_keycode=20
android_input_linux_code=545
android_input_linux_event=BTN_DPAD_DOWN
android_axis_forwarded=none
android_input_forwarded=pass
uinput_probe=pass
```

The app report recorded the socket and activity dispatch:

```text
android_input_socket=listening
android_input_socket=connected
android_input_key_forwarded=pass
android_input_key_event device=69 keycode=20 source=0x1000010
```

The same native session also passed the process-level Steam observation:

```text
steam_input_process pid=22612 name=steam fd=/proc/22612/fd/95 target=/data/local/tmp/nova-holo-rootfs/dev/input/event10
steam_input_fd=pass
steam_input_fd_probe=pass
headless_gamescope_ahb=pass
native_steam_smoke=pass
controller_ui_android_input_bridge=pass
```

## UI result

The semantic assertion failed because the selector-region hashes were
identical:

```text
controller_ui_navigation_panel_before_sha256=ce05521bd0d993a868eceb4b8d5981633314257fc5d3f0571bc913ef85cfdd1b
controller_ui_navigation_panel_after_sha256=ce05521bd0d993a868eceb4b8d5981633314257fc5d3f0571bc913ef85cfdd1b
controller_ui_navigation=none
expected controller UI navigation was not observed
```

The center greeting changed as part of Steam's localization animation, but
the language-list selection did not. The accepted boundary is therefore:

```text
Android Activity.dispatchKeyEvent
  -> abstract LocalServerSocket
  -> rooted ARM64 helper
  -> Linux BTN_DPAD_DOWN on /dev/uinput
  -> Steam process owns the virtual-node FD
```

The final SteamUI consumption/navigation step remains unproven. An earlier
non-isolated exploratory run showed one panel-hash transition while Android
motion forwarding was also active; the key-only assertion run above did not
reproduce it, so that transient observation is not counted as navigation
evidence.
