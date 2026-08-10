# Nova optimal-tiling Steam-surface result — 2026-08-09

Status: valid lower-level device result; the Android end-user presentation and
gamepad-navigation gates remain open.

## Decision

The optimal-tiling importer removed the earlier all-zero output boundary and
the full 240-frame run carried changing, nonzero AHardwareBuffer bytes. It did
not make the Android SurfaceControl/HWC screenshot show Steam. The settled
X11 capture from the same native session shows Steam's Big Picture/OOBE
language screen, while the Android screenshot shows the diagnostic green-line
surface and a superuser toast.

This is a valid presentation-boundary result, not an end-user pass:

```text
controller_ui_ready=1
controller_ui_surface=missing
native_steam_smoke=pass
ahb_double_buffer_frames=240 releases=239
ahb_frame_marker_capture=pass frame=239 checksum_low16=2083
post_stop_verification=pass
```

The Android surface gate failed before input injection, so this run makes no
Android A-button navigation claim. The separate Steam input-fd probe did pass,
but that does not substitute for a visible Android Steam surface.

## Run identity and provenance

```text
run_id=controller-ui-20260809T-optimal-tiling-steam-1280x960
profile=controller-ui-optimal-tiling-steam-1280x960
run_started_utc=2026-08-09T12:48:18Z
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
gamescope_binary=/tmp/nova-gamescope-ahb-tiling-libei-20260809-out/src/gamescope
gamescope_binary_sha256=29c62f0b19aee09e111909cf6bee0c3df8b306380d93e133a1affa22b83bcfc0
gamescope_libei_build=enabled
gamescope_input_emulation=enabled
nova_apk=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/nova-lab-debug.apk
nova_apk_sha256=cc8acf22b881304f9cc8cdf7fa05d6b8af4b77df2e2c02655e6b57f772379550
gamescope_source_tree=/tmp/nova-gamescope-ahb-tiling-libei-20260809-source
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
gamescope_source_dirty=1
gamescope_source_status_sha256=69593c2eccc73b03fdaf2285d0f1c3217cda35a04c0d936560c43f635e42e1e0
gamescope_source_diff_sha256=b75a2aff21a4d423540721cb07db5b75a84e533227256dfa7fa33a65ba5d2c27
gamescope_source_submodules_sha256=ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
fullscreen_presentation=1
fullscreen=1280x960
ahb_buffer=1280x960
ahb_usage=0x333
nova_ahb_output_tiling=optimal
nova_ahb_ack_poll_timeout_ms=0
steam_client_timeout=180
steam_gamescope_timeout=300
```

The session intentionally retained the software CEF/GL profile (`swrast`,
`softpipe`). Hardware-accelerated graphics is a downstream acceptance gate,
not a claim from this presentation experiment.

## Fresh-run and cleanup gates

The run used a fresh process/log baseline, the predeclared 1280×960 profile,
and the exact-scope cleanup contract from [the lifecycle document](../00-start-here/34-nova-runtime-harness-lifecycle.md).
Preflight, runtime cleanup, residual-process checks, app-file cleanup, and the
explicit post-stop verifier all passed. The final verifier recorded:

```text
post_stop_residual_processes=pass
post_stop_app_files=pass
post_stop_trace_state=pass
post_stop_scheduler_trace_state=pass
post_stop_frame_identity_state=pass
post_stop_frame_marker_state=pass
post_stop_content_probe_state=pass
post_stop_android_vulkan_layout_state=pass
post_stop_ack_poll_timeout_state=pass
post_stop_verification=pass
```

The outer host wrapper also exposed a zsh reserved-variable error after the
inner run had completed. That wrapper defect did not invalidate the device
artifacts: the explicit verifier was rerun with the correct run variable and
passed. It is a harness cleanup item, not evidence about the Android surface.

## Producer-side AHB result

Gamescope logged three successful optimal-tiling imports:

```text
Android AHardwareBuffer output import begin tiling=optimal requested=optimal width=1280 height=960 format=0x34324241 modifier=0xffffffffffffff stride=5120
Android AHardwareBuffer output import result=pass tiling=optimal
```

The run then recorded `Android AHardwareBuffer output imported: 3 x
1280x960 RGBA`, successful libei initialization,
`android_ahb_target_reached=240`, `offscreen_probe_status=0`, and
`probe_status=0`.

The test-bench app completed all 240 producer frames and released 239. The
logical CPU readback probes show the transition from the initial diagnostic
pattern to frame-variable content:

```text
frame=0   raw_fnv1a64=2256ebda257e4783 rgba_max=49,99,49,49 luma_max=59
frame=30  raw_fnv1a64=1a3194ec60fcb483 rgba_max=255,255,255,255 luma_max=255
frame=150 raw_fnv1a64=e9fbc955f2c45c83 rgba_max=255,255,255,255 luma_max=255
frame=239 raw_fnv1a64=331219c317e02083 rgba_max=255,255,255,255 luma_max=255
```

