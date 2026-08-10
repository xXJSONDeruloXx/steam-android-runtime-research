# Nova Android WSI layer DMA-BUF/X11 predeclaration — 2026-08-10

Status: predeclared; no DMA-BUF variant has been built or installed on the
Nova under this identity.

## Question

The upstream X11 WSI layer can be loaded in the Nova glibc rootfs and reports
the missing surface/swapchain extensions, but its standard X11 backend requires
`VK_ANDROID_external_memory_android_hardware_buffer`. The exact Turnip ICD
does not advertise that Android Vulkan extension, although it does advertise
`VK_EXT_external_memory_dma_buf`, `VK_KHR_external_memory`, and
`VK_KHR_external_memory_fd`.

This experiment tests the narrow implementation consequence: can the same
X11 DRI3/Present backend allocate linear Vulkan images, export their memory as
DMA-BUF fds, and present them to Termux:X11 without Android Vulkan
AHardwareBuffer import? It is a rendering bridge experiment; input, audio,
networking, aspect ratio, and Steam UI behavior remain out of scope.

## Provenance and fixed profile

- Device: Retroid Pocket Nova, adb serial `675a2365`, Android 13, `kalama`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Compatibility tool: Proton 11 ARM64
- Display: Termux:X11 `:0`, Android `1280x960`, stretched X11 `1280x800`
- ICD: `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`
- Upstream source: `xMeM/vulkan-wsi-layer`, revision
  `d5624d42d8b2debbd910ad25662a05c751eb38b7`
- Prior source checkout:
  `/Users/kurt/Developer/vulkan-wsi-layer`
- Parent experiment: [doc 291](291-nova-android-wsi-layer-x11-experiment-2026-08-10.md)

The adaptation is build/run-scoped prior art and will not be copied into the
product APK unless a same-run game frame is observed. The existing Turnip
ICD, FROG layer, Steam prefix, game files, and one-click APK remain unchanged.

## Controlled change

1. Add a build-only DMA-BUF mode to the external X11 backend.
2. Replace the unavailable AHardwareBuffer export/Unix-socket handoff with
   `vkGetMemoryFdKHR` using `VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT`.
3. Pass the exported fd through `xcb_dri3_pixmap_from_buffers` and retain the
   existing Present event and Vulkan synchronization code.
4. Build an ARM64 glibc layer with a unique artifact hash.
5. Run a fresh native probe through `VK_IMPLICIT_LAYER_PATH`, with FROG
   disabled, and require successful device creation plus the X11/swapchain
   extension inventory.
6. Only after that probe passes, run Geometry Wars once with the same layer and
   capture the Android screen and DXVK log.

The first success threshold is a live Vulkan swapchain creation. The rendering
acceptance threshold remains a same-run Geometry Wars frame visibly replacing
the Steam UI. A native bridge pass without a game frame is not a product pass.

## Lifecycle and evidence contract

Read [the Nova lifecycle contract](34-nova-runtime-harness-lifecycle.md)
immediately before the device run. Use a fresh run identity, exact preflight
cleanup, fresh one-click APK/session provenance, complete layer/ICD/Proton
hashes, native probe output, game output, screenshots, and exact teardown.
Commit and push the result before any further rendering variant.

## Harness correction before execution

The first probe invocation used `/usr/bin/vulkaninfo --full`, copied from a
desktop-oriented command shape. The Nova rootfs build does not implement that
option: it returned status `1` with the program's usage text immediately after
`mount_private=pass` and `x11_namespace_input=pass`. No Vulkan instance or
device was created, and no game or prefix state changed. The same run will
retry with the supported default text invocation (`/usr/bin/vulkaninfo`).
