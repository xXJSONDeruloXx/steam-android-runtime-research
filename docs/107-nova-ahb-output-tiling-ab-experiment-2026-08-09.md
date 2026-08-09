# Nova AHB output-tiling A/B experiment — 2026-08-09

Status: completed; see [the paired device result](108-nova-ahb-output-tiling-ab-result-2026-08-09.md).

## Question

The exact-profile Android Vulkan probe can import and clear the same
`1280x960`, RGBA8, usage `0x333` AHardwareBuffer with
`VK_IMAGE_TILING_OPTIMAL`, while the current Gamescope output importer forces
`VK_IMAGE_TILING_LINEAR`. The Gamescope path completes its frame protocol but
the app-side pre-marker content probe observes an all-zero AHB. This experiment
tests whether the imported image layout is the presentation boundary.

## One-variable change

Keep the Android APK, allocation profile, three-buffer protocol, Steam/Xwayland
flags, frame count, content probe, and cleanup contract fixed. Add a
Gamescope-only opt-in environment variable:

```text
NOVA_AHB_OUTPUT_TILING=linear   # control; current behavior/default
NOVA_AHB_OUTPUT_TILING=optimal  # treatment; VK_IMAGE_TILING_OPTIMAL
```

The Gamescope build must log the requested and selected mode, the DMA-BUF
descriptor, and import success/failure. The harness metadata must record the
mode and the full Gamescope source/binary provenance. No modifier value is
invented: the Android Vulkan probe does not expose
`VK_EXT_image_drm_format_modifier`, and the DMA-BUF descriptor continues to
use `DRM_FORMAT_MOD_INVALID`.

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

Each arm gets a fresh run ID, fresh log baseline, fresh APK report, and fresh
Gamescope artifact. Run the exact-scope Nova cleanup helper before launch and
after capture, and run the explicit post-stop verifier. Do not reuse an old
Steam log, socket, screenshot, readiness marker, or report.

## Decision rule

- If the optimal arm produces nonzero, frame-variable pre-marker AHB pixels
  while the linear control remains all-zero, record the optimal import as the
  presentation fix candidate and repeat it with a same-run settled X11 capture
  and an Android frame-identity correlation.
- If both arms remain all-zero, keep the tiling change rejected and inspect the
  external-memory import details that remain common to both arms: DMA-BUF
  ownership, memory binding, queue-family/layout barriers, and the actual
  composite write destination.
- If the optimal arm fails image creation/import, retain the Vulkan error and
  document that this device cannot use the proposed layout through the current
  DMA-BUF path.

A passing Gamescope import log, ACK, fence, or Android Vulkan clear alone does
not count as presentation success. The end-user UI gates remain closed until
the pre-marker AHB content is demonstrably nonzero and frame-variable.

## Required retained artifacts

Retain both arm metadata files, Gamescope reports, app-owned AHB reports,
Android Vulkan reports, screenshots, exact cleanup/preflight output, explicit
post-stop verification, APK hash, Gamescope binary hash, source commit/status/
diff/submodule hashes, and the selected tiling mode. Record the control and
treatment results in a separate result document before changing another
presentation or input variable.
