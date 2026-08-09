# Nova AHB output-tiling A/B result — 2026-08-09

Status: valid paired device result. The opt-in optimal-tiling importer changes
the pre-marker AHardwareBuffer from reliably all-zero bytes to reliably
nonzero bytes on the Retroid Pocket Nova. This is a real improvement at the
Gamescope external-image write boundary, but it is not yet an end-user Steam
presentation pass: the optimal content is stable across the bounded run and
the captured screen is a diagnostic green-line pattern rather than Steam UI.

## Result

The exact one-variable A/B comparison used the same rebuilt Gamescope binary,
the same 1280×960 Android allocation profile, the same three-buffer protocol,
the same Xwayland/Steam flags, and the same 30-frame content and frame-
identity probes. Only `NOVA_AHB_OUTPUT_TILING` changed:

| Arm | Selected tiling | Gamescope imports | AHB frames/releases | AHB content | Interpretation |
| --- | --- | ---: | ---: | --- | --- |
| Control | `linear` | 3/3 | 30/29 | FNV-1a `e9d70e8ba2210383`; RGBA max `0,0,0,0`; luma max `0` | Import and frame protocol pass, but every sampled pixel is zero |
| Treatment | `optimal` | 3/3 | 30/29 | FNV-1a `2256ebda257e4783`; RGBA max `49,99,49,49`; luma max `59` | Content reaches the AHB, but the checksum is unchanged for every sampled frame |

Both arms reached `android_ahb_target_reached=30`, returned
`offscreen_probe_status=0` and `probe_status=0`, and initialized libei. Both
arms passed the exact preflight, runtime cleanup, residual-process check, and
explicit post-stop verifier.

## Run identity and provenance

```text
adb_serial=675a2365
device=Retroid Pocket Nova / Android 13
gamescope_binary=/tmp/nova-gamescope-ahb-tiling-libei-20260809-out/src/gamescope
gamescope_binary_sha256=29c62f0b19aee09e111909cf6bee0c3df8b306380d93e133a1affa22b83bcfc0
gamescope_libei_build=enabled
gamescope_input_emulation=enabled
gamescope_source_tree=/tmp/nova-gamescope-ahb-tiling-libei-20260809-source
gamescope_source_commit=fb9f84ee247a1f02b1a132da60e94585db84bf61
gamescope_source_dirty=1
gamescope_source_status_sha256=69593c2eccc73b03fdaf2285d0f1c3217cda35a04c0d936560c43f635e42e1e0
gamescope_source_diff_sha256=b75a2aff21a4d423540721cb07db5b75a84e533227256dfa7fa33a65ba5d2c27
gamescope_source_submodules_sha256=ffb0e5c788894ee2a5498ccffe0fcabd659805200bc9bed025ce78e02cc0f8b0
```

The source tree is marked dirty because it is the reproducible Gamescope
patch stack used for this build; the exact status, diff, and submodule hashes
are retained above and in both run manifests.

### Control

```text
run_id=tiling-linear-20260809T123004Z
profile=ahb-output-tiling-linear-1280x960
run_started_utc=2026-08-09T12:30:18Z
nova_ahb_output_tiling=linear
nova_apk_sha256=1360a82402daa2df1d725e76d12c38fe60a699da6dbfab976bf18f13f2f96e7b
```

### Treatment

```text
run_id=tiling-optimal-20260809T123413Z
profile=ahb-output-tiling-optimal-1280x960
run_started_utc=2026-08-09T12:34:28Z
nova_ahb_output_tiling=optimal
nova_apk_sha256=546b056c68dae81eaec2faaa5d8847abe7ebfba4f2b0d4d58deb2b9bad9bb79c
```

The APK hashes differ because each run retained a fresh run identity. The
Gamescope binary and source identity are the same across both arms.

## Fixed run contract

```text
profile=ahb-output-tiling-ab-1280x960
format=AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM
width=1280
height=960
usage=0x333
force_gpu_composition=true
frames=30
NOVA_AHB_CONTENT_PROBE=1
NOVA_AHB_FRAME_IDENTITY=1
NOVA_ANDROID_VULKAN_LAYOUT_PROBE=1
```

