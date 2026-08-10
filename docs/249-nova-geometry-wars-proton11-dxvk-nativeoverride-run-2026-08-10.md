# Nova Geometry Wars Proton 11 DXVK native-override run — 2026-08-10

## Question

The corrected `runinprefix` attempt reached Geometry Wars but loaded WineD3D.
Proton 11's wrapper shows that `runinprefix` skips `setup_prefix()`, which is
where the native DXVK DLLs and `n` overrides are normally installed. This
fresh run keeps the same one-click Steam/X11 session and Turnip ICD, but
explicitly supplies the native D3D9/D3D11/D3D10Core/DXGI overrides and
`SteamGameId=8400` while entering `runinprefix`.

The question is whether explicit native dispatch now loads DXVK/Vulkan and
gets Geometry Wars beyond the previous WineD3D startup boundary.

## Run identity and fixed profile

- Run ID: `nova-game-geometry-dxvk-nativeoverride-20260810T082211Z`
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
- Renderer selection: `PROTON_USE_WINED3D=0`
- Explicit native dispatch:
  `WINEDLLOVERRIDES=d3d11=n;d3d10core=n;d3d9=n;dxgi=n`
- Proton identity: `SteamAppId=8400`, `SteamGameId=8400`
- Bounded logging: `PROTON_LOG=1`, `WINEDEBUG=-all`,
  `DXVK_LOG_LEVEL=info`
- Command transport: one remote `su -mm 0 -c "..."` shell argument;
  the executable path and semicolon-delimited override value remain quoted

Run directory:
`android/nova-lab/build/runs/nova-game-geometry-dxvk-nativeoverride-20260810T082211Z`

## Procedure and acceptance

Read the Nova lifecycle contract immediately before launch. Force-stop the
APK and Termux:X11, run the exact cleanup helpers, verify a fresh process,
mount, socket, and launcher-state baseline, and start a fresh one-click
session. Snapshot the AppID-8400 registry files, `proton-fex-config.json`,
and the ten existing `drive_c/windows/{system32,syswow64}` D3D/DXGI files
before the direct run. Create a run-scoped Proton log directory inside the
chroot and chown it to Steam uid 501.

Run the quoted Geometry Wars path through `proton runinprefix` with the
explicit native overrides, explicit Freedreno ICD, and bounded logging.
Record the complete remote command, stdout, stderr, exit status, process
polls, screenshots, Proton/DXVK log, and artifact hashes.

Success requires fresh DXVK/Vulkan evidence and a changed Geometry Wars
frame. A native DLL load without a changed frame is a startup-boundary result
only. After capture, stop the direct and one-click trees, restore the
registry, compatdata config, and ten prefix DLLs byte-for-byte, remove exact
run-scoped logs and stale sockets, and verify a clean process/mount/socket
state.

This declaration is committed and pushed before changing DLL dispatch or
launching the native-override invocation.
