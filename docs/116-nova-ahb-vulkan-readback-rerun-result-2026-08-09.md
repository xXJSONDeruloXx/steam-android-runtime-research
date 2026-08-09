# Nova Vulkan AHardwareBuffer readback rerun result — 2026-08-09

Status: valid lower-level producer/import-path split; Android Steam
presentation, gamepad navigation, login, touch, audio, networking, hardware
graphics, and standalone launch remain open.

## Decision

The corrected rerun executed the Gamescope Vulkan readback at frame 239 and
produced a valid 1280×960, 4,915,200-byte logical RGBA result. Its bytes were
all zero:

```text
android_ahb_vulkan_readback_239=pass frame=239 buffer=2 bytes=4915200 width=1280 height=960 fnv1a64=e9d70e8ba2210383 rgba_min=0,0,0,0 rgba_max=0,0,0,0 first=0,0,0,0 center=0,0,0,0 last=0,0,0,0
```

The same-frame APK raw AHardwareBuffer capture passed with changing/nonzero
diagnostic content and a different checksum:

```text
ahb_double_buffer_frame_content_239=pass producer_frame=239 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 pixels=1228800 raw_fnv1a64=331219c317e02083 rgba_min=0,0,0,0 rgba_max=255,255,255,255 rgba_avg_milli=510,1953,727,1024 luma_min=0 luma_max=255 luma_avg_milli=1379
ahb_double_buffer_raw_capture_239=pass producer_frame=239 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 bytes=4915200 pre_marker=1 raw_fnv1a64=331219c317e02083
```

This proves that the readback implementation and selected native-Steam
control path now execute, and that the post-export Vulkan view does not match
the CPU-visible AHardwareBuffer view. It does not yet prove whether the
composite shader wrote zeros, whether the external-image export/import
transition loses the content, or whether the physical AHardwareBuffer layout
is being interpreted differently by the two paths. The current readback is a
second command buffer after `vulkan_composite` has submitted and exported the
external image; the next diagnostic must read the same image inside the
original composite command before that export boundary.

## Gate summary

```text
controller_ui_ready=1
controller_ui_surface=missing
native_steam_smoke=pass
ahb_double_buffer_raw_capture_239=pass
ahb_raw_capture=pass frame=239 bytes=4915200
nova_ahb_raw_decode=pass
ahb_double_buffer_frames=240 releases=239
android_ahb_vulkan_readback_239=pass
post_stop_verification=pass
```

The outer controller wrapper returned status 1 only because the strict
Android Steam-surface gate was missing and therefore no Android key event was
sent. The bounded producer/import run and explicit cleanup verifier passed.
The settled X11 capture completed, but it is not an Android presentation or
input result.

## Run provenance

```text
run_id=controller-ui-20260809T135726Z-vulkan-readback-rerun-1280x960
profile=controller-ui-vulkan-readback-rerun-1280x960
run_started_utc=2026-08-09T13:59:21Z
repo_commit=226816a
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
gamescope_binary=/tmp/nova-gamescope-ahb-vulkan-readback-202609-out2/src/gamescope
gamescope_binary_sha256=12a19e022aad45ae3468530a9ea9ed79a2d8f404ce8649457733aa5fc53b5308
gamescope_libei_build=enabled
gamescope_input_emulation=enabled
nova_apk=/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/nova-lab-debug.apk
nova_apk_sha256=913d008da24951e9e493d9bbcbd41e96526e61732016c78042ce4a3bed010014
gamescope_source_tree=/tmp/nova-gamescope-ahb-vulkan-readback-source2-20260809
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
gamescope_source_dirty=1
gamescope_source_status_sha256=d8554a591ad45ff80921c48b581bb32857b4e365c978e1b963002ab242c306d3
gamescope_source_diff_sha256=a42cbbdbfcf24bbd08a7bfe8689ebbc8306f3b384c0b3fe7f252d2ce88a46af9
gamescope_source_submodules_sha256=ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
fullscreen_presentation=1
fullscreen=1280x960
ahb_buffer=1280x960
ahb_usage=0x333
ahb_frames=240
NOVA_AHB_OUTPUT_TILING=optimal
NOVA_AHB_VULKAN_READBACK=1
NOVA_AHB_VULKAN_READBACK_FRAME=239
NOVA_AHB_RAW_CAPTURE=1
NOVA_AHB_RAW_CAPTURE_FRAME=239
NOVA_AHB_FRAME_IDENTITY=1
NOVA_AHB_FRAME_MARKER=1
NOVA_AHB_CONTENT_PROBE=1
NOVA_AHB_TRACE=1
NOVA_AHB_SOCKET_TRACE=1
NOVA_AHB_SCHEDULER_TRACE=1
NOVA_AHB_ACK_POLL_TIMEOUT_MS=0
NOVA_CONTROLLER_UI_INPUT_MODE=android-keyevent
NOVA_CONTROLLER_UI_X11_CAPTURE_AFTER_SETTLE=1
NOVA_CONTROLLER_UI_REQUIRE_STEAM_SURFACE=1
```

