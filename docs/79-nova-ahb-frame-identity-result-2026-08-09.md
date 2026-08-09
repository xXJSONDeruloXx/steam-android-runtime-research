# Nova AHB frame identity device result (2026-08-09)

Status: accepted as a diagnostic ARM64 Gamescope-to-Android frame-identity
result. The native Steam/Xwayland presentation and controller gates pass, but
the Steam login gate remains rejected because the final visible state is still
the Steam language/OOBE screen and the downstream visual frame is not yet
cryptographically correlated with the producer buffer.

## Run identity

- Repository branch/commit at launch: `feat/nova-steam-end-to-end` at
  `88408a1` (`test: record scheduler trace device result`), with the
  frame-identity implementation in the worktree.
- Device: Retroid Pocket Nova, Android 13, ADB serial `675a2365`.
- Run ID/profile: `controller-ui-20260809T160000Z-frame-identity` /
  `controller-ui-frame-identity`.
- Run start: `2026-08-09T07:40:59Z`.
- Presentation: fullscreen, 1280x960, native Steam/Xwayland controller UI
  wrapper, Android key-event D-pad bridge, software CEF/GL profile.
- AHB target: 240 frames; AHB, socket, and scheduler traces enabled; ACK
  poll-timeout override disabled (`0`); frame identity enabled (`1`).

The exact run artifacts are retained under
`android/nova-lab/build/manual-runs/controller-ui-20260809T160000Z-frame-identity/`.

## Build provenance

The Gamescope binary was rebuilt from a fresh ARM64 source copy with the
tracked patch sequence, including the frame-identity patch, and libei input
support. The build completed all `459/459` targets.

```text
gamescope_binary=/tmp/nova-gamescope-frame-identity-final.AOqe48/out-libei/src/gamescope
gamescope_binary_sha256=5d1425b50cbef93ee6084c95a6bd2360f3c97b5686f8d2b2cf17fefcac3b7d1b
gamescope_libei_build=enabled
gamescope_source_tree=/tmp/nova-gamescope-frame-identity-final.AOqe48/source
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
gamescope_source_dirty=1
gamescope_source_status_sha256=d8554a591ad45ff80921c48b581bb32857b4e365c978e1b963002ab242c306d3
gamescope_source_diff_sha256=db9e17962a7036dac51c47a1a14551f0e0e5b4e3cf01c210134d7ad54dceec3a
gamescope_source_submodules_sha256=ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
gamescope_frame_identity_patch_sha256=493ab664eeb6ef53cd40302249086494f9a0694e9eea448e1cdc797883bd84ba
nova_apk=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/nova-lab-debug.apk
nova_apk_sha256=26fa7adc81fa681580ec9d829750ab1bfe1eaa20e02f99a4eb48eae2d043a4de
```

`gamescope_source_dirty=1` is expected: the source copy records the tracked
Gamescope patch sequence used to construct this diagnostic binary. The binary,
source, patch, and APK hashes distinguish this run from earlier scheduler and
AHB builds.

## Device result

The wrapper completed with status 0 and passed the established native profile:

```text
controller_ui_surface=pass
controller_ui_steam_surface=pass
controller_ui_navigation=pass
controller_ui_screen_changed=pass
controller_ui_android_input_bridge=pass
native_steam_smoke=pass
headless_gamescope_ahb=pass
native_steam_controller_ui_input_smoke=pass
controller_ui_run_status=0
```

The Android bridge forwarded D-pad key code 20 as Linux code 545
(`BTN_DPAD_DOWN`), and the Steam input FD probe passed against the rooted
`Nova Virtual Xbox Controller` event device.

The app report recorded all 240 frame-identity records as passes, with no
failures:

```text
ahb_double_buffer_version=2
ahb_double_buffer_frame_identity=enabled
ahb_double_buffer_frame_identity_0=pass producer_frame=0 ... checksum_status=0
ahb_double_buffer_frame_identity_239=pass producer_frame=239 ... checksum_status=0
ahb_double_buffer_frames=240 releases=239
dma_buf_double_buffer_summary ... ahb_double_buffer=pass
```

The explicit post-stop verifier also passed and reset the diagnostic state:

```text
post_stop_residual_processes=pass
post_stop_app_files=pass
post_stop_trace_state=pass
post_stop_scheduler_trace_state=pass
post_stop_frame_identity_state=pass
post_stop_ack_poll_timeout_state=pass
post_stop_verification=pass
```

Run artifact hashes:

```text
preflight=6b3043b1ef224725045ea59ebae4b7c9773fa3d3a84417affa3f5c44fcc68a34
logcat=f7673f00018be5eb5ec3e5ba0a48c3b8bc51971453c9068212b4fe62afef69ff
metadata=090416b9590ddc2bc0bfdfc118f59b846de7f7a873163407dc1f562ce3195c1e
gamescope_report=918376c828f4cd4da222f8107c4496c6877e563710e9891f657b8b6c1b8b733a
app_report=ac20cc34ac4bf39acfb966723ee227819d74cb4802a11c6e938209d018e2c4d4
screenshot=44df231df55ba131d633673c1cc362638dcab5f8b2a0c9664251f18e0cb08897
android_input_report=4df5814d1961010f71ba99474d93f404c0aa76b2db6c32d3f23de5930618e489
post_stop_verification=bba1861e8ad510a13cc1b7c00b6d82cd2a857b0a97abdedcdc480177dacb7d52
```

## What the identity path proves

Gamescope now attaches its output frame counter and focus/override commit IDs
to each Android ACK. When the opt-in Android property
`debug.nova.ahb_frame_identity=1` is set, the app:

1. requires the ACK's producer frame to equal the app's expected frame;
2. waits for the acquire fence;
3. CPU-reads the active RGBA rows from the received AHardwareBuffer; and
4. records an FNV-1a 64 checksum before submitting that buffer to
   SurfaceControl.

The 240/240 result proves the producer identity, ACK metadata, acquire-fence
ordering, Android buffer readback, and per-frame checksum path are coherent in
one run. The identity mode is diagnostic-only: CPU readback adds substantial
latency and is disabled by default for normal presentation.

## What remains unproven

The final screenshot visibly remains on Steam's language-selection/OOBE screen,
not the login form. The run therefore does not accept Steam login. The checksum
is taken before SurfaceControl composition, while the retained screenshot is a
downstream PNG capture; the two are not yet byte-for-byte correlated. A
screenshot/crop hash alone cannot establish which producer frame the user saw.

The next implementation should add a same-run downstream capture correlation
gate: preserve a frame/commit identity through SurfaceControl capture (or use a
controlled visible marker/test pattern), canonicalize the capture to the AHB
active-pixel format, and compare it with the recorded frame checksum. Only then
should the login/OOBE transition be re-run as an acceptance test.
