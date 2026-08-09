# Nova settled X11 presentation timing result — 2026-08-09

Status: valid synchronized device result. The settled X11 window contains
visible Steam UI, while the same-run Android AHardwareBuffer screenshot remains
dark and diagnostic-marker-only. This resolves the remaining capture-timing
hypothesis and moves the presentation fault boundary into the Gamescope
AHardwareBuffer output path.

## Run identity and provenance

```text
run_id=controller-ui-20260809T-settled-x11-1280x960-v2
profile=controller-ui-1280x960-resolution-settled-x11
run_started_utc=2026-08-09T10:47:45Z
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
gamescope=/tmp/nova-gamescope-frame-identity-final.AOqe48/out-libei/src/gamescope
gamescope_sha256=f7035c838a2e9e91a36c388d00832709d941afdf12e1fb08dd377085dfe3b22c
gamescope_source=/tmp/nova-gamescope-frame-identity-final.AOqe48/source
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
gamescope_source_status_sha256=d8554a591ad45ff80921c48b581bb32857b4e365c978e1b963002ab242c306d3
gamescope_source_diff_sha256=ed675c36d4e8a01f85246a719a7a1edb68e337a5ffa953d028be5f87eaf99220
gamescope_submodules_sha256=ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
gamescope_libei=1
apk_sha256=883b03553b74a13dd98f0b7bdca9631be1327748eb2a5593fd9b19dd32227e8d
x11_capture_helper_sha256=a8971824bfcb812139bcc7451a1ab2c262b4a2af0ff9d462e25206a3efb4b017
fullscreen_presentation=1
producer=1280x960
android_destination=1280x960
input=android-keyevent KEYCODE_BUTTON_A(96) -> BTN_SOUTH(304)
```

The run retained the doc 100 Steam/Gamescope profile and changed only the
predeclared settled X11 capture phase. It enabled
`NOVA_CONTROLLER_UI_X11_CAPTURE_AFTER_SETTLE=1`, waited the existing 30-second
settle interval, dismissed the Android overlay, captured the mapped X11 window,
and immediately sampled the Android surface. The AHB frame count remained 240,
with identity, marker, socket, scheduler, and cleanup diagnostics enabled.

## Result

The fresh bounded controller run reached Steam readiness, and the settled X11
capture succeeded:

```text
controller_ui_ready=1 app_pid=1844
nova_x11_capture_status=pass phase=settled window_id=0x1e0003b
controller_ui_surface=missing
android_key_forwarded=none
native_steam_controller_ui_input_smoke=fail
```

The settled X11 PPM is not black. Its signal statistics were:

```text
YMIN=24 YLOW=26 YAVG=37.01 YHIGH=49 UMIN=87 UMAX=132 VMIN=92 VMAX=128
```

Visual inspection shows the Steam Big Picture/OOBE language screen: a dark
Steam UI panel with `Bun-venit / Selectați o limbă`, a language list, and the
bottom `MENU`/`SELECT` controls. The settled PPM SHA-256 is
`81d42c373bc6fa1515e472e6b42aeb1350bab61408b989111c98bee1bab077c8`; the
derived PNG SHA-256 is
`b5013d3b0290819d476e8fb80c058b035123b74f450ba640dc2d389d898a5109`.

The immediately following Android screenshot remains dark and marker-only,
with no visible Steam panel. Its SHA-256 is
`158cf3d46dff6628bc1ee390af05ed2095071a7ef0a08946b434e684c8a270e2`.
Because the strict visible Android Steam-surface gate failed, no A-button was
sent and no navigation result is claimed.

## AHB, Gamescope, and SurfaceFlinger evidence

The lower-level AHB exchange still completed:

```text
ahb_double_buffer_frame_identity_239=pass producer_frame=239 focus_commit=0 override_commit=0 checksum_fnv1a64=e9d70e8ba2210383 checksum_status=0
ahb_double_buffer_frame_marker_239=pass producer_frame=239 checksum_low16=0383 marker_status=0 checksum_status=0
ahb_double_buffer_frames=240 releases=239
ahb_frame_marker_capture=pass frame=239 checksum_low16=0383
headless_gamescope_ahb=pass
probe_status=0
```

SurfaceFlinger retained the active Nova layer at the native geometry, without a
destination transform, crop, or scale:

```text
geomBufferSize=[0 0 1280 960]
geomContentCrop=[0 0 1280 960]
geomLayerBounds=[0.000000 0.000000 1280.000000 960.000000]
composition type=DEVICE
```

These passes prove fresh buffer allocation, Gamescope/Android ownership and
fence progression, marker submission, and native-size SurfaceControl
composition. They do not prove that the Steam pixels rendered by Gamescope
were written into the AHB before the Android app wrote its diagnostic marker:
the current identity checksum is taken before marker writing, but the marker
itself is app-written after that checksum and is not a readback of the full
Gamescope image.

## Steam and renderer evidence

Fresh current-run Steam markers were present around the settled capture:

```text
Started webhelper process       2026-08-09 10:48:04
SteamUI connection ready        2026-08-09 10:48:09
OOBE Store: keyboards           2026-08-09 10:48:10
IPv4 connectivity test          2026-08-09 10:48:05 ... OK
IPv6 HTTP/UDP tests             2026-08-09 10:48:05 ... TIMEOUT
```

The native Steam wrapper completed its bounded software-renderer smoke path:

```text
client_output=1280x960
client_started=pass
client_status=124
client_timeout=expected
client_installed=pass
native_steam_smoke=pass
```

This remains the intentional `ANGLE (Mesa, softpipe)` / `swrast` path. The run
does not claim hardware-accelerated graphics, audio, touchscreen, login, or
end-user networking acceptance. IPv4 connectivity is observed only; the
visible screen is still the OOBE language page, not a login-complete result.

## Decision and next boundary

The same-run settled pair rejects capture timing as the primary explanation:
Steam is visible in the X11 source after the Android screenshot's settle point,
but the Android AHB destination is not. It also keeps the resolution and
SurfaceControl geometry hypotheses rejected. Do not change CEF, Xwayland,
resolution, or input based on this result.

The next one-variable diagnostic should inspect the AHB contents immediately
after Gamescope's acquire fence and before the app writes the frame marker. It
should record the actual `AHardwareBuffer_Desc` width, height, stride, format,
and a bounded raw-pixel/luma summary, preserving the existing checksum and
marker ordering. This distinguishes “Gamescope did not write Steam pixels into
the AHB” from “SurfaceControl/HWC displayed the wrong contents.”

Source inspection identifies the highest-value import facts to verify before a
fix: the Gamescope bridge currently describes the imported dmabuf as
`DRM_FORMAT_ABGR8888`, assumes `stride=width*4`, uses
`DRM_FORMAT_MOD_INVALID`, and does not receive the AHardwareBuffer's actual
stride or descriptor metadata. The imported output is also initialized through
the linear Vulkan image path. These are hypotheses, not yet fixes; the raw AHB
probe should precede changing format, stride, modifier, or tiling semantics.

The explicit post-stop verifier passed residual-process, app-file, trace,
scheduler, frame-identity, frame-marker, and ACK-timeout cleanup checks:

```text
post_stop_report_sha256=a669f556f98acc49ee788771714b36ae92b0b07c00785e8c1930b201ac642ec2
post_stop_verification=pass
```

## Retained artifacts

The complete run is retained under:

```text
android/nova-lab/build/manual-runs/controller-ui-20260809T-settled-x11-1280x960-v2/
```

Key artifact hashes:

```text
controller-ui-output.txt=0c3ef93f04be0a159180c47458aa844fe90ebfd420c9837e98f6d1cd300bce6a
device-gamescope-headless-ahb-report.txt=a669f556f98acc49ee788771714b36ae92b0b07c00785e8c1930b201ac642ec2
device-gamescope-headless-ahb-screenshot.png=158cf3d46dff6628bc1ee390af05ed2095071a7ef0a08946b434e684c8a270e2
x11-steam-settled.ppm=81d42c373bc6fa1515e472e6b42aeb1350bab61408b989111c98bee1bab077c8
x11-steam-settled.png=b5013d3b0290819d476e8fb80c058b035123b74f450ba640dc2d389d898a5109
x11-capture-settled-status.txt=143df99f0bdb3165eba056c155f74aa04655b987f2a3e97f2fdbbd67fcd8d14f
post-stop-verification-explicit.txt=76e07d7ea96e34647424c4576fc9707bf8c4ce09be4f1a0b83b20468a0633e30
```
