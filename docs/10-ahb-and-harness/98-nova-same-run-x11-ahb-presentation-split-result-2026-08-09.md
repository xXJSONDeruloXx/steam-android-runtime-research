# Nova same-run X11/AHB presentation split result — 2026-08-09

Status: X11 diagnostic passed; visible Steam presentation remains rejected.

## Run identity and provenance

```text
run_id=controller-ui-20260809T-x11-ahb-presentation-split
profile=controller-ui-x11-ahb-presentation-split
run_started_utc=2026-08-09T10:23:45Z
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
gamescope=/tmp/nova-gamescope-frame-identity-final.AOqe48/out-libei/src/gamescope
gamescope_sha256=f7035c838a2e9e91a36c388d00832709d941afdf12e1fb08dd377085dfe3b22c
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
gamescope_source_status_sha256=d8554a591ad45ff80921c48b581bb32857b4e365c978e1b963002ab242c306d3
gamescope_source_diff_sha256=ed675c36d4e8a01f85246a719a7a1edb68e337a5ffa953d028be5f87eaf99220
gamescope_source_submodules_sha256=ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
apk=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/nova-lab-debug.apk
apk_sha256=5fdc843d277bf4270bf700a972fb73fddb25f464c68e644204111a3667a88881
x11_capture_helper_sha256=a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206a3efb4b017
fullscreen_presentation=1
ahb_producer=960x540
android_destination=1280x960
input=android-keyevent KEYCODE_BUTTON_A(96) -> BTN_SOUTH(304)
```

The run used the doc 96 software profile, valid-content AHB cadence, frame
identity and marker tracing, the overlay guard, and the new
`NOVA_CONTROLLER_UI_X11_CAPTURE=1` diagnostic. No Gamescope, AHB, SurfaceControl,
or input behavior was changed for this run.

## Result

Fresh Steam readiness was reached, and the X11 helper found the mapped Steam
window in the same run:

```text
controller_ui_ready=1 app_pid=21111
controller_ui_x11_capture_status=0
nova_x11_capture_status=pass phase=baseline window_id=0x240003b
controller_ui_surface=missing
android_key_forwarded=none
native_steam_controller_ui_input_smoke=fail underlying_status=1
```

The X11 PPM is 960x540 and its luma/chroma signal statistics are constant
black (`YMIN=YLOW=YAVG=YHIGH=16`, `U=V=128`). Its SHA-256 is
`cc43b9f07a7411347c54707315b778375fcb8c7840e8ba7338f45571a046637a`.
The derived PNG has SHA-256
`c747e3bfeaf151d3c889ca35fd101b296e190f0c54c5992fe713f2d69ef77520`.

The native Android capture is 1280x960 with the AHB marker and a transient
Superuser toast over a dark gray surface, but no Steam panel. Its SHA-256 is
`c8c8e8395ecd557e97a6e9bd0942692bb082248ac2d8fd9121e50e00925c700c` and the
native marker decoder returned:

```text
nova_frame_marker_decode=fail reason=magic_0000
```

The X11 sample was taken immediately after the fresh UI-readiness gate; the
Android screenshot was taken after the declared 30-second settle delay. Thus
this is the “X11 dark / AHB dark” branch for the captured baseline, but the
timing difference is retained as a caveat rather than treated as proof that
the X11 window stayed black for the entire settle interval.

## AHB and SurfaceFlinger evidence

The lower-level transport remained healthy through all 240 producer frames:

```text
ahb_double_buffer_frames=240
ahb_double_buffer_presents=240
ahb_double_buffer_releases=239
ahb_double_buffer_frame_marker_239=pass producer_frame=239 checksum_low16=b383
probe_status=0
```

The app report SHA-256 is
`eac543ed064dd41b7c230942bd380cfa9786c66909a0dbc3b0ff84bbc260b03d`.
SurfaceFlinger retained the active `Nova double-buffer Linux image loop#27859`
layer and mapped the 960x540 source across the full 1280x960 destination with
`composition=DEVICE`:

