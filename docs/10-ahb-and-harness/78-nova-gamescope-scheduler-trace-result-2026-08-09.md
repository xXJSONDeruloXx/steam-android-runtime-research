# Nova Gamescope scheduler trace device result (2026-08-09)

Status: accepted as a reproducible ARM64 Gamescope, Steam UI, controller-input,
and Android AHardwareBuffer transport result. This run does not accept the
Steam login screen and does not close the visual frame-identity gap.

## Run identity

- Repository branch/commit: `feat/nova-steam-end-to-end` at `72f5ade`
  (`diag: make Nova scheduler trace reproducible`).
- Device: Retroid Pocket Nova, Android 13, ADB serial `675a2365`.
- Run ID/profile: `controller-ui-20260809T123000Z-scheduler-frame-boundary` /
  `controller-ui-scheduler-frame-boundary`.
- Run start: `2026-08-09T07:15:43Z`.
- Presentation: fullscreen, 1280x960, native Steam/Xwayland controller UI
  wrapper, Android key-event D-pad bridge, software CEF/GL profile.
- AHB target: 240 frames; scheduler, AHB, and socket traces enabled; ACK
  poll-timeout override disabled (`0`).

The exact run artifacts are retained under
`android/nova-lab/build/manual-runs/controller-ui-20260809T123000Z-scheduler-frame-boundary/`.

## Build provenance

The Gamescope binary was rebuilt from a fresh ARM64 source copy with the
tracked build script and the now-tracked scheduler patch applied in sequence.
The clean build completed all `459/459` targets with libei input support
enabled.

```text
gamescope_binary=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/gamescope-headless-build-scheduler-trace-libei-repro/src/gamescope
gamescope_binary_sha256=ed0aba347cfb6393a5a3097cf7958c2d9c67eb635649534a52fa6753e1e331db
gamescope_source_tree=/tmp/nova-gamescope-scheduler-repro.utJ5YY/source-libei
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
gamescope_source_dirty=1
gamescope_source_status_sha256=d8554a591ad45ff80921c48b581bb32857b4e365c978e1b963002ab242c306d3
gamescope_source_diff_sha256=c8c00989cb0b913470208b17a234d290966e2f02b0018ff491c4217f847858a9
gamescope_source_submodules_sha256=ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
gamescope_scheduler_patch_sha256=9ce6d2ab522143da093f79c7b8b4abff48a159a917efa64ac35136c15235964f
nova_apk=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/nova-lab-debug.apk
nova_apk_sha256=db7912d17c345bf4d9183195fc49d564b8a75688e8dd7843810996f0e346f0b9
```

`gamescope_source_dirty=1` is expected here: the source-tree status records
the repository patch sequence used to construct this diagnostic binary. The
binary hash, source commit, status hash, diff hash, submodule hash, and patch
hash above make this exact build distinguishable from the earlier dirty,
untracked scheduler binary.

## Device result

The corrected native Steam/Xwayland profile passed all wrapper gates:

```text
controller_ui_surface=pass
controller_ui_steam_surface=pass
controller_ui_navigation=pass
controller_ui_screen_changed=pass
controller_ui_android_input_bridge=pass
native_steam_smoke=pass
headless_gamescope_ahb=pass
native_steam_controller_ui_input_smoke=pass
```

The Android bridge recorded D-pad code 20 forwarded as Linux code 545
(`BTN_DPAD_DOWN`), and the Steam input FD was found at `event9`. The app
reported `ahb_double_buffer_frames=240 releases=239` and
`ahb_double_buffer=pass`; frame 239 was presented successfully. The one fewer
release is the expected final-frame boundary of this bounded run.

The explicit post-stop verifier passed:

```text
post_stop_verification=pass
```

The run-level artifact hashes are:

```text
preflight=1dea36466f5d0985ed9f0ec6488bb515410a7aec7829fbdfdccc717fb4c85e77
logcat=6060aad72d8f0c1bf4101ab2ec0ea4909e23449632f3d23eb6e0697c283d247a
metadata=8e01a5c601c6cd2ddd535f62cb645d243b12936bd8f8bdea68c66a78dd4bc390
post_stop_verification=a42d6480e34c1e7af1526f4d7399f18719b1e5f3e4643aa6d888314afa5dc6ae
screenshot=ad3e1ddff169c151108f6bd295e952bc53e5127c3aca4051c16f19d9c4b9de72
app_report=d20c715cbf1a49a6bc0f436b699cb90a4cc9a89d8da1e8a23b5b0cbb4e76b6ef
gamescope_report=e8b884b960ae000b1fd4a682dda8b3b3adf72feae11fc5e890771a8b55489cc0
android_input_report=edad2609d51b7f9b6e95cef69d71ecffa73b6d15d2ab46b996b06c38c4dc2e4f
```

## What the scheduler trace proves

The report contains 437 `paint_decision` records, 349 `present_call`
records, and 349 matching `present_return` records. It shows the expected
quiet-scene decisions with `has_repaint=0 should_paint=0`, followed by active
decisions with `has_repaint=1 should_paint=1` and a `present_call`.

At the first active transition, the shared monotonic clock records:

```text
paint_decision monotonic_ns=93026338513261 has_repaint=1 should_paint=1
present_call   monotonic_ns=93027043753000 layers=1
compose_begin  monotonic_ns=93027043774667 frame=0
ack_sent       monotonic_ns=93027109414406 frame=0
composite      frame=1
present_return monotonic_ns=93027109426958 result=0
```

The end of the bounded stream has the same ordering for frame 239:

```text
paint_decision monotonic_ns=93153705236493 has_repaint=1 should_paint=1
present_call   monotonic_ns=93153705287639 layers=1
compose_begin  monotonic_ns=93153705384827 frame=239
ack_sent       monotonic_ns=93153707370556 frame=239
composite      frame=240
present_return monotonic_ns=93153707392743 result=0
```

This is enough to distinguish a scheduler decision, Gamescope `Present()`,
AHB composition/ACK, and the Android-side bounded result within one run. It
also confirms that the diagnostic did not reintroduce unconditional global
repainting: idle decisions remain visible and the active transition is
explicit.

## What remains unproven

The scheduler and AHB traces identify timing and transport events, not the
visual content in the buffer. The screenshot/crop hashes prove that captures
were taken, but they do not establish that a particular Gamescope frame ID
produced a particular Android or X11 image. The next implementation should
carry a stable producer frame/commit ID and a visual checksum through the AHB
report path, then correlate it with same-run Android SurfaceControl and X11
captures. Steam login remains rejected until that correlation also agrees with
the visible screenshot and DOM state.

## Profile correction

An earlier run, `ahb-only-20260809T120000Z-scheduler-repro`, used the synthetic
SHM Gamescope control profile instead of the native Steam/Xwayland controller
wrapper. It failed closed at the expected first-frame boundary
(`ack_bytes=0`, `frames=0`, `ahb_double_buffer=fail`, broken Wayland pipe) and
was not used as a scheduler or presentation result. The corrected run above
uses the established native profile and is the only device evidence accepted
by this document.
