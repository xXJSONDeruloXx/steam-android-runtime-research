# Nova 1280x960 Steam/X11 resolution result — 2026-08-09

Status: resolution comparison passed its lower-level gates; visible Steam
presentation remains rejected.

## Run identity and provenance

```text
run_id=controller-ui-20260809T-1280x960-resolution
profile=controller-ui-1280x960-resolution
run_started_utc=2026-08-09T10:34:10Z
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
gamescope=/tmp/nova-gamescope-frame-identity-final.AOqe48/out-libei/src/gamescope
gamescope_sha256=f7035c838a2e9e91a36c388d00832709d941afdf12e1fb08dd377085dfe3b22c
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
apk_sha256=5ce8498298f407e7dfe3df0c72a0e8d0732f96e153f31b9c934f9d8599deec56
x11_capture_helper_sha256=a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206a3efb4b017
fullscreen_presentation=1
producer=1280x960
android_destination=1280x960
input=android-keyevent KEYCODE_BUTTON_A(96) -> BTN_SOUTH(304)
```

The run changed only the output dimensions from doc 98. It retained the same
Gamescope source/artifact, valid-content cadence, software CEF/GL flags,
readiness gate, X11 diagnostic, AHB marker/identity tracing, and cleanup
contract.

## Result

Steam reached fresh readiness and the helper rediscovered a native-size mapped
window:

```text
controller_ui_ready=1 app_pid=27014
client_output=1280x960
nova_x11_capture_status=pass phase=baseline window_id=0x240003b
controller_ui_surface=missing
android_key_forwarded=none
controller_ui_run_status=0
native_steam_controller_ui_input_smoke=fail
```

The X11 window was viewable at 1280x960, but its same-run PPM was uniformly
black (`YMIN=YLOW=YAVG=YHIGH=16`, neutral chroma). The PPM SHA-256 is
`cc6137017d29c333dc2ca762849e23b2da7b399f63363814ebf7c035476267c4` and the
derived PNG SHA-256 is
`ab13cfb0e75353e322778d62284b4403961bbbad0d28fd9e85f925d22b3efa7f`.

The Android capture completed the native-size AHB marker gate, but remained a
dark marker-only surface without a Steam panel. The screenshot SHA-256 is
`158cf3d46dff6628bc1ee390af05ed2095071a7ef0a08946b434e684c8a270e2`.
The marker decoder correlated the final capture to the producer:

```text
nova_frame_marker_decode=pass
nova_frame_marker_frame=239
nova_frame_marker_checksum_low16=0383
```

No A-button was sent because the visible Android Steam-surface gate failed.
The relay and Steam FD checks passed, but the expected key-forwarding marker
was correctly absent, which made the controller wrapper fail rather than
claiming navigation.

## AHB and SurfaceFlinger evidence

The full-size AHB transport completed:

```text
ahb_double_buffer_frames=240
ahb_double_buffer_presents=240
ahb_double_buffer_releases=239
ahb_double_buffer_frame_identity_239=pass producer_frame=239 checksum_low16=0383
ahb_double_buffer_frame_marker_239=pass producer_frame=239 checksum_low16=0383
headless_gamescope_ahb=pass
probe_status=0
```

SurfaceFlinger retained the active `Nova double-buffer Linux image loop#28012`
at its native size, with no producer-to-display scale or crop:

```text
geomBufferSize=[0 0 1280 960]
geomContentCrop=[0 0 1280 960]
displayFrame=[0 0 1280 960]
sourceCrop=[0.000000 0.000000 1280.000000 960.000000]
bufferTransform=0
composition=DEVICE
```

This rejects the doc 98 resolution hypothesis and further reduces the
likelihood that SurfaceControl destination geometry is hiding Steam content.

## Steam and renderer evidence

Fresh current-run markers were present:

```text
Started webhelper process       2026-08-09 10:34:30
SteamUI connection ready        2026-08-09 10:34:34
OOBE Store: keyboards           2026-08-09 10:34:36
IPv4 connectivity test          2026-08-09 10:34:30 ... OK
IPv6 HTTP/UDP tests             2026-08-09 10:34:30 ... TIMEOUT
```

The native Steam wrapper and AHB probe both completed their bounded success
markers:

```text
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
native_steam_smoke=pass
```

The CEF renderer remains the intentional software `ANGLE (Mesa, softpipe)`
path; no hardware-GL acceptance claim is made.

## Decision and next boundary

The 1280x960 run reproduces the black X11 baseline, so changing from 960x540
to the previously visible native resolution did not restore Steam content.
This moves the leading hypothesis back to CEF/GLX/Xwayland rendering or the
capture timing, not resolution or SurfaceControl scaling.

The remaining timing caveat is now the highest-value check: both doc 98 and
this run captured X11 immediately after the readiness marker, while the native
Android screenshot was sampled after the 30-second settle delay. The next
diagnostic should capture the same mapped X11 window after that settle delay,
immediately before the Android surface sample, without changing the Steam or
Gamescope profile. If the settled X11 window is still black, use the existing
synthetic X11 animation client to distinguish Xwayland/X11 presentation from
CEF's software renderer before changing Gamescope.

Audio, hardware GL, touchscreen, login, and standalone-app acceptance remain
unclaimed. IPv4 connectivity is observed, but networking is not an end-user
acceptance until a visible Steam surface can be correlated.

The complete run is retained under:

```text
android/nova-lab/build/manual-runs/controller-ui-20260809T-1280x960-resolution/
```

Key artifact hashes:

```text
device-gamescope-headless-ahb-preflight.txt=210bb23053d55e96fc5949d784c8c9cdc287126d656bf5e7df083a26f8347214
device-gamescope-headless-ahb-metadata.txt=420f6306bcb845f5242c2b750db06ffddf7b9060732ee7bb9f782a819f609f90
device-gamescope-headless-ahb-report.txt=3283d4562a8892b24ba6da02d88f4dc4b0897541111533e8f3465e1f4e3d674e
device-gamescope-headless-ahb-screenshot.png=158cf3d46dff6628bc1ee390af05ed2095071a7ef0a08946b434e684c8a270e2
x11-steam-baseline.ppm=cc6137017d29c333dc2ca762849e23b2da7b399f63363814ebf7c035476267c4
x11-capture-baseline-status.txt=ed629fcd04c54a0309dda29673be1bee3282065e8e90d82b5d53d6983e77bb30
post-stop-verification-explicit.txt=3107cda9afc9ab7e9bfe20bc5797018b733893a0e64399d3edf5a982871303f1
```

The explicit post-stop verifier passed residual-process, app-file, all trace
resets, frame-identity reset, frame-marker reset, and ACK-timeout reset.
