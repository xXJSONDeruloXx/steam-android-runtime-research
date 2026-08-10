# Nova AHB pre-marker content probe result — 2026-08-09

Status: valid synchronized device result. The pre-marker probe found the AHB
contents uniformly zero after every sampled Gamescope acquire fence, while the
same-run settled X11 window contained visible Steam UI. The AHB descriptor's
native stride and RGBA8 format match the current Gamescope assumptions, so this
run rejects stride/format metadata mismatch as the primary cause. The remaining
fault boundary is Gamescope's imported AHB target/write path.

## Run identity and provenance

```text
run_id=controller-ui-20260809T-pre-marker-content-1280x960
profile=controller-ui-pre-marker-content-1280x960
run_started_utc=2026-08-09T11:08:13Z
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
gamescope=/tmp/nova-gamescope-frame-identity-final.AOqe48/out-libei/src/gamescope
gamescope_sha256=f7035c838a2e9e91a36c388d00832709d941afdf12e1fb08dd377085dfe3b22c
gamescope_source=/tmp/nova-gamescope-frame-identity-final.AOqe48/source
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
gamescope_source_dirty=1
gamescope_source_status_sha256=d8554a591ad45ff80921c48b581bb32857b4e365c978e1b963002ab242c306d3
gamescope_source_diff_sha256=ed675c36d4e8a01f85246a719a7a1edb68e337a5ffa953d028be5f87eaf99220
gamescope_submodules_sha256=ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
gamescope_libei=1
apk_sha256=ed36e2f96466c3e2b72250b3a65cba9917cc8855952f558aedbc1b11e1468cf7
x11_capture_helper_sha256=a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206a3efb4b017
fullscreen_presentation=1
producer=1280x960
android_destination=1280x960
input=android-keyevent KEYCODE_BUTTON_A(96) -> BTN_SOUTH(304)
```

The run retained the doc 102 settled X11 profile and enabled only the
predeclared `NOVA_AHB_CONTENT_PROBE=1` APK/harness diagnostic. AHB identity,
surface marker, socket, scheduler, presentation, and cleanup diagnostics were
otherwise unchanged. The run's metadata records the final APK hash after the
nested build step.

## Synchronized presentation result

Fresh Steam readiness markers were present:

```text
Started webhelper process       2026-08-09 11:08:32
SteamUI connection ready        2026-08-09 11:08:37
OOBE Store: keyboards           2026-08-09 11:08:38
IPv4 connectivity test          2026-08-09 11:08:33 ... OK
IPv6 HTTP/UDP tests             2026-08-09 11:08:33 ... TIMEOUT
```

The settled X11 capture succeeded with fresh window `0x240003b`. Its signal
statistics were:

```text
YMIN=24 YLOW=26 YAVG=37.3121 YHIGH=49 UMIN=87 UMAX=132 VMIN=92 VMAX=128
```

Visual inspection shows the Steam Big Picture/OOBE language screen (`Willkommen
/ Sprache auswählen`) with the language list and bottom `MENU`/`SELECT`
controls. The settled PPM SHA-256 is
`5115248143ca3681e9771d00abd2b14867fd18794691c8efd4c7f79412497bac`; the
derived PNG SHA-256 is
`e7afc4e19685a9f9946c1787897efe0a46e785af1b245882c4d938be81c5276c`.

The immediately sampled Android screenshot remains dark and diagnostic-
marker-only, with no Steam panel. Its SHA-256 is
`158cf3d46dff6628bc1ee390af05ed2095071a7ef0a08946b434e684c8a270e2`.
The strict Android Steam-surface gate therefore failed; no A-button was sent,
and no navigation result is claimed. The native Steam smoke path itself passed.

## Pre-marker AHB content evidence

The opt-in probe passed on every retained sample, but every active pixel was
zero before the marker write. Representative first, middle, and final samples
were identical:

```text
ahb_double_buffer_content_probe=enabled sample_policy=first3_every30_final
ahb_double_buffer_frame_content_0=pass producer_frame=0 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 pixels=1228800 raw_fnv1a64=e9d70e8ba2210383 rgba_min=0,0,0,0 rgba_max=0,0,0,0 rgba_avg_milli=0,0,0,0 luma_min=0 luma_max=0 luma_avg_milli=0
ahb_double_buffer_frame_content_2=pass producer_frame=2 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 pixels=1228800 raw_fnv1a64=e9d70e8ba2210383 rgba_min=0,0,0,0 rgba_max=0,0,0,0 rgba_avg_milli=0,0,0,0 luma_min=0 luma_max=0 luma_avg_milli=0
ahb_double_buffer_frame_content_120=pass producer_frame=120 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 pixels=1228800 raw_fnv1a64=e9d70e8ba2210383 rgba_min=0,0,0,0 rgba_max=0,0,0,0 rgba_avg_milli=0,0,0,0 luma_min=0 luma_max=0 luma_avg_milli=0
ahb_double_buffer_frame_content_239=pass producer_frame=239 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 pixels=1228800 raw_fnv1a64=e9d70e8ba2210383 rgba_min=0,0,0,0 rgba_max=0,0,0,0 rgba_avg_milli=0,0,0,0 luma_min=0 luma_max=0 luma_avg_milli=0
```

