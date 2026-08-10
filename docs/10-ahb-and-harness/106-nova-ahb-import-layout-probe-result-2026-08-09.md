# Nova AHB import-layout probe result — 2026-08-09

Status: valid lower-level device result. The exact loop allocation profile can
be imported and written through Android Vulkan with optimal tiling, but the
current Gamescope DMA-BUF import path still leaves every sampled pre-marker
AHardwareBuffer byte zero. This keeps the presentation fault at Gamescope's
external-image layout/write boundary. It does not reopen any end-user UI,
input, audio, networking, hardware-GL, login, or launcher gate.

## Run identity and provenance

```text
run_id=direct-20260809T114947Z-ahb-import-layout-report
profile=direct-ahb-import-layout-report
run_started_utc=2026-08-09T11:49:59Z
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
gamescope=/tmp/nova-gamescope-frame-identity-final.AOqe48/out-libei/src/gamescope
gamescope_sha256=f7035c838a2e9e91a36c388d00832709d941afdf12e1fb08dd377085dfe3b22c
gamescope_source=/tmp/nova-gamescope-frame-identity-final.AOqe48/source
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
gamescope_source_dirty=1
gamescope_source_status_sha256=d8554a591ad45ff80921c48b581bb32857b4e365c978e1b963002ab242c306d3
gamescope_source_diff_sha256=ed675c36d4e8a01f85246a719a7a1edb68e337a5ffa953d028be5f87eaf99220
gamescope_source_submodules_sha256=ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
gamescope_libei=1
apk_sha256=4e7959a7e6ff30e6c7e074bad11b5a0aec3a7e567bbe828f718d07ff48dab983
fullscreen_presentation=0
force_gpu_composition=1
producer=1280x960
android_destination=1280x960
android_vulkan_layout_usage=0x333
frames=30
```

This is a fresh direct bounded run using the rebuilt APK and the same
Gamescope/Xwayland control profile as the preceding exact-profile attempt.
The run used `NOVA_ANDROID_VULKAN_LAYOUT_PROBE=1`,
`NOVA_AHB_CONTENT_PROBE=1`, and `NOVA_AHB_FRAME_IDENTITY=1`; no Gamescope
import behavior was changed.

## Android Vulkan result

The independent Android Vulkan probe allocated the exact loop profile:

```text
android_vulkan_probe_version=1
ahardwarebuffer.profile=1280x960 format=0x1 usage=0x333
ahardwarebuffer.supported=1
ahardwarebuffer.allocate_status=0
ahardwarebuffer.describe=1280x960 stride=1280 layers=1 format=0x1 usage=0x333
device=Adreno (TM) 740
extension.VK_ANDROID_external_memory_android_hardware_buffer=present
extension.VK_KHR_external_memory=present
extension.VK_KHR_external_memory_fd=present
extension.VK_EXT_external_memory_dma_buf=missing
extension.VK_EXT_image_drm_format_modifier=missing
vkCreateDevice_status=0
vkGetAndroidHardwareBufferProperties_status=0 allocation_size=4915200 memory_type_bits=0x12
vkCreateImage_status=0 tiling=0 usage=0xf
vkAllocateMemory_import_status=0 memory_type_index=1
vkBindImageMemory_status=0
android_vulkan_image_modifier_status=extension_missing
vkQueueSubmit_status=0
vkWaitForFences_status=0
ahardwarebuffer.lock_after_vulkan_status=0
vulkan_clear_pixel=4080c0ff
ahardwarebuffer.unlock_after_vulkan_status=0
android_vulkan_ahardwarebuffer=pass
```

Here `tiling=0` is `VK_IMAGE_TILING_OPTIMAL` from the probe source. The
Android Vulkan driver does not expose `VK_EXT_image_drm_format_modifier`, so
this result does not identify a DRM modifier. It does establish that the exact
size, stride, usage, and allocation can be imported, cleared, and read back on
the Adreno 740 without using a linear Vulkan image.

## Gamescope/AHB result

Gamescope accepted the three-buffer output, started its Wayland/Xwayland
control path, reached the bounded target, and exited with `probe_status=0`:

```text
Android AHardwareBuffer output imported: 3 x 1280x960 RGBA
Running compositor on wayland display 'gamescope-0'
Starting Xwayland on :0
android_ahb_target_reached=30
offscreen_probe_status=0
probe_status=0
```

The app-owned report contains 30 frame records and 29 releases. Representative
first, middle, and final samples are identical:

```text
ahb_double_buffer_frame_content_0=pass producer_frame=0 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 pixels=1228800 raw_fnv1a64=e9d70e8ba2210383 rgba_min=0,0,0,0 rgba_max=0,0,0,0 rgba_avg_milli=0,0,0,0 luma_min=0 luma_max=0 luma_avg_milli=0
ahb_double_buffer_frame_content_1=pass producer_frame=1 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 pixels=1228800 raw_fnv1a64=e9d70e8ba2210383 rgba_min=0,0,0,0 rgba_max=0,0,0,0 rgba_avg_milli=0,0,0,0 luma_min=0 luma_max=0 luma_avg_milli=0
ahb_double_buffer_frame_content_2=pass producer_frame=2 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 pixels=1228800 raw_fnv1a64=e9d70e8ba2210383 rgba_min=0,0,0,0 rgba_max=0,0,0,0 rgba_avg_milli=0,0,0,0 luma_min=0 luma_max=0 luma_avg_milli=0
ahb_double_buffer_frame_content_29=pass producer_frame=29 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 pixels=1228800 raw_fnv1a64=e9d70e8ba2210383 rgba_min=0,0,0,0 rgba_max=0,0,0,0 rgba_avg_milli=0,0,0,0 luma_min=0 luma_max=0 luma_avg_milli=0
ahb_double_buffer_frame_identity_29=pass producer_frame=29 focus_commit=0 override_commit=0 checksum_fnv1a64=e9d70e8ba2210383 checksum_status=0
ahb_double_buffer_frames=30 releases=29
```

The repeated `e9d70e8ba2210383` value is the FNV-1a checksum of the all-zero
active region. The ACK fields still report `linux_gpu_write=pass` and
`linux_image_write=pass`, but those fields are control-flow labels in the
current headless backend, not a readback of the imported image.

The direct diagnostic screenshot is retained but is not a Steam presentation
result: the Nova USB chooser overlay owned the Android window at capture time.
No Android Steam pixels are claimed from that screenshot. Earlier exact-profile
X11 evidence remains the source-side rendering evidence; this run adds the
independent Android Vulkan layout result and a clean app-owned capture of the
pre-marker bytes.

## Decision

This result rejects the following as the immediate explanation for the zero
content:

1. Android AHardwareBuffer allocation support for the exact profile.
2. The reported width/stride or RGBA8 format mismatch.
3. Android Vulkan's ability to import and write the same allocation profile.
4. A simple Gamescope frame-count or ACK-release failure.

It strengthens the remaining hypothesis that Gamescope's external DMA-BUF
image layout is incompatible with the Android allocation. The current path
constructs the import with `DRM_FORMAT_ABGR8888`,
`DRM_FORMAT_MOD_INVALID`, and forced `VK_IMAGE_TILING_LINEAR`; the independent
Android Vulkan import passed with `VK_IMAGE_TILING_OPTIMAL`.

## Next scoped experiment

Predeclare a new Gamescope-only A/B experiment, then add an opt-in
`NOVA_AHB_OUTPUT_TILING=optimal` mode while retaining the current linear mode
as the default. Keep the allocation profile, Steam flags, frame count, and
content probe fixed. Record the selected tiling mode and Vulkan import result
in the Gamescope report. Call the presentation boundary fixed only if the
pre-marker AHB samples become nonzero and frame-variable; a successful Vulkan
image creation alone is insufficient.

Until that gate passes, keep gamepad, touchscreen, networking, audio, hardware
GL, login, and standalone-launcher acceptance closed.

## Cleanup and retained artifacts

The bounded harness and the explicit post-stop verifier both passed:

```text
headless_gamescope_ahb=pass
nova_runtime_cleanup=pass
headless_ahb_residual_processes=pass
nova_app_runtime_files_cleanup=pass
post_stop_android_vulkan_layout_state=pass
post_stop_verification=pass
```

The complete run is retained under:

```text
android/nova-lab/build/manual-runs/direct-20260809T114947Z-ahb-import-layout-report/
```

Key artifact hashes:

```text
device-gamescope-headless-ahb-report.txt=f98de643d098ccc4b84cabc8b2e971fd1d80019188b17f40cb8a2f75c4fde8c4
device-gamescope-headless-ahb-app-report.txt=c9111ec1e3863c87e9d332c10e236398fa07c53e2b69836f68051d3ccc02b187
device-gamescope-headless-ahb-logcat.txt=07d3e42966e6335566cb701fd07195b622de4b5d64edfc687f82518a73096aa4
android-vulkan-layout-report.txt=a9590c39142d6d6ab91ba4db90bbeff39654c4df34023de84a50d64f3b824f2d
device-gamescope-headless-ahb-metadata.txt=7040ab49019fe071309315ff71828ffd0bae57eb3d03192f758679764a68af4c
device-gamescope-headless-ahb-preflight.txt=ec9960f3ddf704d5d3294c702a8c27f2a25c6333b46a3c08d85c4129f15f5708
device-gamescope-headless-ahb-screenshot.png=f3a99c007ef5bfa61fabd701168b80da653278cf60bd055a9cd330283ed690fd
post-stop-verification-explicit.txt=b1c47eb813167bc2d4aca9b754cb4d584d33e4d3bc31cfc5e0e340c2c4bb1c36
```
