# Nova controller UI readiness-timeout result — 2026-08-09

Status: readiness timing was fixed; the visible-presentation and
frame-correlation gate still failed.

## Run identity and provenance

This is the predeclared doc 93 run:

```text
run_id=controller-ui-20260809T-oobe-a-button-valid-content-cadence-controller-wait
profile=controller-ui-oobe-a-button-valid-content-cadence-controller-wait
run_started_utc=2026-08-09T09:52:30Z
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
binary=/tmp/nova-gamescope-frame-identity-final.AOqe48/out-libei/src/gamescope
binary_sha256=f7035c838a2e9e91a36c388d00832709d941afdf12e1fb08dd377085dfe3b22c
apk_sha256=252881d16ef7ff660e9cb41f529cfec5b085cf5e3fa2fa5454ec035d358597f7
fullscreen_presentation=1
nova_ahb_trace=1
nova_ahb_socket_trace=1
nova_ahb_scheduler_trace=1
nova_ahb_frame_identity=1
nova_ahb_frame_marker=1
nova_ahb_ack_poll_timeout_ms=0
controller_ui_wait_timeout=240
steam_client_timeout=180
steam_gamescope_timeout=300
```

The full source-tree and patch-stack identity is retained in the run
metadata and preflight manifest.

## Result

The extended controller readiness window did its intended job:

```text
controller_ui_source_ready=1
controller_ui_relay_ready=1
controller_ui_ready=1 app_pid=10276
```

This removes the doc 92 ambiguity. SteamUI readiness was observed during the
fresh run, but the settled capture still failed:

```text
controller_ui_surface=missing
controller_ui_run_status=1
native_steam_controller_ui_input_smoke=fail underlying_status=1
```

The harness correctly sent no A-button because its strict visible Steam-panel
gate did not pass. The relay therefore recorded
`android_key_forwarded=none`; the app report only contains fresh controller
enumeration and input-socket connection, not a dispatched key. The separate
Steam input-FD probe still passed, proving that Steam held the virtual
controller device, but no UI-consumption claim is made.

The lower-level producer/output path remained healthy:

```text
ahb_double_buffer_frames=240 releases=239
ahb_double_buffer=pass
headless_ahb_residual_processes=pass
nova_app_runtime_files_cleanup=pass
post_stop_verification=pass
```

All 240 producer marker records passed. The final producer frame was 239 with
FNV-1a checksum `3a9b4d43620b4b2f` and marker low 16 bits `4b2f`.

## Presentation/correlation boundary

The native 1280x960 Android capture is
`device-gamescope-headless-ahb-screenshot.png` with SHA-256
`3cfdaf06d1056212b0c87eef1d3290106d63de8015d29364b6ca7c450276b9b4`.
The marker decoder returned:

```text
nova_frame_marker_decode=fail reason=magic_0000
```

As a diagnostic only, scaling that capture back to the 960x540 producer size
made the marker decoder recover frame 239 and checksum `4b2f`. That does not
convert the acceptance result to pass: the end-user 1280x960 capture did not
correlate at its native display coordinates, and its strict Steam-panel
luminance gate still failed. The image is a dark/transitioning surface, not a
visible Steam OOBE page.

This differs from docs 90–92, where the native 1280x960 capture decoded the
marker at frame 239 with checksum `0383`. The current evidence therefore
points at a downstream SurfaceControl/display transform or presentation-state
boundary, not at the AHB socket, fence, or valid-content cadence itself.

## Evidence limitation

The nested smoke wrapper aborted at the frame-marker decode failure before it
pulled `/tmp/nova-steam-client.log`, stdout, and stderr into the run. The
client files left in the host build directory belonged to an earlier run and
were excluded from this run's artifacts. The rootfs was absent after the
required teardown, so no fresh Steam client log is claimed here.

## Decision and next steps

Keep the valid-content cadence implementation and the 240-frame AHB result as
lower-layer passes. Do not change the AHB transport or inject UI input yet.

Before another long device run:

1. Make the AHB deploy path capture fresh client stdout/stderr/log metadata
   before its cleanup trap, even when marker decoding or a later acceptance
   check fails.
2. Capture same-run SurfaceControl/layer geometry and the producer/display
   transform so the 960x540-to-1280x960 behavior is explicit rather than
   inferred from a rescale.
3. Repeat with the same binary and flags. Only a native-resolution,
   frame-correlated Steam surface should unlock the A-button/navigation gate.

If that repeat still shows a dark surface, then use the fresh client and
SteamUI logs to isolate software GL/CEF, Xwayland, DBus, or Steam window
composition. Networking, audio, touchscreen, hardware GL, and standalone-app
acceptance remain downstream of this boundary.

The retained artifacts are under:

```text
android/nova-lab/build/manual-runs/controller-ui-20260809T-oobe-a-button-valid-content-cadence-controller-wait/
```

