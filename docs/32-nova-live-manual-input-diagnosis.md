# Nova live manual input diagnosis

Test date: 2026-08-08 (device report timestamps are UTC)  
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740  
ADB serial: `675a2365`

This checkpoint explains why a device interaction appeared to do nothing while
the Steam language selector was visible, and records the corrected manual-session
path.

## What the original presses proved

The on-device D-pad presses were visible in Android logcat. The source was the
Nova's controller-class input device (`source=0x1000010`):

```text
android_input_key_dispatch keycode=20 action=0 source=0x1000010
android_input_key_dispatch keycode=20 action=1 source=0x1000010
android_input_key_dispatch keycode=19 action=0 source=0x1000010
android_input_key_dispatch keycode=19 action=1 source=0x1000010
```

That attempt did not have a live downstream session. The app then recorded:

```text
android_input_socket_write_failed
java.io.IOException: Broken pipe
```

At the same time, no Gamescope, Steam, or uinput relay process was running. The
language-selector image was the last presented AHardwareBuffer, not an active
Steam session. The lack of visible response was therefore expected and was not
evidence of a slow D-pad path.

## Two manual-session fixes

The first manual-session draft still used the bounded `relay-once-code` mode.
Manual mode now uses the continuous `relay` mode, so an unrelated face-button
press cannot end the physical relay.

The libei helper was also originally a one-touch probe: it intentionally exited
after the first touch-up so the bounded smoke test could verify a round trip.
Manual mode now passes the `continuous` argument. Its repeated-touch evidence is:

```text
libei_touch_mode=continuous
android_touch_socket_connected=pass
libei_touch_device_resumed=pass
android_touch_event_received action=0 pointer=0 x=0.07812 y=0.52083
libei_touch_up_sent=pass pointer=0
android_touch_event_received action=0 pointer=0 x=0.07812 y=0.62500
libei_touch_up_sent=pass pointer=0
```

The bridge process remained alive after both gestures and no new
`android_touch_socket_write_failed` marker appeared. Bounded smoke tests keep
their original one-touch behavior.

## Current manual-session boundary

The current live session has these transport markers:

```text
launch_flags run_dmabuf_double_buffer=true frame_count=-1 frame_size=1280x960
presentation fullscreen=true size=1280x960
surface_changed format=1 size=1280x960
uinput_source=/dev/input/event7
uinput_device=/dev/input/event9
uinput_relay=begin
```

Steam retains an FD for the exact virtual `Nova Virtual Xbox Controller` node.
The controlled D-pad event traverses `/dev/input/event7` into `/dev/input/event9`,
but the latest manual screenshot comparison did not show a language-panel change.
That leaves the remaining D-pad question at Steam Gamepad UI consumption/focus,
not Android dispatch, libei, uinput creation, or the 4:3 presentation path. The
earlier accepted D-pad experiments remain documented in [doc 28](28-nova-steam-dpad-navigation.md)
and [doc 29](29-nova-android-input-steam-ui-navigation.md); this latest manual
run does not extend that acceptance claim.

## Reproducible operator command

```sh
android/nova-lab/deploy-native-steam-manual-session.sh
```

The session presents at 1280×960, keeps both input bridges alive, and remains in
the foreground while mirroring output to the build log. Stop it with Ctrl-C or
from another terminal with:

```sh
android/nova-lab/deploy-native-steam-manual-session.sh stop
```

The bounded test logs and captures remain under the ignored
`android/nova-lab/build/` directory. The manual session must remain the focused
Android Activity for its Surface and touch socket to stay attached; if Android's
Launcher force-stops or backgrounds the Activity, the displayed frame can become
stale again even if rootfs children have not yet unwound.

The stale-child failure mode is now covered by the shared exact-scope cleanup
helper and artifact metadata gate in [doc 34](34-nova-runtime-harness-lifecycle.md).