The Gamescope logs show the intended one-variable change while the imported
descriptor remains otherwise identical:

```text
linear:  Android AHardwareBuffer output import begin tiling=linear requested=linear width=1280 height=960 format=0x34324241 modifier=0xffffffffffffff stride=5120
linear:  Android AHardwareBuffer output import result=pass tiling=linear
optimal: Android AHardwareBuffer output import begin tiling=optimal requested=optimal width=1280 height=960 format=0x34324241 modifier=0xffffffffffffff stride=5120
optimal: Android AHardwareBuffer output import result=pass tiling=optimal
```

Each arm logged the three successful imports, `Android AHardwareBuffer output
imported: 3 x 1280x960 RGBA`, `Successfully initialized libei for input
emulation!`, and `android_ahb_target_reached=30`.

## AHB content evidence

The control report sampled the same all-zero active region at the beginning,
middle, and end of the run:

```text
ahb_double_buffer_frame_content_0=pass producer_frame=0 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 pixels=1228800 raw_fnv1a64=e9d70e8ba2210383 rgba_min=0,0,0,0 rgba_max=0,0,0,0 rgba_avg_milli=0,0,0,0 luma_min=0 luma_max=0 luma_avg_milli=0
ahb_double_buffer_frame_content_29=pass producer_frame=29 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 pixels=1228800 raw_fnv1a64=e9d70e8ba2210383 rgba_min=0,0,0,0 rgba_max=0,0,0,0 rgba_avg_milli=0,0,0,0 luma_min=0 luma_max=0 luma_avg_milli=0
```

The treatment report produced nonzero content with the same descriptor, but
the same checksum and statistics at every sampled content probe:

```text
ahb_double_buffer_frame_content_0=pass producer_frame=0 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 pixels=1228800 raw_fnv1a64=2256ebda257e4783 rgba_min=0,0,0,0 rgba_max=49,99,49,49 rgba_avg_milli=284,1727,501,439 luma_min=0 luma_max=59 luma_avg_milli=1153
ahb_double_buffer_frame_content_29=pass producer_frame=29 desc=1280x960 stride=1280 layers=1 format=0x00000001 usage=0x333 pixels=1228800 raw_fnv1a64=2256ebda257e4783 rgba_min=0,0,0,0 rgba_max=49,99,49,49 rgba_avg_milli=284,1727,501,439 luma_min=0 luma_max=59 luma_avg_milli=1153
```

The frame-identity checksum remained the same across all sampled producer
frames in both arms. The optimal screenshot shows thin green lines in the
upper output region, confirming visible nonzero diagnostic content, but both
screenshots show the Nova Linux Bridge Lab status surface rather than Steam
UI. No Steam scene, repaint, or frame-variable presentation is claimed from
these captures.

## Decision

This A/B result rejects the hypothesis that the current zero content is
independent of the Vulkan image tiling choice. Keeping the DMA-BUF modifier
as `DRM_FORMAT_MOD_INVALID` and changing only the selected Vulkan tiling mode
is sufficient to change the bytes read back from the Android allocation:

1. `linear` is not an acceptable output mode on this device: its import,
   ACK/fence, and frame counters pass while its sampled AHB remains all zero.
2. `optimal` is a valid output-mode candidate: its imports pass and its
   sampled AHB is nonzero.
3. `optimal` is not yet the complete presentation fix: the content is stable
   and diagnostic, not frame-variable Steam output.

The next fault boundary is therefore narrower. Preserve optimal tiling as the
diagnostic baseline and investigate dynamic repaint/content propagation,
image write visibility, queue/layout synchronization, or the actual composite
destination before reopening UI or input acceptance. Do not interpret the
Gamescope ACK fields or the successful import alone as end-user presentation.

## Next scoped gate

