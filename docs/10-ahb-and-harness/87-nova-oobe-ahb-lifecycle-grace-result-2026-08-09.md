# Nova OOBE AHB lifecycle-grace result — 2026-08-09

Status: partial acceptance; the lifecycle-grace hypothesis is disproved. The
Android A-button transition and downstream frame marker still pass, but the
AHB session closes at frame 88 because Gamescope stops reaching the Android
presentation path for longer than the producer's bounded ACK wait.

## Run identity and provenance

- Predeclared experiment: [doc 86](86-nova-oobe-ahb-lifecycle-grace-experiment-2026-08-09.md).
- Device: Retroid Pocket Nova, Android 13, ADB serial `675a2365`.
- Run ID/profile: `controller-ui-20260809T-oobe-a-button-lifecycle-grace` /
  `controller-ui-oobe-a-button-lifecycle-grace`.
- Run start: `2026-08-09T08:42:22Z`.
- Presentation: native Steam/Xwayland, fullscreen 1280x960, software CEF/GL.
- Input: Android `KEYCODE_BUTTON_A` 96 -> Linux `BTN_SOUTH` 304.
- AHB: frame identity and marker enabled; target 240 frames.
- Overlay guard: enabled.

The retained run artifacts are under:

`android/nova-lab/build/manual-runs/controller-ui-20260809T-oobe-a-button-lifecycle-grace/`

```text
gamescope_binary=/tmp/nova-gamescope-frame-identity-final.AOqe48/out-libei/src/gamescope
gamescope_binary_sha256=5d1425b50cbef93ee6084c95a6bd2360f3c97b5686f8d2b2cf17fefcac3b7d1b
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
gamescope_source_status_sha256=d8554a591ad45ff80921c48b581bb32857b4e365c978e1b963002ab242c306d3
gamescope_source_diff_sha256=db9e17962a7036dac51c47a1a14551f0e0e5b4e3cf01c210134d7ad54dceec3a
gamescope_source_submodules_sha256=ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
nova_apk_sha256=5ecb264b64c7cca4befe0f6396164de27e9ca858ad0dff41e9935b0046687f2c
fullscreen_presentation=1
force_gpu_composition=unset
nova_ahb_trace=1
nova_ahb_socket_trace=1
nova_ahb_scheduler_trace=0
nova_ahb_frame_identity=1
nova_ahb_frame_marker=1
nova_ahb_ack_poll_timeout_ms=0
```

## Accepted evidence before the failure

The strict controller gate passed:

```text
controller_ui_surface=pass
controller_ui_steam_surface=pass
controller_ui_android_event=KEYCODE_BUTTON_A code=96 maps_to=BTN_SOUTH code=304
controller_ui_screen_changed=pass
controller_ui_navigation=pass
```

The visible Steam OOBE changed from the language selector to the timezone
selector. No USB chooser was present in the final capture. The frame marker
decoder independently correlated the final valid capture to producer frame
87:

```text
nova_frame_marker_decode=pass
nova_frame_marker_png_size=1280x960
nova_frame_marker_frame=87
nova_frame_marker_checksum_low16=c82d
```

Frames through 87 passed AHB identity, acquire-fence, presentation, marker,
and release checks. The app report recorded 87 releases before the next frame.

## Failure boundary

Gamescope's trace shows the producer-side gap directly:

```text
frame=87 ... phase=ack_sent monotonic_ns=98262065966784
frame=88 ... phase=wait_release monotonic_ns=98306313878590
```

That is approximately 44.25 seconds without entering the frame-88 Android
presentation path. Once Gamescope finally enters it, it receives the release
for buffer 1, composes the frame, and gets `EPIPE` sending the ACK because the
Android producer has already closed its peer:

```text
ahb_double_buffer_frame=88 buffer=1 ack_bytes=-1
ahb_double_buffer_frames=88 releases=87
ahb_double_buffer=fail
```

There is no `ahb_double_buffer_cancelled` record in the app report. The
independent post-stop verifier passed and reset all tracing, identity, marker,
and ACK-timeout properties:

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

## Interpretation

The 5-second `Activity.onStop()` grace did not address this run. The failure
occurs before Gamescope's next `Present()` call and is not explained by the
Android Activity teardown path or by the transient settings overlay. The
current evidence instead identifies a scheduler/present-cadence starvation
on a quiet or transitioning Steam scene, followed by the expected bounded
producer timeout and a later Gamescope `EPIPE`.

This is a valid negative result for the lifecycle hypothesis, not evidence
that the AHB transport or the A-button path is broken. The origin/main global
repaint trigger remains rejected as a product fix because [doc 82](82-nova-origin-main-repaint-trigger-result-2026-08-09.md)
showed a dark final Android surface even though it completed its frame count.

## Next experiment

Keep this exact no-trigger Gamescope binary, APK, input mapping, overlay guard,
presentation flags, and 240-frame gate. Enable only the already integrated
Gamescope scheduler trace, then repeat the A-button transition. Use the trace
to distinguish a missing vblank/paint decision from a block inside
`Present()`. Do not extend the ACK timeout or add another repaint trigger in
that diagnostic run; either would change the causal boundary being measured.

After the scheduler boundary is captured, implement the narrowest
Android-output-specific cadence fix that preserves the visible Steam surface,
then repeat the same marker-correlated gate before moving on to networking,
audio, hardware CEF/GL, or standalone-app work.

## Artifact hashes

```text
device-gamescope-headless-ahb-preflight.txt=e8345be163d417bcb374bf51237c01e62a462f960e47c2e8261b787e121632e3
device-gamescope-headless-ahb-metadata.txt=ccf84920679d00d1e49d8bb81c0086a7b8e5211fcc30eb61bcca79d47ea999fe
device-gamescope-headless-ahb-report.txt=c746b4da93ded8dd4d0f3462c6e2cf83b7bcdbe778e1c60785ed6aea85bc67b8
device-gamescope-headless-ahb-app-report.txt=8c622f86e2cfb2a0ff2d3eb52d1bbd09f67300ead0ce91c8107dba906b226014
device-gamescope-headless-ahb-screenshot.png=ea084c23408a278a6144eec20ad7bdcaf44fac8e7dd1fcdcb58553562cd042e2
ahb-frame-marker-screenshot.txt=692b2eb30852b04c65eb86cd8aea0a0ff7bfdadc60ebd778ed4228df7d1ee4e4
android-input-bridge-report.txt=781e2fed7f3fa4668b3723c87f329f024474985ebf14fb9c7659134a8586131a
post-stop-verification-explicit.txt=e0fa7fe260c4736e836c597e53dc35727c0f9657548f7d9dd33bc37c5b07ee36
```
