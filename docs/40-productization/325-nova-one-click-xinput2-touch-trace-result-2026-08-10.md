# Nova one-click XInput2 touch trace result — 2026-08-10

Status: completed; XInput2 was available and event selection succeeded, but no
XI2 touch, motion, or button event was observed during the declared Android
tap. This strengthens the core-pointer result, while leaving one scope check
for a future explicit Steam-window selection.

This is the result for the [predeclared XI2 trace](323-nova-one-click-xinput2-touch-trace-predeclaration-2026-08-10.md), following the [core-pointer result](322-nova-one-click-x11-pointer-probe-result-2026-08-10.md).

## Run identity and provenance

- Run ID: `nova-one-click-xinput2-touch-trace-20260810T154904Z`
- Device: Retroid Pocket Nova, Android 13, adb serial `675a2365`, `kalama`
- Source commit: `f3e245e`
- APK SHA-256: `0d3020eb0ba8d0fa09b168f85ba088ad3cc08932a7ad36c76bad0ab4b69f5d97`
- XI2 tracer SHA-256: `0c8caf1f288b679b46f62cf2754155c0437f56e3dc42768ba6545a83479c0e13`
- Device `libXi.so.6.1.0` SHA-256:
  `43e3de807c9a1c19b61d67145625cf64bd988800a02d3126494325e46d01bb09`
- Launcher session: `20260810T155745Z-23790`
- Host evidence: `android/nova-lab/build/runs/nova-one-click-xinput2-touch-trace-20260810T154904Z/`
- Evidence manifest SHA-256:
  `27b00b8e3af633a25c8cd4d7925226c913be06d028c99261ba91f636d069a74a`

The session was started through the visible APK `Start Steam` button with no
Steam launch extras. Readiness used a session-ID transition from the previous
session, followed by a fresh signed-in Steam screenshot and Termux:X11 focus
check. The settled X11 tree identified the viewable Steam Big Picture window
as `0x1800035`, geometry `1280x800`, while Android captures were `1280x960`.

## Declared input and trace

The single controlled input was:

```text
adb shell input tap 620 545
tap UTC: 2026-08-10T15:59:32Z
```

The tracer reported:

```text
nova_xi2_extension=pass opcode=131 event_base=66 version=2.0 root=0x511
nova_xi2_select=pass root=0x511 opcode=131
nova_xi2_trace=pass seconds=10 samples=200 events=0
```

The raw trace SHA-256 is
`585c74e34ba6146dc2ab71ff423173e1b0d3d1c1e67da0d44e9a0c4ee8fa6cfd`.
The tracer selected XI2 touch begin/update/end, motion, and button events on
the X11 root window. It did not inject, grab, or alter input.

Android focus immediately before and after remained:

```text
FocusedWindows:
  displayId=0, name='ad9e333 com.termux.x11/com.termux.x11.MainActivity'
```

No `com.rp.settings` overlay owned focus. The before/after Steam screenshots
are `steam-settled-before-trace.png` (SHA-256
`3f3378ce059d8d21ae7c59ed1087468f51ab04ef1574215768a06a2f275bd611`) and
`steam-after-trace.png` (SHA-256
`bd0ea75c76e9c8e37570477d061b5669dbbfbe02ae9f6050bdc5b12c1a156616`). They
remain on the same `WHAT'S NEW` tab; animated news content is not treated as
input success.

## Teardown

The exact stop path passed:

```text
nova_x11_cleanup=pass
nova_runtime_cleanup=pass root=/data/local/tmp/nova-holo-rootfs
nova_launcher_dbus_state=absent
nova_launcher_stop=pass
```

The final targeted process audit found no Nova rootfs Steam, Termux:X11,
Gamescope, relay, or launcher-start process. Both rootfs D-Bus paths were
absent, and the APK-owned bridge-file audit was empty.

## Interpretation

This run provides fresh evidence that the declared Android tap did not reach
the selected X11 root-window XI2 event stream. Together with the prior
unchanged `XQueryPointer` position and `mask=0`, the direct Termux:X11 path has
no demonstrated Android-to-X11 touch/click delivery yet.

The result is not a claim that every XI2 event target is impossible: the
tracer selected the root window, not an explicit `Steam Big Picture Mode`
window. The next narrow diagnostic should select both the discovered Steam
window and the root, then repeat the same tap. If that also reports zero, stop
spending effort on coordinate transforms and implement an Android
MotionEvent-to-X11/libei bridge (or promote the existing Gamescope touch bridge)
for the product path. If the Steam-window selection receives XI2 events, add a
touch-to-pointer/button adapter at that boundary and retest Steam navigation.

Audio remains outside this experiment's gate and retains the corrected status:
playback is audible but delayed, not absent.