Across the 240 frame-identity records there were 238 unique checksums. The
last frame marker was captured and correlated as
`frame=239 checksum_low16=2083`. This proves that the optimal output image is
not merely the stable all-zero result from the linear control or the stable
30-frame pattern from the earlier A/B run.

## Consumer-side presentation result

The settled X11 capture independently shows the native Steam scene. Its
derived PNG is 1280×960 and has SHA-256
`b2866110709172f90212cac1a32668b01689b26e52c4d420487e6c35490e2b10`.
The capture status was `pass`, with window id `0x1e0003b`.

The Android screenshot at the same native resolution was visually inspected
and contains thin green diagnostic lines on a dark background plus a
“Shell was granted Superuser rights” toast; it does not contain the Steam
language screen. Its SHA-256 is
`57d8d99997c8a5781b41a64da858bc9fa4c90b7b6ea669a53cf59bafbf8e612e`.

SurfaceFlinger evidence rules out a simple presentation geometry mistake:

```text
Nova double-buffer Linux image loop#29076
geomBufferSize=[0 0 1280 960]
geomContentCrop=[0 0 1280 960]
composition type=DEVICE
HWC AHardwareBuffer pid [6734] z: 1 format: RGBA_8888 transform: 0/0/0
AHardwareBuffer pid [6734] w/h:1280x960 usage: 0x333 compressed: false
planes: R/G/B/A: w/h:1280x960 stride:5120 bytes
display projection bounds/content: 1280x960, orientation=ROTATION_0
```

The Android consumer therefore receives a native-size, uncompressed RGBA
buffer with no scale or rotation indicated in the dump, yet the displayed
pixels remain the diagnostic pattern. The remaining boundary is most likely
the physical image contents/layout or synchronization as the Vulkan external
image is consumed by Android/HWC; this result does not distinguish those
subcases yet.

## Acceptance matrix

| Gate | Result | Evidence |
| --- | --- | --- |
| Fresh preflight and provenance | pass | run preflight and metadata |
| Native Steam session | pass | `native_steam_smoke=pass`; client timeout was expected |
| Settled native Steam source | pass | `x11-steam-settled.png` |
| Optimal AHB import | pass | three `tiling=optimal` import pairs |
| Frame-variable AHB content | pass | 238 unique identity checksums; changing content probes |
| Native-size Android layer | pass | SurfaceFlinger/HWC dump |
| Android Steam surface | fail | `controller_ui_surface=missing`; green-line screenshot |
| Android gamepad navigation | not run | strict surface gate prevented A-button injection |
| Post-stop cleanup | pass | explicit verifier |

## Next gate

Do not advance to login, touch, audio, networking, hardware GL, or standalone
launcher acceptance from this result. First add an opt-in, bounded raw logical
AHB snapshot to the test-bench APK, preserving the existing checksum and
cleanup contract. Decode that snapshot on the host and compare it with the
same-run X11 Steam image and Android screenshot:

1. If the raw AHB contains Steam pixels but Android still shows green lines,
   focus on SurfaceControl/HWC import, cache visibility, or physical layout.
2. If the raw AHB itself contains green lines, focus on the Gamescope Vulkan
   output-image write, format, stride, and transition path.

The snapshot experiment must be predeclared and committed before its next
device run.

## Retained artifacts

All artifacts are retained under:

```text
android/nova-lab/build/manual-runs/controller-ui-20260809T-optimal-tiling-steam-1280x960/
```

Key SHA-256 values:

```text
device-gamescope-headless-ahb-report.txt=f0cc4804630373a82fc50a430cc12751935ad078946d899479f904b45e586a66
device-gamescope-headless-ahb-app-report.txt=d5e9b2e753642c26fcffa1ee068d08ea6aae7aa2cd8171418f190a4e9b6dc0b6
device-gamescope-headless-ahb-logcat.txt=d1f6be250c12aa88c1fa6318ff34f2d0af5c24999072d2d6114071832e8855a4
device-gamescope-headless-ahb-metadata.txt=4fd8ae08f5bfaa0047d920227d93a947607a54d049b21b0430cb557335a9248f
device-gamescope-headless-ahb-preflight.txt=5a9f9f36c26bfe1263c06dd094edfcf607b1b774553da7ad4b8b309500c61da2
device-gamescope-headless-ahb-screenshot.png=57d8d99997c8a5781b41a64da858bc9fa4c90b7b6ea669a53cf59bafbf8e612e
device-surfaceflinger.txt=04c9403b2388c77713fe71d5f26c96e0650210432396c07616f8fce6dbe01162
x11-steam-settled.png=b2866110709172f90212cac1a32668b01689b26e52c4d420487e6c35490e2b10
x11-steam-settled.ppm=8382b813c282a1c9b09234e28aa7838d88cf0884cd7ae16e5b7041ec875f5588
post-stop-verification-explicit.txt=747c6482d8723043af8ced111ba673345fa8514bf84cdfcb55ab1932ec48e6e9
```
