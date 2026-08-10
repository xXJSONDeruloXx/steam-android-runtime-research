# Nova Android WSI layer DMA-BUF/X11 result — 2026-08-10

## Result

The DMA-BUF adaptation crossed the native Vulkan bridge boundary, but it did
not yet produce a Geometry Wars frame. The implicit ARM64 layer loaded in the
real Proton 11 ARM64 process, `vkCreateDevice` completed, and DXVK found the
Turnip Adreno 740 without the earlier explicit-layer `khrSwapchain` adapter
rejection. The game process nevertheless exited with status `5` before a
visible surface or swapchain frame appeared.

This is meaningful progress, not a universal Proton/game failure. The next
likely seam is Windows WSI: the layer's manifest supplies XCB/Xlib surfaces,
while WineVulkan/DXVK requests `VK_KHR_win32_surface`. That mismatch is the
strongest next hypothesis from this run, but the log does not yet prove
whether the failure is Win32-surface translation, the loader's ICD-side
swapchain negotiation, or a later DRI3 import error.

## Source and controlled change

- Prior art: `xMeM/vulkan-wsi-layer`, revision
  `d5624d42d8b2debbd910ad25662a05c751eb38b7`
- External build checkout:
  `/Users/kurt/Developer/vulkan-wsi-layer`
- Build mode: `NOVA_X11_USE_DMA_BUF=ON`, ARM64 glibc/X11
- Layer artifact:
  `android/nova-lab/build/vulkan-wsi-layer-build-dmabuf1/libVkLayer_window_system_integration.so`
- Layer SHA-256:
  `895a6dc9dc63e5778c0171fc56cdcb7e565a0f99c137c137073cb5ce8693b24a`
- Manifest SHA-256:
  `31758fb210e73e1ecd7460c9ec413e8eab6a7281b0ba847cd351af79f17f742a`
- The DMA-BUF mode retains the X11 synchronization/memory extension set,
  omits only the unavailable Android AHardwareBuffer Vulkan extension, uses
  `vkGetMemoryFdKHR`, and passes a linear modifier (`0`) to DRI3.
- The layer remains build/run-scoped prior art; it was not copied into the
  product APK.

## Run identity and provenance

- Run ID: `nova-android-wsi-layer-dmabuf-x11-20260810T115421Z`
- Device: Retroid Pocket Nova, adb serial `675a2365`, Android 13, `kalama`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Compatibility tool: Proton `proton-11.0-1-beta5-unstripped` / Proton 11
  ARM64
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256:
  `7f94e8bc85717147c2c62b4438fae26a826d1132cbbec4e103c9ddad79b84229`
- Source commit represented by the APK: `e5fd23f`
- Display: Termux:X11 `:0`, Android `1280x960`, stretched X11 `1280x800`
- ICD: `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`
- Turnip SHA-256:
  `a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810`
- FROG layer SHA-256:
  `6797355511b1d62d7d324b9f49e0119a48d2b5647489a4f55784cde37f03eb5a`
- GeometryWars.exe SHA-256:
  `457340226810ea529310f17875d87201cc93635e5a375ea4b5fdb75361887129`
- Proton wrapper SHA-256:
  `b56de46d7619ebf6975a625e47c202c81baa375ca3576983e221bc9892b0633b`

The parent Steam session used the known-good software/CEF profile:
`hardware_accel=0`, `cef_disable_gpu=1`, `steam_ui_mode=gamepadui`, with the
Turnip ICD retained. The fresh launcher log recorded
`nova_launcher_ready=pass display=:0 geometry=1280x960`, and Termux:X11
reported the expected hardware-backed 1280×800 buffer handoff.

## Native probe

The first invocation used unsupported `/usr/bin/vulkaninfo --full` and was
recorded as a harness correction in [doc 292](292-nova-android-wsi-layer-dmabuf-predeclaration-2026-08-10.md).
The corrected default `/usr/bin/vulkaninfo` invocation returned status `0`:

```text
INFO | LAYER:      Insert instance layer "VK_LAYER_window_system_integration"
INFO | LAYER:      Inserted device layer "VK_LAYER_window_system_integration"
VK_KHR_surface                         : extension revision 25
VK_KHR_xcb_surface                     : extension revision 1
VK_KHR_xlib_surface                    : extension revision 1
Layer-Device Extensions: count = 3
    VK_KHR_swapchain                   : extension revision 70
GPU id : 0 (Turnip Adreno (TM) 740) [VK_KHR_xcb_surface, VK_KHR_xlib_surface]
VK_EXT_external_memory_dma_buf         : extension revision 1
VK_KHR_swapchain                       : extension revision 70
```

