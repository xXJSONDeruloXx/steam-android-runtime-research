# Nova one-click X11 pointer probe result — 2026-08-10

Status: completed; the declared Android tap did not move the X11 core
pointer or produce a core button mask. The direct Termux:X11 path therefore
does not currently provide a usable Steam touch-click path through the X11
core pointer.

This is the result for the [predeclared pointer probe](321-nova-one-click-x11-pointer-probe-predeclaration-2026-08-10.md).

## Run identity and provenance

- Run ID: `nova-one-click-x11-pointer-probe-20260810T153333Z`
- Device: Retroid Pocket Nova, Android 13, adb serial `675a2365`, `kalama`
- Source commit: `e5987f5`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256: `0d3020eb0ba8d0fa09b168f85ba088ad3cc08932a7ad36c76bad0ab4b69f5d97`
- X11 helper SHA-256: `7f831a14b701f373027714560c8607f916dc8f98ff68b50d7c9271c0ae5d187c`
- Launcher session: `20260810T153848Z-12814`
- Host evidence: `android/nova-lab/build/runs/nova-one-click-x11-pointer-probe-20260810T153333Z/`
- Evidence manifest SHA-256:
  `f8b9fc79938dcfb84dc8ea3f0721684054890c6bed2c97b7269221828c5feebf`

The session used the visible APK `Start Steam` button and the default prepared
profile, with no Steam launch extras. The first generic launcher-ready poll
was rejected as potentially stale because the state file still contained the
previous session's marker. The current session ID and new launcher PIDs were
then correlated with the live X11/Steam surface before the probe began.

## Fresh display and focus gate

The X11 tree discovered a fresh viewable Steam window:

```text
nova_x11_window id=0x1800035 parent=0x511 depth=1 map_state=viewable x=0 y=0 width=1280 height=800 name="Steam Big Picture Mode" res_name="steamwebhelper" res_class="steam"
```

Android captures were 1280x960. The fresh signed-in Steam home surface was
captured before the tap (`steam-client-ready.png`, SHA-256
`1a6783699c4c63e41f265f5d502aebcf15e7460a8c48474adcc48b5e77dca61c`) and
after the tap (`steam-after-pointer-tap.png`, SHA-256
`433559884085262290bf4738f8f24307c1792441140f61d71d59ccfd744ca164`).

Immediately before and after the controlled input, Android reported:

```text
FocusedWindows:
  displayId=0, name='23ceacd com.termux.x11/com.termux.x11.MainActivity'
```

No `com.rp.settings` window owned focus. The before/after screenshots remain
on the `WHAT'S NEW` Steam tab; the changing green Friends notification is an
animated/state update, not evidence of navigation.

## Pointer result

The probe ran for 10 seconds, sampled every 50 ms, and completed with:

```text
nova_x11_pointer_probe=pass seconds=10 samples=200
```

The single declared input was:

```text
adb shell input tap 620 545
tap UTC: 2026-08-10T15:42:31Z
```

Every sample reported the same values:

```text
same_screen=1 root_x=640 root_y=400 window_x=640 window_y=400 mask=0x0 child=0x1800035
```

The pointer-probe log SHA-256 is
`9867847d3d34a3b3623ad50711b4556ed1fc32a1b867a5cf28549b38ed556c21`.

This proves that the tap did not move the X11 core pointer and did not leave a
core button/modifier mask observable through `XQueryPointer`. It does not yet
prove that the X server emitted no XInput2 touch event; the helper intentionally
observed the core pointer only and did not select, grab, or inject events.

## Teardown

The first direct-stop attempt intentionally failed closed because the command
omitted the Termux:X11 APK argument and therefore did not supply the app asset
directory to the launcher. The corrected exact stop command then passed:

```text
nova_x11_cleanup=pass
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs attempts=1 term_pids=12953 kill_pids= remaining=
nova_launcher_dbus_state=absent
nova_launcher_stop=pass
```

The final targeted process audit found no Nova rootfs Steam, Termux:X11,
Gamescope, relay, or launcher-start process. Both rootfs D-Bus paths were
absent, and the APK-owned bridge-file audit was empty.

## Conclusion and next experiment

The failure is now localized above Steam navigation and below Steam's UI: the
default Android `input tap` did not reach the Termux:X11 core pointer. Do not
try another coordinate transform on the basis of this run; there was no
observed coordinate to transform.

The next narrow experiment should add an XInput2 read-only trace to the same
helper (or a separate helper) and repeat one tap. That will distinguish
Termux:X11 touch events from complete input loss. If XI2 touch events are
present, the next fix belongs in the X11/Steam touch contract. If they are
absent, the product path needs an Android MotionEvent-to-X11/libei bridge or
the existing app-owned Gamescope touch bridge. The result does not change the
known-good audio finding: audio output is audible but delayed, not absent.

This run did not alter the one-click defaults, Gamescope/AHardwareBuffer,
Vulkan WSI, audio buffering, networking, or the test-bench APK.
