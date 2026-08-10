# Nova one-click X11 stretch retry result — 2026-08-10

## Decision

The productized Termux:X11 stretch profile passed its fresh-session,
presentation, preference-restore, and exact teardown gates. It is now the
preferred display path for the Nova launcher. This is not full end-user
acceptance: the run used software Steam/CEF, did not send input, left audio
disabled, and did not launch a game.

## Run identity and provenance

- Run ID: `nova-one-click-x11-stretch-retry-20260810T095931Z`
- Device: Retroid Pocket Nova, adb serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- Package: `com.xjsonderulo.steamandroid.novalab`
- Source commit: `456cba17a512bdaa8c8c386285764a307cd44850`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256: `773ff7cc263d0fe9873c8a60c10fa7063c88ec6070550c676596df62e8bdd448`
- Evidence directory:
  `android/nova-lab/build/runs/nova-one-click-x11-stretch-retry-20260810T095931Z/`

The selected launcher profile was:

```text
x11_stretch=1
x11_stretch_resolution=1280x800
hardware_accel=0
cef_disable_gpu=1
steam_ui_mode=minimal
steam_force_software_gl=1
audio_bridge=0
gamepad_relay=pass input_allow=event9
steam_flags=-fullscreen -fulldesktopres
```

No physical, synthetic, keyboard, pointer, touch, or game-launch input was
sent during this run.

## Fresh-session presentation result

The launcher rejected the previous session identity and accepted a fresh one:

```text
ready=1 poll=2 old_session=20260810T095430Z-3791 fresh_session=20260810T100141Z-11161
```

Termux:X11 reported the Nova Android surface and then the stretched X11
buffer separately:

```text
SurfaceChangedListener: Surface was changed: 1280x960
tx11-request: window changed: 1280 800 builtin
LorieNative: Sent shared buffer width 1280 stride 1280 height 800
LorieNative: Received shared buffer width 1280 stride 1280 height 800
```

The fresh X11 tree reported a viewable `1280x800` root and a viewable Steam
webhelper child at `(290,180)` with `700x440` geometry. The child was titled
`Sign in to Steam` in this run, so the existing capture helper—which only
accepts the `Steam Big Picture Mode` title—returned `capture_status=fail` even
though the X11 tree itself passed. This is a harness title-matching gap, not
evidence that the X11 surface failed to appear.

The Android screenshot was `1280x960`, SHA-256
`71954e9cc497d806cd07ceeca058c93dd1877295623ef4b846f1a46df0ed94a4`. Visual
inspection shows the Steam frame filling the stretched Android surface, with
the current Steam “Waiting for network…” dialog visible. The dialog state and
the lack of a successful X11 child PPM mean this is supporting display
evidence, not a signed-in full-library screenshot acceptance.

## Preference transaction

The launcher applied the supported Termux:X11 profile:

```text
displayResolutionMode=custom
displayResolutionExact=1280x800
displayResolutionCustom=1280x800
displayStretch=true
```

The preference file was owned by `10120:10120` with mode `660` during and
after the run. The hashes were:

```text
before 25530aa4ed8fda450e43638e2c7a00bb95d5cb1ff1c1ab18e717f32a4feb0895
during 0989cb3336c9bf61b06213a01176a81c206b8b80458358be81527c5df20fef50
after  25530aa4ed8fda450e43638e2c7a00bb95d5cb1ff1c1ab18e717f32a4feb0895
```

The stop path logged both
`nova_launcher_x11_stretch_restore=pass` and
`nova_launcher_stop=pass`. The stop wrapper now excludes its own and its
parent PID from runtime cleanup, allowing preference restoration to finish
without weakening descendant cleanup.

## Teardown

The exact X11 and runtime cleanup logs both returned `pass`. After the logs
were pulled, the two current-run Steam temp residues—a singleton directory
and Chrome shared-memory socket—plus the staged capture/relay helpers were
removed by exact path. The final audit found:

```text
matching Nova runtime processes=0
current-run rootfs residues=0
launcher state directory=absent
X11 socket children=0
preference hash restoration=pass
```

Older dated Steam and capture directories in the rootfs were not deleted;
they are outside this run's scope and may be evidence for earlier experiments.

## Follow-up

Keep this stretch profile in the one-click launcher. Improve the capture
helper to accept the current viewable Steam webhelper title or an explicitly
identified top-level Steam child, then capture a fresh stable signed-in Steam
frame. The next functional blocker remains game rendering: the small-game
matrix (198X, Peggle Deluxe, and Geometry Wars) reached Proton/DXVK in
different ways but produced no game frame; Geometry Wars ultimately stopped
at the device's missing `VK_KHR_swapchain` boundary. Do not reopen the
Gamescope/AHardwareBuffer compositor path for the display geometry result.

This run follows [34](../00-start-here/34-nova-runtime-harness-lifecycle.md).
