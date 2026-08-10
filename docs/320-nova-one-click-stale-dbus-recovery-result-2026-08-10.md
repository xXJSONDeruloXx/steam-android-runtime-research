# Nova one-click stale system-D-Bus recovery result — 2026-08-10

Status: stale-D-Bus recovery passed from the exact failure state in run 318.
The same session produced a valid signed-in Steam surface and lossless audio,
but the predeclared touch tap did not navigate the selected Steam tab.

## Run identity and provenance

- Experiment: `nova-one-click-stale-dbus-20260810T152437Z`
- Launcher session: `20260810T152514Z-9734`
- Device: Retroid Pocket Nova, Android 13, adb serial `675a2365`, `kalama`
- Source commit: `cb6fd37`
- APK SHA-256: `cce9e018344029c20dc80b23711c5d7831b82b8d209a03587171809d4a4f473f`
- Start mode: visible APK `Start Steam` button; no Steam launch extras
- Host evidence: `android/nova-lab/build/runs/nova-one-click-stale-dbus-20260810T152437Z/`

The preflight snapshot confirmed both stale objects before launch:

```text
/data/local/tmp/nova-holo-rootfs/run/dbus/pid
/data/local/tmp/nova-holo-rootfs/run/dbus/system_bus_socket
```

## Recovery result

The new launcher emitted:

```text
nova_launcher_dbus_state=cleared
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The fresh Steam client then recorded:

```text
client_dbus_system_status=pass
client_dbus_system_client_probe=pass
client_dbus_session_status=pass
client_dbus_session_client_probe=pass
client_started=pass
```

The settled `1280x960` screenshot shows the signed-in Steam Big Picture home
surface. Its SHA-256 is
`5d067f7fb733b2a43421895f9bfab339d403ef630590339fcbf65921d7093103`.

## Audio and cleanup

The default APK path still enabled the tested audio bridge. One naturally
closed stream matched exactly:

```text
C preload attempted: 1898496 frames
C preload sent:      1898496 frames
Android accepted:    1898496 frames
short_writes=0
zero_writes=0
send_failures=0
```

The exact launcher stop logged `nova_launcher_dbus_state=absent`, returned
`nova_launcher_stop=pass`, `nova_x11_cleanup=pass`, and
`nova_runtime_cleanup=pass`. The post-stop checks found neither rootfs D-Bus
object and no matching Nova process.

## Touch subtest boundary

Input focus was the Termux:X11 Activity both before and after the tap:

```text
FocusedWindows: com.termux.x11/com.termux.x11.MainActivity
```

The before/after screenshot hashes were:

```text
before: 5d067f7fb733b2a43421895f9bfab339d403ef630590339fcbf65921d7093103
after:  6f6607c29a52815c5ec012e7daf5d646fd38c49531a2900f0a4725f20596d8f6
```

The full-screen hash changed because Steam's animated home/news scene moved,
but the cropped navigation row at the tap target was byte-identical:

```text
navigation_before: 7b6ee2d6b0df49c2cccee317d192d2a9733f08c97ececcbc4b4f15d11e956f3a
navigation_after:  7b6ee2d6b0df49c2cccee317d192d2a9733f08c97ececcbc4b4f15d11e956f3a
```

Therefore the `(620,545)` tap is not accepted as Steam touch navigation. The
focus evidence rules out the Nova settings overlay, while the identical
navigation crop rules out using the full-screen hash as a touch claim. The
remaining question is whether the Android/Termux:X11 touch mapping reaches the
X11 pointer coordinate expected by Steam, or whether Steam Gamepad UI requires
a different pointer/tap path.

## Next step

Keep the stale-D-Bus guard. Predeclare a separate touch-coordinate/input
experiment with an X11-side pointer trace or window capture, then test one
coordinate transformation at a time. Do not change Steam profile, audio, or
runtime cleanup in that experiment. The native Gamescope/AHardwareBuffer touch
path remains a separate product gate.
