# Nova Geometry Wars Proton 11 DXVK run — 2026-08-10

## Question

The explicit Freedreno Vulkan probe succeeds on Turnip Adreno 740, but
Geometry Wars has consistently loaded WineD3D/OpenGL instead of exercising
Vulkan. The installed Proton 11 ARM64 package contains ARM64 PE32 DXVK
libraries and its `proton` wrapper recognizes `PROTON_USE_WINED3D`.

This bounded comparison asks whether forcing `PROTON_USE_WINED3D=0` makes the
same 32-bit Geometry Wars executable use DXVK/Vulkan and reach a frame. It
keeps the working explicit Freedreno ICD and one-click software-GL Steam
display, changing only the Proton renderer selection plus bounded logging.

## Run identity and fixed profile

- Run ID: `nova-game-geometry-dxvk-20260810T080307Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Executable:
  `/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe`
- Compatibility tool: Proton 11.0 (ARM64),
  `compatibilitytools.d/proton-11-arm64`
- APK SHA-256:
  `3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a`
- Presentation: hardware-backed Termux:X11 Android SurfaceView, 1280×960
- Steam client: software GL (`swrast`, `softpipe`,
  `LIBGL_ALWAYS_SOFTWARE=1`)
- Vulkan ICD:
  `VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`
- Renderer switch: `PROTON_USE_WINED3D=0`
- Bounded logging: `PROTON_LOG=1`, `WINEDEBUG=-all`,
  `DXVK_LOG_LEVEL=info`

Run directory:
`android/nova-lab/build/runs/nova-game-geometry-dxvk-20260810T080307Z`

## Procedure and acceptance

Read the Nova lifecycle contract immediately before launch. Force-stop the
APK and Termux:X11, run the exact cleanup helpers, verify a fresh process,
mount, socket, and launcher-state baseline, and start a fresh one-click
session. Snapshot the AppID-8400 registry files, `proton-fex-config.json`,
and the ten existing `system32`/`syswow64` `d3d*.dll`/`dxgi.dll` files before
the direct run.

Create a run-scoped Proton log directory inside the chroot and chown it to
the Steam uid; this avoids the earlier root-owned log-directory failure. Run
the quoted Geometry Wars path through `proton runinprefix` with
`PROTON_USE_WINED3D=0`, retaining the exact command, Proton/DXVK log, status,
process poll, and repeated screenshots.

Success requires fresh evidence that DXVK/Vulkan is loaded and a real
Geometry Wars frame. A renderer switch or game process without a changed
frame is a startup-boundary result only. After capture, stop the direct and
one-click trees, restore the registry, compatdata config, and ten prefix DLLs
byte-for-byte, remove exact run-scoped logs and stale sockets, and verify a
clean process/mount/socket state.

This declaration is committed and pushed before changing the Proton renderer
environment or launching the game.
