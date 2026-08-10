# Nova Android-aware Vulkan WSI/X11 layer experiment — 2026-08-10

Status: predeclared; no WSI layer has been built, staged, or enabled on the
Nova under this run identity.

## Question

The current Geometry Wars DXVK/FROG route reaches Turnip but stops because the
ICD exposes no `VK_KHR_surface`, X11 surface, Android surface, or
`VK_KHR_swapchain`. This is a presentation seam, not a proof that Proton 11
ARM64 cannot render a game.

The upstream `xMeM/vulkan-wsi-layer` project is a concrete alternative: its
X11 backend implements `VK_KHR_xcb_surface`/`VK_KHR_xlib_surface` and a
`VK_KHR_swapchain` layer using DRI3/Present and Android AHardwareBuffer
handles. That is materially different from FROG, which wraps an existing
swapchain and therefore cannot create one when the ICD does not provide it.

This experiment asks whether the WSI layer can be built for the Nova glibc
rootfs, loaded below the existing Gamescope/FROG path, and make a native
Vulkan extension probe plus one Geometry Wars launch progress beyond the
current missing-swapchain boundary.

## Prior art and source provenance

- Project: [xMeM/vulkan-wsi-layer](https://github.com/xMeM/vulkan-wsi-layer)
- Source revision: `d5624d42d8b2debbd910ad25662a05c751eb38b7`
- Relevant upstream implementation: `wsi/x11/swapchain.cpp` creates linear
  Android-backed images and exports them to X11 through DRI3/Present.
- Khronos WSI contract:
  [Vulkan WSI documentation](https://github.khronos.org/Vulkan-Site/spec/latest/chapters/VK_KHR_surface/wsi.html)
- Android/X11 integration context:
  [Termux package discussion #22292](https://github.com/termux/termux-packages/issues/22292)

The checkout is an external, read-only prior-art workspace at
`/Users/kurt/Developer/vulkan-wsi-layer`; no upstream source is copied into
the product APK by this predeclaration.

## Fixed profile

- Device: Retroid Pocket Nova, adb serial `675a2365`
- Android: 13, product `kalama`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Compatibility tool: installed Proton 11 ARM64
- Presentation: Termux:X11 display `:0`, Android `1280x960`, stretched X11
  `1280x800`
- Existing Gamescope/FROG binaries and the Turnip ICD remain unchanged
- Steam parent: signed-in direct X11 session using the known-good software
  Steam/CEF profile
- Input, audio, networking, and aspect-ratio acceptance: not in scope

## Controlled change

Build one ARM64 glibc `VK_LAYER_window_system_integration` library from the
declared upstream revision with its X11 backend enabled. Stage only its library
and manifest under a unique run directory. The native probe and game process
will receive the layer through an explicit `VK_LAYER_PATH` and
`VK_INSTANCE_LAYERS` setting. No existing ICD, FROG library, Steam prefix,
game files, or persistent Steam launch option may be modified.

The probe must first record whether the layer adds the expected instance/device
surface and swapchain extensions under the exact Nova namespace. Only then may
the Geometry Wars launch proceed. If the layer cannot build, load, or satisfy
the Turnip external-memory contract, that build/load boundary is the result;
another game is not a useful substitute.

## Acceptance and cleanup

A rendering pass requires all of the following from the same fresh run:

1. the WSI layer library and manifest have recorded source/build/hash
   provenance;
2. the native probe reports a usable X11 surface path and
   `VK_KHR_swapchain` after the layer is enabled;
3. the real Geometry Wars process reaches a Vulkan/DXVK swapchain and a
   same-run Android or X11 capture contains a Geometry Wars frame, not the
   unchanged Steam UI;
4. the exact Nova cleanup helpers return pass and no matching process, mount,
   socket, layer staging directory, or launcher state remains.

An extension-list change without a frame is a bridge pass only. A game process
without a frame is a startup result. A clean teardown without the stop and
rendering gates is not a product success.

Read [the Nova lifecycle contract](../00-start-here/34-nova-runtime-harness-lifecycle.md)
immediately before the device run. Assign a fresh timestamped run ID, capture
APK/ICD/Gamescope/WSI hashes, preserve prefix metadata, and commit the result
before starting another rendering experiment.

## First device probe and explicit-layer boundary

The ARM64 glibc build completed from the declared source revision. The build
used the Nova rootfs library set for Vulkan/XCB/X11 and a build-only opaque
`AHardwareBuffer` declaration because the NDK header carries Bionic-only
annotations that GCC cannot parse in this glibc environment. The resulting
library is a native AArch64 ELF and its manifest advertises the expected X11
surface and swapchain entry points.

Run `nova-android-wsi-layer-x11-20260810T114402Z` loaded that library with
`VK_LAYER_PATH` and `VK_INSTANCE_LAYERS`. The loader found and inserted the
layer, and the native `vulkaninfo` layer-specific inventory reported
`VK_KHR_xcb_surface`, `VK_KHR_xlib_surface`, `VK_KHR_surface`, and device-side
`VK_KHR_swapchain` above Turnip. This is a bridge-level pass; the ICD itself
still reports no swapchain.

The first Geometry Wars launch then reached Proton 11 ARM64, DXVK, and the
Turnip Adreno 740, but DXVK still reported:

    Skipping: Device does not support required feature 'khrSwapchain'

The explicit layer's per-layer extension inventory was therefore not enough
for this WineVulkan/DXVK path. This is not a game failure or evidence against
the WSI implementation: the upstream installation instructions place the
layer in Vulkan's implicit-layer directory, and the source comments account
for loader aggregation of implicit-layer extensions. The next controlled
variant keeps the same build, game, ICD, and display but exposes the staged
manifest through `VK_IMPLICIT_LAYER_PATH`, with FROG disabled, before repeating
one native inventory and one bounded Geometry Wars launch.

The implicit-loader variant in the same session loaded the layer but failed at
`vkCreateDevice` inside `add_device_extensions_required_by_layer`. The X11
backend requires `VK_ANDROID_external_memory_android_hardware_buffer`; the
fresh Turnip device inventory contains `VK_EXT_external_memory_dma_buf` and
the KHR external-memory-fd extensions, but does not contain the Android
AHardwareBuffer Vulkan extension. No second game launch was accepted from this
variant. The explicit-layer game result and this implicit-layer load boundary
are retained as separate evidence rather than being collapsed into a generic
"WSI failed" result.

The next implementation branch is therefore the same upstream X11 WSI layer
adapted to export the linear Vulkan image memory through the device's supported
DMA-BUF external-memory path and pass that fd to X11 DRI3/Present. It keeps the
same public swapchain and surface contract while removing the unavailable
Android Vulkan import requirement. That adaptation is predeclared separately
in [doc 292](292-nova-android-wsi-layer-dmabuf-predeclaration-2026-08-10.md).
