# Nova Android input to rooted uinput bridge

Test date: 2026-08-07 (device report timestamps are UTC)
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740
ADB serial: `675a2365`

This is the first executable Android-to-Linux input bridge in the Nova lab. The
Nova Lab Android activity enumerates Android `InputDevice` instances and, when
the bridge flag is enabled, forwards Android key events and controller motion
axes over an Android abstract Unix socket. A rooted ARM64 helper inside the
Holo glibc chroot reads that socket, maps Android keycodes/axes to Linux evdev
codes, and emits them through a virtual Xbox-shaped `/dev/uinput` device.

The socket intentionally uses Android's abstract namespace. Android's
`LocalServerSocket(String)` constructor creates an abstract socket rather than
a filesystem node; the helper represents the same address with an `@` prefix.
See the [Android framework implementation](https://android.googlesource.com/platform/frameworks/base/+/HEAD/core/java/android/net/LocalServerSocket.java).
This lets the glibc helper cross the chroot boundary without a privileged app
data-directory bind mount.

## Build and run

Build the ARM64 rooted helper and Android APK as usual:

```sh
android/nova-lab/build-uinput-gamepad-relay.sh
android/nova-lab/build.sh
```

Run the bounded native Steam/AHB smoke first, then exercise the app input
bridge while the Nova Lab activity remains alive:

```sh
android/nova-lab/deploy-native-steam-android-input-bridge-smoke-test.sh
```

The wrapper uses five AHardwareBuffer frames by default, starts the app with
`run_android_input_bridge=true`, waits for the native Steam smoke to finish,
starts the rooted helper in `socket` mode, and sends Android keycode 96
(`KEYCODE_BUTTON_A`) with `adb shell input keyevent 96`. The helper's default
relay window is 30 seconds so the app can accept the socket under the full
Gamescope workload. Override it with
`NOVA_STEAM_ANDROID_INPUT_RELAY_TIMEOUT` when diagnosing scheduling.

The app report and helper logs are generated under the ignored
`android/nova-lab/build/` directory:

- `nova-android-input-bridge-report.txt` records the app's socket accept and
  successful write markers;
- `nova-android-input-bridge-logcat.txt` records controller enumeration and
  the Android listener;
- `nova-uinput-android-input-bridge.log` records the rooted helper's Linux
  device and mapping markers;
- `native-steam-android-input-bridge-smoke.log` contains the underlying native
  Steam/AHB run.

## Accepted Nova evidence

The Android logcat from the default-timeout run reported the physical
controller as an Android controller-class device and started the listener:

```text
android_input_device id=8 name=Xbox Wireless Controller sources=0x1000511
android_input_device_controller=pass count=7
android_input_socket=listening path=/data/user/0/com.xjsonderulo.steamandroid.novalab/files/nova-input.sock
```

The app-owned report recorded the handoff and key write:

```text
android_input_socket=listening
android_input_socket=connected
android_input_key_forwarded=pass
```

The rooted ARM64 helper reported the abstract address, virtual device, and
mapped key:

```text
uinput_source=/dev/input/event7
uinput_source_name=Xbox Wireless Controller
uinput_open=pass
uinput_device=/dev/input/event10
uinput_device_ready=pass
android_input_socket=@/data/user/0/com.xjsonderulo.steamandroid.novalab/files/nova-input.sock
android_input_socket_connected=pass
android_key_forwarded=pass
android_input_forwarded=pass
uinput_probe=pass
```

The same bounded run also returned:

```text
headless_gamescope_ahb=pass
native_steam_smoke=pass
native_steam_android_input_bridge_smoke=pass
```

## Exact boundary

This proves the Android app event → abstract Unix socket → rooted ARM64 helper
→ Linux virtual gamepad path for a deterministic Android key event. It also
proves that the bridge can be exercised alongside the already-accepted native
Steam/AHB presentation smoke.

It does not yet prove that Steam uid 501 opens the virtual device, that Steam
Input maps it, or that the Gamepad UI changes state. The formal run uses an
Android key injection rather than a physical controller gesture. A separate
controlled evdev-to-Android dispatch assertion is now accepted in
[doc 20](20-nova-physical-controller-dispatch.md). The axis mapping is
implemented but not yet covered by a device acceptance run.

Next, capture a before/after Gamepad UI state change, inspect Steam's Linux
device enumeration, and add rumble return through the same supervisor boundary.
