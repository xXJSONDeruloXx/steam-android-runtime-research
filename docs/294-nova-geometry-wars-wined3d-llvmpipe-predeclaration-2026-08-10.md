# Nova Geometry Wars WineD3D/llvmpipe predeclaration — 2026-08-10

Status: predeclared; no device run has started under this identity.

## Question

The DMA-BUF WSI layer reached Turnip and removed the earlier DXVK adapter
rejection, but its X11-only surface contract does not match the
`VK_KHR_win32_surface` request made by WineVulkan. This experiment bypasses
Vulkan entirely for the game: Proton 11 ARM64 will use WineD3D/OpenGL, and
Mesa will be forced to the software `llvmpipe` driver. The result separates a
usable Wine/X11 game window from the Vulkan/WSI problem.

This is supported Proton behavior: `PROTON_USE_WINED3D=1` selects the OpenGL
WineD3D renderer instead of DXVK. It is also consistent with the Android
container prior art in [Winlator](https://github.com/Honkonx/winlator) and
[GameNative](https://github.com/utkarshdalal/GameNative), which use per-game
runtime configuration rather than assuming one global renderer works for all
titles.

## Fixed profile

- Device: Retroid Pocket Nova, adb serial `675a2365`, Android 13, `kalama`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Compatibility tool: Proton 11 ARM64
- Display: Termux:X11 `:0`, Android `1280x960`, stretched X11 `1280x800`
- ICD: unset for the direct game process; no Vulkan layer or FROG activation
- Parent Steam session: fresh one-click session with software Steam/CEF
  isolation, using the previously validated signed-in profile

## Controlled change

The direct game process will add only these renderer variables:

```text
PROTON_USE_WINED3D=1
MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
GALLIUM_DRIVER=llvmpipe
LIBGL_ALWAYS_SOFTWARE=1
```

`VK_ICD_FILENAMES`, `VK_IMPLICIT_LAYER_PATH`, and FROG activation will be
absent. The run will pre-create a Steam-uid-owned log directory, take exact
byte-for-byte backups of the AppID-8400 registry/FEX files, launch Geometry
Wars once with a host-side timeout, capture Proton/Wine logs and fresh
screenshots, then restore the backups before teardown.

## Acceptance

The result is a pass only if a same-run capture contains the Geometry Wars
window/frame rather than the unchanged Steam UI. A real WineD3D process with
Mesa errors is a GLX boundary result; it is not a display pass. Every setup
failure, prefix mutation, process cleanup, and restoration comparison will be
recorded before the next experiment.

Read [the Nova lifecycle contract](34-nova-runtime-harness-lifecycle.md)
immediately before the device run. Commit and push this predeclaration before
launching it.

## Harness correction before game launch

The root-created device staging directory initially had mode `0755` and was
not writable by the adb shell user, so the first `adb push` of the direct
wrapper returned `Permission denied`. The exact prefix backups had already
completed, and no game, Wine, or prefix state changed. The run will retry the
push after changing only this run directory's mode to `0777`.