`format=0x00000001` is the allocated
`AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM`; `stride=1280` equals the active
width. This is direct device evidence against the previously suspected
width/stride mismatch. The repeated checksum is the FNV-1a value for the
all-zero active region, not the later diagnostic marker checksum.

The transport and marker gates still passed:

```text
ahb_double_buffer_frame_identity_239=pass producer_frame=239 focus_commit=0 override_commit=0 checksum_fnv1a64=e9d70e8ba2210383 checksum_status=0
ahb_double_buffer_frame_marker_239=pass producer_frame=239 checksum_low16=0383 marker_status=0 checksum_status=0
ahb_double_buffer_frames=240 releases=239
ahb_frame_marker_capture=pass frame=239 checksum_low16=0383
headless_gamescope_ahb=pass
probe_status=0
```

This exposes an important observability gap: Gamescope's ACK payload still says
`linux_gpu_write=pass` and `linux_image_write=pass`, but those fields are
currently hard-coded in the headless backend. They describe control flow and
fence handoff, not a readback of the imported image. The pre-marker probe is
stronger evidence for actual bytes and shows that those ACK labels must not be
treated as proof of a successful AHB write.

SurfaceFlinger retained the active layer `Nova double-buffer Linux image
loop#28343` at native geometry, with no transform, crop, or scale:

```text
geomBufferSize=[0 0 1280 960]
geomContentCrop=[0 0 1280 960]
geomLayerBounds=[0.000000 0.000000 1280.000000 960.000000]
composition type=DEVICE
```

The Android marker is still visible in the retained screenshot, proving that
the app can write and submit the AHB and that SurfaceControl can display that
buffer. Combined with the pre-marker all-zero result, this makes a downstream
SurfaceControl geometry problem unlikely.

## Decision and next boundary

The content probe resolves the next question:

1. X11 source is visibly rendering Steam after the settled delay.
2. Gamescope sends 240 ACKs and fences, but its imported AHB is all zero before
   the app marker.
3. Android displays the app marker in the same native-size layer.

Therefore do not change Steam readiness, CEF/Xwayland timing, resolution,
SurfaceControl geometry, or input. Do not treat the current ACK text as a
successful image-write proof.

The next scoped implementation should target the Gamescope external-image
import/write path. The highest-value one-variable test is an explicitly
declared linear DMA-BUF import using the AHB-compatible modifier/layout
metadata, with Gamescope-side logging of image creation, descriptor/image
layout, and the actual composite submission result. The current path constructs
the import as `DRM_FORMAT_ABGR8888` with `DRM_FORMAT_MOD_INVALID`, forces
`VK_IMAGE_TILING_LINEAR`, and assumes `stride=width*4`; the probe rejects the
stride assumption as the immediate cause but does not validate the external
memory layout or Vulkan queue ownership. A fix should be tested against the
same probe and require nonzero/varied pre-marker AHB pixels before any input or
end-user acceptance gate is reopened.

Hardware GL, audio, touchscreen, login, end-user networking, and standalone
launcher acceptance remain unclaimed.

## Cleanup and retained artifacts

The explicit post-stop verifier passed all old cleanup checks and the new
content-probe property reset:

```text
post_stop_report_sha256=d9190325b3b39036b4d448022def6c4533e4d0d9c1392498e06147fc848673fc
debug.nova.ahb_content_probe=0
post_stop_content_probe_state=pass
post_stop_verification=pass
```

The complete run is retained under:

```text
android/nova-lab/build/manual-runs/controller-ui-20260809T-pre-marker-content-1280x960/
```

Key artifact hashes:

```text
native-steam-smoke-output.txt=4664dd1440c545396ecc40307a63b13c4e3827c5f94f9656b69104bcf1f88760
device-gamescope-headless-ahb-metadata.txt=23e022eede7d94a7560926d3eaee8378a1e70828ad372ba1ed67cdf2b383557a
device-gamescope-headless-ahb-report.txt=d9190325b3b39036b4d448022def6c4533e4d0d9c1392498e06147fc848673fc
device-gamescope-headless-ahb-app-report.txt=f493ffd9933962f4ddb423242bf109bf5f6b24a121b5ec2b0cd59372d961ec95
device-gamescope-headless-ahb-screenshot.png=158cf3d46dff6628bc1ee390af05ed2095071a7ef0a08946b434e684c8a270e2
x11-steam-settled.ppm=5115248143ca3681e9771d00abd2b14867fd18794691c8efd4c7f79412497bac
x11-steam-settled.png=e7afc4e19685a9f9946c1787897efe0a46e785af1b245882c4d938be81c5276c
x11-capture-settled-status.txt=207604eefcecb48164b274a395d73238cc7201c47b8eed48d5068f593a9f182b
post-stop-verification-explicit.txt=cfeb52caa4ed186378522aee2845700ccf10df78f820cc8f155d2fd1607b4594
```
