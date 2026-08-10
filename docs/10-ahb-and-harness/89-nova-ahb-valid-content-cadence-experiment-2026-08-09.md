# Nova AHB valid-content cadence experiment — 2026-08-09

Status: predeclared; device result pending.

## Causal basis

The scheduler result in [doc 88](88-nova-gamescope-present-cadence-result-2026-08-09.md)
shows that vblank continues while `hasRepaint=0` and `should_paint=0` on a
static Steam scene. The earlier global vblank trigger completed its frame
count but produced a dark Android capture, so it is not an acceptable fix.

## One-variable implementation

Add an opt-in Gamescope repaint cadence for `NOVA_AHB_OUTPUT_SOCKET`, but arm
it only after `paint_all()` has produced valid visible contents. Clear that
armed state when the current paint has no valid contents or the backend is
paused. Keep the existing `SOCK_STREAM` transport, three-buffer ring,
SurfaceControl pacing, fence handoff, software CEF/GL flags, frame identity,
marker, and input mapping unchanged.

This is intended to avoid forcing the Android output through the blank/early
composition state that made the global trigger dark while still causing
`Present()` to repeat an already-valid Steam frame on a quiet scene.

## Build gate

Apply the new patch after the existing AHB frame-identity and scheduler-trace
patches to a fresh Gamescope source tree. The patch stack must pass reverse
and forward checks, then compile and link the ARM64 libei-enabled Gamescope
binary. Rebuild the Android APK through the existing harness and record both
artifact hashes.

## Device acceptance gate

Repeat the exact guarded OOBE A-button run at fullscreen 1280x960 with a
240-frame target and `NOVA_AHB_ACK_POLL_TIMEOUT_MS=0`. Accept only if:

```text
controller_ui_navigation=pass
ahb_frame_marker_capture=pass
android_ahb_target_reached=240
ahb_double_buffer_frames=240 releases=239
post_stop_verification=pass
```

The final screenshot must remain a visible Steam surface and correlate to the
producer report. A frame-count pass with a dark or uncorrelated Android
capture rejects the patch. If this gate passes, repeat it once with the
scheduler trace disabled to confirm the diagnostic instrumentation is not
masking the cadence behavior before moving to login/network/audio work.