Predeclare the next experiment before another device run. Keep optimal tiling,
the allocation profile, and the cleanup contract fixed, then establish a
known-changing producer or settled Steam scene and correlate, in the same
run:

1. the X11/Steam source frame identity;
2. Gamescope's selected output image and present/composite events; and
3. the Android pre-marker AHB checksum and settled screenshot.

If the AHB becomes nonzero and frame-variable with a settled Steam capture,
then proceed through the existing UI, gamepad, touch, login/network, audio,
hardware-GL, and standalone-launcher gates in order. If it remains a stable
green-line or otherwise non-Steam pattern, stay at the presentation boundary
and instrument the output image write/transition path rather than escalating
to input or network hypotheses.

## Cleanup and retained artifacts

Both runs passed the exact cleanup contract and explicit post-stop verifier:

```text
headless_gamescope_ahb=pass
nova_runtime_cleanup=pass
headless_ahb_runtime_cleanup=pass
headless_ahb_residual_processes=pass
nova_app_runtime_files_cleanup=pass
post_stop_residual_processes=pass
post_stop_app_files=pass
post_stop_android_vulkan_layout_state=pass
post_stop_verification=pass
```

The complete run directories are retained at:

```text
android/nova-lab/build/manual-runs/tiling-linear-20260809T123004Z/
android/nova-lab/build/manual-runs/tiling-optimal-20260809T123413Z/
```

Key retained artifact hashes:

```text
tiling-linear-20260809T123004Z/
  device-gamescope-headless-ahb-report.txt=e254a68a689e24b58eda8c1b2983d5106171b81fa4fc8892be5314ba921ae018
  device-gamescope-headless-ahb-app-report.txt=ca5e2ce93f5e685327a3a40a78934908c7cb2bab98889ef9bab533303bf33d62
  device-gamescope-headless-ahb-logcat.txt=811faac7e091367c46b6e7e8113cd2b5b93f8af997b58e288eedf06380c3925d
  device-gamescope-headless-ahb-metadata.txt=6ca95171f2e74905539c72dc25a2e72bf0f4781bf4e998c5fabbb6d323492c54
  device-gamescope-headless-ahb-preflight.txt=58af1a0da8165681722aa7d88ebbbdf36620d957c8941947e12eadb6a58fc9f6
  android-vulkan-layout-report.txt=b9db06319f222e619ec47b4c13cf8c0193ffda0f2177f65772f95b0d91a5fd21
  device-gamescope-headless-ahb-screenshot.png=56cba3a68d0726fe7ba3b3e219d2a30cfab9901ba1bd21e9557f774058a42995
  post-stop-verification-explicit.txt=cbf898018f767a879797eb7c04024a7c5d5b00f5f74c2667b494cb0fa5e85891

tiling-optimal-20260809T123413Z/
  device-gamescope-headless-ahb-report.txt=da792d3eecab7c62b4bfec9eae0cef5aa7f4e28e0b8860a804fadcbb9e6a6691
  device-gamescope-headless-ahb-app-report.txt=7463658fe141765646667696d722966bcf59648cfc1c18cb6e56e1484c7200c1
  device-gamescope-headless-ahb-logcat.txt=1074a1aaf01a827995c036d7fd6518c26f98d170fec7292045045c3fafd2a51e
  device-gamescope-headless-ahb-metadata.txt=c2e4d6f1e8706d531e7ddb915a4b5bcf7a9c5e51cfaf8c34347271a11d9ed2fb
  device-gamescope-headless-ahb-preflight.txt=7bb1da0bbc1df685963f685b90200b6679119685190c5cf55e3d7a36ecad8904
  android-vulkan-layout-report.txt=8dca3d9d47decd82b91d95a654468059233909dc293c627a2eb05098093e2501
  device-gamescope-headless-ahb-screenshot.png=fc059ddaddb9a2443a7b27ab898f1aaf182f8580d92c6bf5d5ec123fe1bdec19
  post-stop-verification-explicit.txt=981f7e5bf393e957fb559915bbfa0d7c621ec02753d1672fdd4ad7a36a3faa08
```
