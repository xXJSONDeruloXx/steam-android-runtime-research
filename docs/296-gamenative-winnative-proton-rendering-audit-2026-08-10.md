# GameNative/WinNative rendering-path audit and Proton control — 2026-08-10

## Why this matters

The GameNative and WinNative source trees do not solve the Nova failure with a
Gamescope-to-AHardwareBuffer patch. Their Android application owns the final
Vulkan presentation path, while the Windows guest still reaches that
application through an ordinary X11 server and Wine's normal Xlib Vulkan WSI.
That separates two problems which have been entangled in the Nova runs:

1. getting Wine/DXVK to create a usable host Vulkan device and swapchain; and
2. presenting the resulting guest image through an Android `Surface`.

GameNative's `VulkanRendererContext` creates `VK_KHR_android_surface` and an
Android swapchain from an `ANativeWindow`. Its Java `XServerComponent` instead
serves X11 clients over `/tmp/.X11-unix/X0`. The guest launcher sets
`DISPLAY=:0`, `ANDROID_SYSVSHM_SERVER`, `WINE_X11FORCEGLX=1`, and the Android
library/preload paths. WinNative follows the same family of design: a Java/C
X server plus a native renderer that creates an Android surface and imports
guest window buffers.

The important negative result is that the GameNative Proton Wine source does
not contain a special swapchain implementation. `winex11.drv` advertises
`VK_KHR_xlib_surface` and calls `vkCreateXlibSurfaceKHR`; `winevulkan` maps
the application's `VK_KHR_win32_surface` request to that host extension.
Therefore, swapping in GameNative's ARM64EC Wine is a meaningful controlled
test, but it is not expected to bypass a host/device-side
`VK_KHR_swapchain` enumeration failure by itself.

## Sources inspected

