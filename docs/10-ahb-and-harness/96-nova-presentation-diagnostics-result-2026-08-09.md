# Nova presentation diagnostics result — 2026-08-09

Status: diagnostic capture passed; end-to-end visible Steam presentation
remains rejected.

## Run identity and provenance

```text
run_id=controller-ui-20260809T-oobe-a-button-valid-content-cadence-presentation-diagnostics
profile=controller-ui-oobe-a-button-valid-content-cadence-presentation-diagnostics
run_started_utc=2026-08-09T10:09:30Z
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
binary=/tmp/nova-gamescope-frame-identity-final.AOqe48/out-libei/src/gamescope
binary_sha256=f7035c838a2e9e91a36c388d00832709d941afdf12e1fb08dd377085dfe3b22c
apk_sha256=fab2bd8b72133017ca3413028dede3a9179ff8adda5d7759e0b072d1de800e94
fullscreen_presentation=1
ahb_producer=960x540
android_destination=1280x960
presentation_diagnostics=1
```

The Gamescope source identity remains the doc 94 candidate: source commit
`fb9f84ee247a1f02b1a132da60e94585db84bf61`, with the same recorded dirty,
diff, and submodule hashes in the run metadata.

## Result

The fresh Steam readiness and strict presentation gates separated cleanly:

```text
controller_ui_ready=1 app_pid=15226
controller_ui_surface=missing
android_key_forwarded=none
steam_input_fd=pass
native_steam_controller_ui_input_smoke=fail underlying_status=1
```

The harness correctly sent no A-button because the visible Steam-panel gate
never passed. The lower-level AHB path still completed the full target:

```text
ahb_double_buffer_frames=240 releases=239
ahb_double_buffer_frame_marker_239=pass producer_frame=239 checksum_low16=b383 marker_status=0 checksum_status=0
ahb_double_buffer=pass
probe_status=0
post_stop_verification=pass
```

The native Android capture is
`device-gamescope-headless-ahb-screenshot.png` with SHA-256
`c8c8e8395ecd557e97a6e9bd0942692bb082248ac2d8fd9121e50e00925c700c`. It is
1280x960 and visibly contains the marker and a transient Android toast over a
dark surface, but no Steam OOBE panel. The native marker decoder returned
`magic_0000`.

## Fresh client and Steam evidence

The new early capture retained all three current client files:

```text
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
```

The client selected GLX (`Using update UI: glx`). It also reported missing
`VK_KHR_surface` and `VK_KHR_xlib_surface` and `BInit - Unable to initialize
Vulkan!`; this is consistent with the intentionally software-GL diagnostic
profile and is not a hardware-acceleration pass. The stderr contains the
expected no-session-bus/DBus errors and repeated SysV semaphore shim retries.

All seven requested Steam log files were pulled from the same run. Current
run markers are present at the following times:

```text
Started webhelper process       2026-08-09 10:10:02
SteamUI connection ready        2026-08-09 10:10:07
OOBE Store: keyboards           2026-08-09 10:10:09
IPv4 connectivity test          2026-08-09 10:10:03 ... OK
```

The Steam log bundle also contains older cumulative history; the timestamps
above are the fresh-run evidence used by the readiness gate. IPv6 probes timed
out, while the IPv4 connectivity probe passed. This does not advance the
networking acceptance because the user-visible Steam surface is still absent.

## SurfaceFlinger boundary

The same-run `dumpsys SurfaceFlinger --list` and `--layers` captures both
passed. They show the active `Nova double-buffer Linux image loop#27705`
layer with:

```text
geomBufferSize=[0 0 960 540]
geomContentCrop=[0 0 960 540]
geomLayerTransform=SCALE 1.3333 horizontal, 1.7778 vertical
displayFrame=[0 0 1280 960]
sourceCrop=[0.000000 0.000000 960.000000 540.000000]
bufferTransform=0
composition=DEVICE
```

The HWC pipe table independently reports the 960x540 source mapped across the
full 1280x960 destination. This proves that SurfaceControl retained and
displayed the AHB layer; it is not an unexplained dropped-latch or stale-layer
case. The native marker decoder's `magic_0000` is therefore explained by its
producer-coordinate assumption: the marker is scaled to a different position
and cell size in the 1280x960 capture. Rescaling the capture to 960x540 recovers
the producer marker, but that is diagnostic only and does not make the dark
Steam surface acceptable.

## Decision and next steps

Keep the valid-content cadence and AHB ownership changes. Do not change
SurfaceControl destination sizing or send controller input based on this
result. The downstream presentation geometry is now explicit; the remaining
visible-content question is upstream of SurfaceFlinger, in the Xwayland
window/Gamescope composition path or the software CEF/GL renderer.

The next run should use the existing X11 window-capture helper from
[`docs/38`](38-nova-x11-presentation-capture.md) during the same fresh Steam
session and retain its output beside the AHB screenshot, client logs, and
SurfaceFlinger dump. Compare the visible Steam X11 window with the same-run AHB
buffer before considering any Gamescope repaint change:

1. X11 dark and AHB dark: isolate CEF/GLX/Xwayland rendering and damage.
2. X11 visible and AHB dark: isolate Gamescope composition/output import.
3. X11 and AHB both visible: repair only the transform-aware marker/capture
   gate, then repeat the controlled A-button navigation test.

Networking, audio, hardware GL, touchscreen, login, and standalone-app
acceptance remain downstream and intentionally unclaimed.

The complete retained run is under:

```text
android/nova-lab/build/manual-runs/controller-ui-20260809T-oobe-a-button-valid-content-cadence-presentation-diagnostics/
```

