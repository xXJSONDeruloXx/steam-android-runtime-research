# Nova AHB import-layout probe experiment — 2026-08-09

Status: predeclared. This experiment answers the next presentation-layer
question exposed by the pre-marker content result: whether the Android
AHardwareBuffer allocation used by the 1280×960 three-buffer loop has a
Vulkan/DRM image layout compatible with Gamescope's current DMA-BUF import.

## Question

The loop reports `format=R8G8B8A8_UNORM`, `stride=1280`, and `usage=0x333`,
but those fields do not establish that the allocation is physically linear.
Gamescope currently imports the native handle as `DRM_FORMAT_ABGR8888` with
`DRM_FORMAT_MOD_INVALID` and forces `VK_IMAGE_TILING_LINEAR`. The prior run
showed visible Steam pixels in the same-run X11 source but all-zero bytes in
the Android AHardwareBuffer before the marker write.

This run will allocate an independent Android AHardwareBuffer with the exact
loop profile (`1280×960`, RGBA8, usage `0x333`, no composer-overlay usage),
import it through Android Vulkan, query its DRM modifier and image properties,
perform a Vulkan clear, and verify the result through the Android CPU lock.
That isolates allocator/layout facts from Gamescope's write path without
changing Steam, X11 timing, SurfaceControl geometry, or input behavior.

## Fixed run contract

```text
profile=ahb-import-layout-probe-1280x960
format=AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM
width=1280
height=960
usage=AHARDWAREBUFFER_USAGE_CPU_READ_OFTEN|CPU_WRITE_OFTEN|GPU_SAMPLED_IMAGE|GPU_FRAMEBUFFER
usage_hex=0x333
composer_overlay=disabled
```

The run must use a fresh APK identity and fresh log baseline on the attached
Nova device. It must run the exact-scope Nova cleanup helper before launch and
after capture, and retain the APK hash, device serial, Android Vulkan report,
logcat, and post-stop verifier output. No Gamescope import flag or Steam input
gate changes are part of this experiment.

## Decision rule

- If the same-profile Android Vulkan import and CPU readback pass, record the
  reported DRM modifier and image layout as the authoritative allocator
  evidence. The next experiment may change only Gamescope's external-image
  modifier/layout selection to that value.
- If the import or clear fails, keep Gamescope unchanged and document the
  Android-side limitation before investigating a different buffer usage or
  allocation path.
- A passing Vulkan clear is not itself Steam presentation success; it only
  identifies a valid Android-side layout and keeps the end-user gates closed
  until the Gamescope pre-marker probe becomes nonzero and frame-variable.

## Acceptance artifacts

The result document will include the exact run ID, APK and source provenance,
the complete bounded Android Vulkan report, the modifier/layout fields, hashes
of retained artifacts, and the cleanup verifier result.