- GameNative source revision `4c3269c63851849fbe16e462733494755ce47524`:
  [repository](https://github.com/utkarshdalal/GameNative)
- WinNative source revision `89daef3bc5693762868b2254054b47f4cdf27edf`:
  [repository](https://github.com/WinNative-Emu/WinNative)
- GameNative Proton Wine source revision
  `147d88ee0c4eee8b356110dd0c53cc44b7515f73`:
  [repository](https://github.com/GameNative/proton-wine)
- GameNative's current content manifest:
  [manifest.json](https://github.com/utkarshdalal/GameNative/blob/master/manifest.json)
- GameNative's ARM64EC Proton build script:
  [build-step-arm64ec.sh](https://github.com/GameNative/proton-wine/blob/main/build-scripts/build-step-arm64ec.sh)
- GameNative's Wine WSI implementation:
  [winex11.drv/vulkan.c](https://github.com/GameNative/proton-wine/blob/main/dlls/winex11.drv/vulkan.c),
  [winevulkan/vulkan.c](https://github.com/GameNative/proton-wine/blob/main/dlls/winevulkan/vulkan.c)
- Relevant application components:
  [BionicProgramLauncherComponent.java](https://github.com/utkarshdalal/GameNative/blob/master/app/src/main/java/com/winlator/xenvironment/components/BionicProgramLauncherComponent.java),
  [VulkanRendererContext.cpp](https://github.com/utkarshdalal/GameNative/blob/master/app/src/main/cpp/winlator/VulkanRendererContext.cpp)

## Findings

### Android-side display path

GameNative's renderer enables `VK_KHR_surface` and
`VK_KHR_android_surface`, calls `vkCreateAndroidSurfaceKHR` with the Android
`ANativeWindow`, requests `VK_KHR_swapchain`, and presents its own Android
swapchain. Its X server is a protocol endpoint, not the final Vulkan display
surface. WinNative's renderer has the same shape and additionally exposes the
AHardwareBuffer/SurfaceControl scanout path used by its display compositor.

This is prior art for a later product direction: embed or adapt the Android
renderer/X-server architecture into the Nova APK. It is substantially larger
than changing the current Wine build, so it is not the next blocker-isolation
experiment.

### Wine/Proton-side path

GameNative's ARM64EC build is configured for AArch64 Android with Wine's
OpenGL, Vulkan, X11 shared memory, and no Wayland/XRandR/XRender extras. It
also carries Android/ARM64EC patches for address-space, syscall, networking,
X11, and shared-memory behavior. The launcher runs the ARM64EC Wine executable
directly and selects `HODLL=libwow64fex.dll` for FEXCore or `wowbox64.dll` for
the Box64 path.

The current Nova test uses a Steam-installed Proton 11 ARM64 compatibility
tool. That is not byte-identical to GameNative's Wine component. The latter is
distributed as a GameNative WCP and is therefore the next useful control.

### Driver packages

GameNative's manifest currently offers Proton 11.0-1 ARM64EC, FEXCore
2601-217d039, DXVK 2.7.1, and a `Turnip v26.1.0 A12 Fix` package. The Turnip
package is an Android/Bionic driver artifact; the current Nova rootfs uses a
glibc-built `/opt/nova-kgsl-driver/libvulkan_freedreno.so`. It must not be
dropped into the current rootfs without a loader/ABI probe, and this run will
not replace the known driver.

GameNative's `libkgslshim.so` is separately called out as proprietary/source
withheld in its third-party notices. It is not copied, redistributed, or used
in this research run.

## Predeclared experiment

Run ID prefix: `nova-game-gamenative-proton-arm64ec`

The run will use a fresh UTC run ID and the existing exact-scope lifecycle
from `docs/34-nova-runtime-harness-lifecycle.md`.

Fixed controls:

- Retroid Pocket Nova, adb serial `675a2365`, Android 13/product `kalama`.
- Rootfs `/data/local/tmp/nova-holo-rootfs`.
- Geometry Wars: Retro Evolved, AppID `8400`, unchanged executable.
- Existing Termux:X11 `:0`, Android `1280x960`, X11 `1280x800` session.
- Existing Nova Mesa/Turnip ICD and the already-tested xMeM WSI layer.
- Existing Steam prefix, with exact `system.reg`, `user.reg`, `userdef.reg`,
  and FEX configuration backups restored after the run.
- No Gamescope patch, driver swap, Proton prefix migration, or APK change.

One variable changed:

- Replace only the direct Wine binaries/modules for this run with
  GameNative's `proton-11.0-1-arm64ec.wcp`, staged under a run-scoped device
  temporary directory.

Expected launch environment, adapted from GameNative and constrained to the
current rootfs, is `DISPLAY=:0`, `HODLL=libwow64fex.dll`,
`WINE_X11FORCEGLX=1`, `ANDROID_SYSVSHM_SERVER` if present, the current
`VK_ICD_FILENAMES`, the current implicit WSI layer path, and the current
SysV-shm preload. The direct wrapper will record every effective variable and
the hashes of the staged WCP and extracted Wine files.

The tracked bounded wrapper for this control is
`android/nova-lab/device/nova-gamenative-proton-geometry-wars.sh`. It runs the
GameNative `bin/wine` directly with the existing AppID-8400 prefix and a
45-second timeout; it does not replace the installed Steam compatibility tool.

Acceptance is a fresh Geometry Wars frame in the post-launch screenshot plus
log evidence that the game reached its graphics path. A repeat of
`vkCreateDevice extension VK_KHR_swapchain not available` is still useful: it
would move the blocker below Proton/Wine and toward the current Mesa ICD,
Vulkan loader, or implicit-layer device-extension dispatch.

## Artifact provenance

Downloaded GameNative Proton WCP:

- URL: `https://downloads.gamenative.app/proton-11.0-1-arm64ec.wcp`
- Local staging: `/tmp/gamenative-proton.IeHGto/proton-11.0-1-arm64ec.wcp`
- Size: `276851384` bytes
- SHA-256: `be248bf8baf354c4426f997605c6b78debbc93b091a3be3339c1bbc2176b596f`
- HTTP ETag: `"62d9a7fd6e1a0b8f7053500c9a8c798e"`
- Profile: Proton `11.0-1-arm64ec`, `binPath=bin`, `libPath=lib`,
  `prefixPack=prefixPack.txz`.

The WCP is an external experiment artifact and will remain outside the main
repository. Only this predeclaration and the resulting evidence document are
tracked here.

## Decision

Proceed with the ARM64EC Wine control first. If it reaches the same
driver-specific swapchain boundary, stop changing Proton and investigate the
actual runtime enumeration/dispatch of `VK_KHR_swapchain` in the current
Mesa/loader/layer stack. Keep the GameNative/WinNative Android renderer as a
separate, larger route for later work rather than mixing it into this control.
