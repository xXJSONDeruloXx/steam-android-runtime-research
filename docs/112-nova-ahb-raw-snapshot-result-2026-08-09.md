# Nova raw AHardwareBuffer snapshot result — 2026-08-09

Status: valid lower-level producer/import-path result; Android Steam
presentation, gamepad navigation, login, and end-user acceptance remain open.

## Decision

The bounded raw AHardwareBuffer capture passed and decoded to a 1280×960 RGBA
PNG, but the raw PNG contains the same thin green diagnostic lines seen in the
Android screenshot rather than the Steam scene visible in the same-run settled
X11 capture. The strict Android surface gate therefore remained missing and no
Android input event was sent.

This moves the primary investigation boundary upstream of SurfaceControl/HWC:
the next work should inspect Gamescope's Vulkan external-image import, output
write, format/stride interpretation, physical tiling, and synchronization.
The raw CPU view does not by itself distinguish those producer-side subcases,
and it does not prove that Android's consumer path is perfect; it does rule out
the narrower hypothesis that the AHardwareBuffer contains Steam pixels and only
SurfaceControl/HWC turns them into the green diagnostic surface.

```text
controller_ui_ready=1
controller_ui_surface=missing
native_steam_smoke=pass
ahb_double_buffer_raw_capture_239=pass
ahb_raw_capture=pass frame=239 bytes=4915200
nova_ahb_raw_decode=pass
ahb_double_buffer_frames=240 releases=239
post_stop_raw_capture_state=pass
post_stop_verification=pass
```

## Run identity and provenance

The first invocation of the predeclared identity
`controller-ui-20260809T130645Z-raw-ahb-1280x960` was rejected before device
launch because the wrapper was called with the invalid literal value
`NOVA_FORCE_GPU_COMPOSITION=unset`. Its cleanup and property-reset checks
passed, and it is excluded from the device evidence below.

The valid run used a fresh identity and run directory:

```text
run_id=controller-ui-20260809T131106Z-raw-ahb-1280x960
profile=controller-ui-raw-ahb-1280x960
run_started_utc=2026-08-09T13:11:25Z
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
gamescope_binary=/tmp/nova-gamescope-ahb-tiling-libei-20260809-out/src/gamescope
gamescope_binary_sha256=29c62f0b19aee09e111909cf6bee0c3df8b306380d93e133a1affa22b83bcfc0
gamescope_libei_build=enabled
gamescope_input_emulation=enabled
nova_apk=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/nova-lab-debug.apk
nova_apk_sha256=916a059cb884ddd09dd3583ff793e55a2bdb97588d7850e3f53416eb17c95ff2
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
ahb_frames=240
NOVA_AHB_OUTPUT_TILING=optimal
NOVA_AHB_FRAME_IDENTITY=1
NOVA_AHB_FRAME_MARKER=1
NOVA_AHB_CONTENT_PROBE=1
NOVA_AHB_RAW_CAPTURE=1
NOVA_AHB_RAW_CAPTURE_FRAME=239
NOVA_AHB_TRACE=1
NOVA_AHB_SOCKET_TRACE=1
NOVA_AHB_SCHEDULER_TRACE=1
NOVA_AHB_ACK_POLL_TIMEOUT_MS=0
NOVA_STEAM_CLIENT_TIMEOUT=180
NOVA_STEAM_GAMESCOPE_TIMEOUT=300
NOVA_CONTROLLER_UI_WAIT_TIMEOUT=240
NOVA_CONTROLLER_UI_SETTLE_DELAY=30
NOVA_CONTROLLER_UI_INPUT_MODE=android-keyevent
NOVA_CONTROLLER_UI_ANDROID_KEYCODE=96
NOVA_CONTROLLER_UI_EVENT_CODE=304
NOVA_CONTROLLER_UI_X11_CAPTURE=1
NOVA_CONTROLLER_UI_X11_CAPTURE_AFTER_SETTLE=1
NOVA_CONTROLLER_UI_OVERLAY_GUARD=1
NOVA_CONTROLLER_UI_EXPECT_NAVIGATION=1
```

The software CEF/GL profile (`swrast`, `softpipe`) remained fixed. This is a
presentation/import diagnostic, not a hardware-accelerated graphics result.

## Producer and raw-capture evidence

Gamescope completed the optimal-tiling output import and the native Steam
smoke. The test-bench app's final report recorded:

```text
ahb_double_buffer_raw_capture=enabled target_frame=239 ... format=rgba8 layout=logical_rows pre_marker=1
ahb_double_buffer_frame_content_239=pass producer_frame=239 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 pixels=1228800 raw_fnv1a64=331219c317e02083 ...
ahb_double_buffer_frame_identity_239=pass producer_frame=239 ... checksum_fnv1a64=331219c317e02083 checksum_status=0
ahb_double_buffer_frame_marker_239=pass producer_frame=239 checksum_low16=2083 marker_status=0 checksum_status=0
ahb_double_buffer_raw_capture_239=pass producer_frame=239 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 bytes=4915200 ... pre_marker=1 raw_fnv1a64=331219c317e02083
ahb_double_buffer_frames=240 releases=239
ahb_double_buffer=pass
```

The host decoder recorded:

```text
nova_ahb_raw_decode=pass
nova_ahb_raw_size=1280x960
nova_ahb_raw_bytes=4915200
```