Probe evidence:

- Output: `android/nova-lab/build/runs/nova-android-wsi-layer-dmabuf-x11-20260810T115421Z/native-probe-full-2.txt`
- Output SHA-256:
  `8d16d71891b0a72800457af66a91bce66a3a755d4fd923faea9828b6e056c545`
- Status SHA-256:
  `1d5ce67cad73ba3fed3840c689aaea087108c4c943cf62067de3512a453ee86a`
- Fresh namespace markers: `mount_private=pass` and
  `x11_namespace_input=pass allowed_events=9`.

## Game result

The first bounded launch reached Proton but was corrected before retry because
the run-scoped `PROTON_LOG_DIR` did not exist. The corrected launch used the
same game, prefix, ICD, display, and implicit layer with FROG disabled and
returned `direct_game_status=5`.

The Proton log proves the layer was active in the real game process:

```text
Game: GeometryWars.exe
DXVK: v2.7.1-467-g83e503b4ae6de84
Vulkan: Found vkGetInstanceProcAddr in winevulkan.dll
Type: Implicit
Manifest: /tmp/nova-android-wsi-layer-dmabuf-x11-20260810T115421Z/wsi-stage/VkLayer_window_system_integration.json
Enabled instance extensions:
    VK_KHR_surface
    VK_KHR_win32_surface
Found device: Turnip Adreno (TM) 740 (turnip Mesa driver 25.2.7)
```

The loader also logged that `VK_KHR_swapchain` is absent from the underlying
ICD. Unlike the earlier explicit-layer run, this corrected implicit run did
not log DXVK's `Skipping: Device does not support required feature
'khrSwapchain'` or `No adapters found`; DXVK reached device discovery. It did
not, however, produce a `vkCreateSwapchainKHR`/present trace or a game frame.
The WSI manifest advertises XCB/Xlib, not Win32, while the Wine path enabled
`VK_KHR_win32_surface`; this is the next concrete compatibility boundary to
test rather than calling the DMA-BUF transport a failure.

The same-run screen remained the Steam library with Geometry Wars selected,
not a game frame:

- Before: `screen-before.png`, SHA-256
  `0bab26b67a1da6469f275e1534224c1087c9285af13095554f988c4f2b36f385`
- After: `screen-after-game-2.png`, SHA-256
  `91f15452ced1f74fa1bdf89439492a5324ca99f2ac7d61cad7f9f3d644a754ee`
- Proton log: `proton-log-2.txt`, SHA-256
  `cc2466cff491d834fe0c27d2f55084d30752d5cbd67d08de50a78d860f48e9ae`
- Game output: `direct-game-output-2.txt`, SHA-256
  `1619903f56f05254d534cdef3a73b870320808649bc159c8b5f57bca9e223eec`

The first failed game attempt and the corrected per-run log-directory setup
are both described in doc 292. The authoritative evidence directory is:

`android/nova-lab/build/runs/nova-android-wsi-layer-dmabuf-x11-20260810T115421Z/`

## State and cleanup

The exact Wine processes left by the bounded launch were captured as
`wineserver` and two `winedevice.exe` processes, verified by command line, and
killed by exact PID. The one-click session then completed:

```text
nova_x11_cleanup=pass
nova_runtime_cleanup=pass
```

The final process audit was empty. The exact run-scoped device staging,
manifest, helper, Proton log, and rootfs `/tmp` directory were removed; the
device cleanup marker is `exact_device_cleanup=pass`.

The AppID-8400 prefix did change during the game attempt. This run recorded
the pre-launch hashes (`system.reg=1c1fe3...`, `user.reg=a57bbd...`) and the
post-launch hashes (`system.reg=5a7fba...`, `user.reg=1943c8...`), but did not
capture byte-for-byte backups before launching. Do not claim prefix restoration
for this run; the next game experiment must take exact backups and either
restore them or explicitly preserve the resulting state.

## Decision and next step

Keep the DMA-BUF WSI work as a useful bridge experiment, but do not put this
layer in the product APK yet. The immediate next experiment should isolate the
Wine-facing WSI contract: either add a narrowly scoped Win32-to-X11 surface
adapter to the layer, or run a separately predeclared WineD3D/llvmpipe control
that bypasses Vulkan entirely. The prior WineD3D/KGSL run failed at Mesa
Zink/GLX, so the latter should force and verify a software GLX driver rather
than repeat the same KGSL/Zink environment.
