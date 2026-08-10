# Nova Gamescope present-cadence result — 2026-08-09

Status: partial acceptance; the scheduler trace confirms repaint starvation as
the cause of the AHB boundary failure. The A-button transition and visual
frame correlation pass, but the bounded producer still closes before the
240-frame target.

## Run identity and provenance

- Predeclared experiment: the present-cadence diagnostic in
  `docs/10-ahb-and-harness/71-nova-gamescope-present-cadence-experiment-2026-08-09.md`.
- Device: Retroid Pocket Nova, Android 13, ADB serial `675a2365`.
- Run ID/profile: `controller-ui-20260809T-oobe-a-button-scheduler-trace` /
  `controller-ui-oobe-a-button-scheduler-trace`.
- Run start: `2026-08-09T08:59:44Z`.
- Presentation: native Steam/Xwayland, fullscreen 1280x960, software CEF/GL.
- Input: Android `KEYCODE_BUTTON_A` 96 -> Linux `BTN_SOUTH` 304.
- AHB: scheduler trace, frame identity, and marker enabled; target 240 frames.
- Overlay guard: enabled.

The retained run artifacts are under:

`android/nova-lab/build/manual-runs/controller-ui-20260809T-oobe-a-button-scheduler-trace/`

```text
gamescope_binary=/tmp/nova-gamescope-frame-identity-final.AOqe48/out-libei/src/gamescope
gamescope_binary_sha256=5d1425b50cbef93ee6084c95a6bd2360f3c97b5686f8d2b2cf17fefcac3b7d1b
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
gamescope_source_status_sha256=d8554a591ad45ff80921c48b581bb32857b4e365c978e1b963002ab242c306d3
gamescope_source_diff_sha256=db9e17962a7036dac51c47a1a14551f0e0e5b4e3cf01c210134d7ad54dceec3a
gamescope_source_submodules_sha256=ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
nova_apk_sha256=c70ea96b0e1670673c904d26df1fb062639244b5e06e69975a829540f4623a9a
fullscreen_presentation=1
force_gpu_composition=unset
nova_ahb_trace=1
nova_ahb_socket_trace=1
nova_ahb_scheduler_trace=1
nova_ahb_frame_identity=1
nova_ahb_frame_marker=1
nova_ahb_ack_poll_timeout_ms=0
```

## Accepted evidence

The strict controller gate passed:

```text
controller_ui_surface=pass
controller_ui_steam_surface=pass
controller_ui_android_event=KEYCODE_BUTTON_A code=96 maps_to=BTN_SOUTH code=304
controller_ui_screen_changed=pass
controller_ui_navigation=pass
```

The marker decoder correlated the final valid Android capture to producer
frame 105:

```text
nova_frame_marker_decode=pass
nova_frame_marker_png_size=1280x960
nova_frame_marker_frame=105
nova_frame_marker_checksum_low16=4eed
```

Frames through 105 passed frame identity, acquire-fence, presentation,
marker, and release checks. The app report recorded 105 releases before the
next frame failed.

## Scheduler decision at the failure boundary

The last healthy frame 105 was acknowledged at:

```text
frame=105 phase=ack_sent monotonic_ns=99339246548353
```

Immediately afterward, the scheduler continued to receive vblank events but
reported the unchanged scene as not needing a repaint:

```text
phase=paint_decision focus_commit=70 vblank=1 has_repaint=0 has_repaint_non_base=0 should_paint=0
```

Those idle decisions continued at roughly one-second intervals from
`99340261226477` through `99385611225054`. There was no `present_call` during
that interval. The gap from frame 105's ACK to the next Android-output
`Present()` path was approximately 47.16 seconds.

Only after a new focus commit did Gamescope resume presenting:

```text
phase=paint_decision focus_commit=71 vblank=1 has_repaint=1 should_paint=1 monotonic_ns=99386411265991
phase=present_call monotonic_ns=99386411325314
frame=106 phase=wait_release monotonic_ns=99386411362866
```

By then the app's bounded 15-second ACK wait had closed the peer. Gamescope
received the release but its frame-106 ACK returned `EPIPE`:

```text
ahb_double_buffer_frame=106 buffer=1 ack_bytes=-1
ahb_double_buffer_frames=106 releases=105
ahb_double_buffer=fail
```

This satisfies the diagnostic branch “no repaint/present during the gap.” It
does not implicate the release-fence handoff, socket framing, or Activity
teardown.

## Interpretation and next implementation

The no-trigger artifact is correct for preserving the visible Steam surface,
but its normal repaint policy is incompatible with an Android AHB consumer
that synchronously waits for a new frame on a static scene. The earlier
global vblank trigger remains rejected because [doc 82](82-nova-origin-main-repaint-trigger-result-2026-08-09.md)
completed its frame count while leaving the Android capture dark.

The next code experiment should add an Android-output-specific cadence path
that starts only after Gamescope has a valid visible frame, preserving the
current transport, three-buffer ownership, release fences, and frame marker.
The first acceptance gate remains this exact A-button transition with a
240-frame marker-correlated capture; an ACK-timeout extension is useful only
as a diagnostic and is not a product fix.

The independent post-stop verifier passed:

```text
post_stop_residual_processes=pass
post_stop_app_files=pass
post_stop_trace_state=pass
post_stop_scheduler_trace_state=pass
post_stop_frame_identity_state=pass
post_stop_frame_marker_state=pass
post_stop_ack_poll_timeout_state=pass
post_stop_verification=pass
```

## Artifact hashes

```text
device-gamescope-headless-ahb-preflight.txt=054d4c33b103a2a1855ddbc25815eeb299c3d581618ff00eb456eedcd450f167
device-gamescope-headless-ahb-metadata.txt=07d90b28256c67d2b9dc9bc2bccdf4b31d3ff861695db090edd01cdbcf3803d6
device-gamescope-headless-ahb-report.txt=90415299bf58ae9a99942af7beb0446514e2f8c38e157db13356ee0f1d2402a6
device-gamescope-headless-ahb-app-report.txt=936add64cc5dd4318e1c02e30ab3f7b7a5c175e9bc0ae2fc954325560b9d4a06
device-gamescope-headless-ahb-logcat.txt=55e44e306fe73fb059525fd0e462bcefcbf90b95a004331eb0e419bab0cb48b6
device-gamescope-headless-ahb-screenshot.png=1de52dca2fd428ab31ebf31f46d87697684dcbefada494ad81da8bdb7c6f18a2
ahb-frame-marker-screenshot.txt=c900060a01841fafd240ea015e56e4d9c0255002dd1c1d0f9652e3c9697dcd1e
android-input-bridge-report.txt=756f6cde418e6f0a71335e1b70dd7501ed170f2cd5ef56ae87a02672d2640c21
post-stop-verification-explicit.txt=e1381f7eb2b718ce3b000e923248ec136e5ba5edd899a790f363bfef149d0216
```