The raw logical RGBA image is visibly the dark green-line diagnostic pattern,
with a small white pattern near the upper-left. It is not the Steam language
selector. Its retained artifact hashes are:

```text
nova-ahb-raw-frame.rgba  sha256=85108fef4a41eac057c6a60f74380e27fe5070f8b9a0a81153032640c4c220bf
nova-ahb-raw-frame.png   sha256=8bbac1dcaa74eb3e2f59921a140fdb4b4fadb905b725ce76e5e347e5ed83d952
raw-frame-decode.txt     sha256=912e172a083783ba3e971ca193024bb9d227fe610037812fcdfe6c8076d39549
device-app-report.txt    sha256=3bfa6535f957435d2e586fde415bef548a4afb9d9b99b9a03d823e20d7ee1300
```

The changing pre-marker checksum is correlated with the frame-identity
checksum, so this is not evidence of a failed capture or a stale all-zero
buffer. The raw capture was taken before the app's marker write, as required by
the experiment contract.

## Same-run presentation split

The settled X11 source capture passed independently and is a 1280×960 RGB PNG
showing Steam Big Picture/OOBE's language selector. The Android screenshot is
also 1280×960 but shows the green-line diagnostic surface and a superuser
toast. The relevant hashes are:

```text
x11-steam-settled.png                    sha256=c760d1a810ad8d84f2716310b36313be76fa7eed3768ea468ea72a2ac049d4c7
x11-steam-settled.ppm                    sha256=dd84ac93c24bbab4d8d325c1f1a709dad027a961bf83109bb51f3a39f5237235
device-gamescope-headless-ahb-screenshot.png sha256=57d8d99997c8a5781b41a64da858bc9fa4c90b7b6ea669a53cf59bafbf8e612e
x11-capture-settled-status.txt           sha256=e8f01544d7cd6dae9c70a90fcab1f0b825139b4bad23f596e34dc06d0b0f0cb8
```

The X11 capture status was `pass` with window id `0x240003b`. The outer
controller wrapper ended with the expected strict-gate error because it did
not find `android_key_forwarded=pass`; that event was intentionally not sent
when `controller_ui_surface=missing`. The inner bounded AHB probe and native
Steam smoke both exited successfully.

SurfaceFlinger/HWC evidence confirms that the Android layer is being composed
at the requested native geometry, but it does not show Steam pixels:

```text
Nova double-buffer Linux image loop#29282 ... Comp Type DEVICE ... 0 0 1280 960
AHardwareBuffer pid [13981] ... composition: Device/Device ... format: RGBA_8888
name:AHardwareBuffer pid [13981] ... w/h:1280x960 usage: 0x333 req fmt:1 fourcc/mod:875708993/0 compressed: false
planes: R/G/B/A: w/h:1280x960, stride:5120 bytes, size:4915200
```

The surface dump therefore removes simple scaling, rotation, compression, and
native-size geometry as the leading explanation. It does not establish that
the imported image's physical layout or synchronization is correct.

## Cleanup and provenance hashes

The explicit post-stop verifier passed residual-process, app-file, trace,
frame-identity, frame-marker, content-probe, raw-capture-property, Android
layout-property, ACK-timeout-property, and overall verification checks. The
verifier recorded report SHA-256
`0c94b95647dd5463f50df59f8ef7104b453e71fee3824cbef1995677bd791bf0` before
derived host image conversion.

Key retained run artifacts:

```text
device-gamescope-headless-ahb-report.txt sha256=0c94b95647dd5463f50df59f8ef7104b453e71fee3824cbef1995677bd791bf0
device-gamescope-headless-ahb-logcat.txt sha256=567b3e63473533fe4694580ac451aa8515cacc7493fd3d4ee9cb8d16a00769fb
device-surfaceflinger.txt                sha256=0ba265e8d27eb4d2ecfa899b34f7727c8bc226a8ec143140b76546de075de68e
device-gamescope-headless-ahb-metadata.txt sha256=457b42129e7dae04b978adcb3324a227d1e89db9cb88433b12990c9c985a7c1d
device-gamescope-headless-ahb-preflight.txt sha256=ffb03119ba65f6be538d25b7762c55b1f908c5d797ac16d1710de99f7d9e38a5
post-stop-verification-explicit.txt       sha256=7d64a729f549837bf82ad26fed9084c78101540259790b2b1a9abf94051d81af
```

The run directory is
`android/nova-lab/build/manual-runs/controller-ui-20260809T131106Z-raw-ahb-1280x960/`.
The build output keeps these device artifacts outside the Git commit while
this result records their exact paths and hashes.

## Next diagnostic

Do not advance to Android input, login, touch, audio, networking, hardware GL,
or standalone-launcher acceptance yet. First add one bounded Gamescope-side
producer diagnostic on the same output image: either a Vulkan readback/hash of
the imported output after `vulkan_composite`, or an opt-in known-pattern write
that can be compared through the app's raw AHB capture. The diagnostic should
separate:

1. Vulkan's view of the imported image after the composite dispatch;
2. the bytes exposed by `AHardwareBuffer_lock` as logical rows; and
3. the image that SurfaceControl/HWC scans out.

Keep the current 1280×960 optimal-tiling profile, raw frame 239, software GL
profile, fresh run identity, and lifecycle cleanup contract fixed while
changing only that producer-side diagnostic. Commit the diagnostic and its
predeclared experiment before the next long device run.