The retained run directory is:

```text
/Users/kurt/Developer/steam-android-runtime-research/android/nova-lab/build/manual-runs/controller-ui-20260809T135726Z-vulkan-readback-rerun-1280x960/
```

## Retained artifact hashes

```text
device-gamescope-headless-ahb-report.txt  sha256=7ea5d999e7dc1e026e3a2e0a2c14216bed703fa3ce8bf75f204776f1cae548ab
device-gamescope-headless-ahb-logcat.txt  sha256=6441b2a0439d48f979e93d15182a94a7c74795ab7d454f35d4eda68633ec36fb
device-gamescope-headless-ahb-app-report.txt sha256=c183d5e93686800b04ece5c4e7bc994c38f6f0a8d48b7852c8b18b412cc20e0f
device-gamescope-headless-ahb-screenshot.png sha256=57d8d99997c8a5781b41a64da858bc9fa4c90b7b6ea669a53cf59bafbf8e612e
nova-ahb-raw-frame.rgba                  sha256=85108fef4a41eac057c6a60f74380e27fe5070f8b9a0a81153032640c4c220bf
nova-ahb-raw-frame.png                   sha256=8bbac1dcaa74eb3e2f59921a140fdb4b4fadb905b725ce76e5e347e5ed83d952
nova-ahb-raw-frame-decode.txt            sha256=be04f26711b302843252c58fa747bd2c7ddbcb3233d50b6ea9822a457e957402
x11-steam-settled.ppm                   sha256=20c65f3ddf3df849bcacff6e4c64555b80e37f5f3e2f9bd92aaf4d919bd9da71
x11-capture-settled-status.txt           sha256=28d2cc255d0bed3cc14c36381a2e14c40b3afe4323d88d7fa738c91350281bc6
device-surfaceflinger.txt                sha256=d044063639802ee86cf5a39642ddde620e7935722490f497fb7629f490473f3b
device-gamescope-headless-ahb-metadata.txt sha256=d4c43c1576344e7be296071f05fc84e1edce5e518121518d382da5ea539bdb24
device-gamescope-headless-ahb-preflight.txt sha256=091f6b0789c45effee2aa29409cbdab414494ccc9d75b485ffc56342695d13a1
post-stop-verification-explicit.txt      sha256=62feb1f973f689588762aea63ae77167f6758c78a7245896016fc78e36fe7051
```

The pulled setup report was retained at
`android/nova-lab/build/holo-glibc-report.txt` with SHA-256
`8efa138b2332468f08d05fdf6d802c13cdf13e8df550401f52fed5103175bc4a`.

## Next diagnostic

Add an opt-in pre-export readback request to `vulkan_composite`: queue the
image-to-buffer copy in the same command buffer after the composite dispatch,
before the command's external-image export barrier, then hash the mapped
buffer after the existing sequence wait. Keep the current post-export line
available or label the new line distinctly so the two boundaries cannot be
confused. Run the same fresh 1280×960 contract and use the three-way result to
separate composite-shader output from external export/import and CPU/HWC
visibility. Do not advance to Android input or login based on this split alone.