```text
geomBufferSize=[0 0 960 540]
geomContentCrop=[0 0 960 540]
displayFrame=[0 0 1280 960]
sourceCrop=[0.000000 0.000000 960.000000 540.000000]
bufferTransform=0
```

The HWC table independently maps both 960x540 source halves to the complete
1280x960 display. This repeats doc 96's downstream finding: the Android layer
is latched and displayed, so changing SurfaceControl destination geometry is
not the next hypothesis.

## Steam and renderer evidence

The fresh Steam logs reached the same readiness markers used by the harness:

```text
Started webhelper process       2026-08-09 10:24:04
SteamUI connection ready        2026-08-09 10:24:09
OOBE Store: keyboards           2026-08-09 10:24:10
IPv4 connectivity test          2026-08-09 10:24:05 ... OK
IPv6 HTTP/UDP tests             2026-08-09 10:24:07-09 ... TIMEOUT
```

The client completed its bounded expected timeout and installation markers:

```text
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
```

The client selected the intentional software stack. CEF's GPU report names
`ANGLE (Mesa, softpipe, OpenGL 3.3)` with `gpu_compositing=enabled`, while the
client also reports missing Vulkan surface extensions and
`BInit - Unable to initialize Vulkan!`. Gamescope reports Xwayland glamor
falling back to software. These are not hardware-GL acceptance results.

## Decision and next step

Keep the valid-content cadence and AHB ownership changes. Do not alter
SurfaceControl sizing, input dispatch, or the Gamescope output import based on
this run. The same-run X11 capture makes the upstream rendered-content path the
next boundary, but the 960x540 timing/resolution caveat must be removed first.

The older visible X11 controls in docs 54 and 60 used the same software-GL
family but a 1280x960 Steam/Xwayland window. The next predeclared run should
change only the producer/output size from 960x540 to 1280x960 while retaining
the current Gamescope source, APK, valid-content cadence, readiness gate,
X11 capture, and cleanup contract. Interpret it as follows:

1. 1280x960 X11 and Android become visible: the current failure is a
   low-resolution Steam/CEF/Xwayland path incompatibility; keep the native
   destination profile and repair that resolution boundary.
2. 1280x960 X11 is visible but Android remains dark: return to Gamescope AHB
   output import with a synchronized X11/Android capture.
3. 1280x960 X11 remains black: isolate software CEF/GLX/Xwayland with a
   known-good synthetic X11 client and a renderer/GLX diagnostic before making
   any compositor change.

Networking remains only partially observed, and audio, hardware CEF/GL,
touchscreen, login, and the standalone end-user launcher remain unaccepted.

The complete run is retained under:

```text
android/nova-lab/build/manual-runs/controller-ui-20260809T-x11-ahb-presentation-split/
```

Key artifact hashes:

```text
device-gamescope-headless-ahb-preflight.txt=49f4595a8cc09a71988bed4e618c5ed69526db98ff75d18a1f17f30f3e99e436
device-gamescope-headless-ahb-metadata.txt=6a871a94541a1a8ca29bbc15824d6444b5d8fd08ee3755cbe148ca727906044a
device-gamescope-headless-ahb-report.txt=95cd264ef9ae6b31e74a6ef1cd8d35632e9b00b739109fdfd984035308d3edd6
device-gamescope-headless-ahb-screenshot.png=c8c8e8395ecd557e97a6e9bd0942692bb082248ac2d8fd9121e50e00925c700c
x11-steam-baseline.ppm=cc43b9f07a7411347c54707315b778375fcb8c7840e8ba7338f45571a046637a
x11-capture-baseline-status.txt=9041e5264ef67d3d6f585f8cfad621fd26a305fe7ceccf4fab62cdeddfb6d159
post-stop-verification-explicit.txt=4ce8eb8a96033d627f4ca2d3e716c309fa9f74c4e5788de264f711fbe37f9b87
```

The explicit verifier passed residual-process, app-file, trace-reset,
scheduler-reset, frame-identity-reset, frame-marker-reset, and ACK-timeout
reset checks.
