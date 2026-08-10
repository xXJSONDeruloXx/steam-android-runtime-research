# Nova Geometry Wars WineD3D/KGSL experiment — 2026-08-10

## Question

The missing Vulkan surface/swapchain extensions explain why the current
DXVK/Turnip/X11 route stops before a game frame, but they do not eliminate
OpenGL-based game presentation. Valve’s Proton runtime configuration explicitly
supports `PROTON_USE_WINED3D=1` as the OpenGL WineD3D alternative to Vulkan
DXVK. The earlier Geometry Wars direct runs reached WineD3D, but they also
forced `swrast`/`softpipe`, so they did not test the Nova Mesa KGSL OpenGL
driver.

This experiment tests that missing combination: keep the Steam client on the
known-good software-GL profile that gives a stable Termux:X11 desktop, then
launch Geometry Wars through Proton 11 ARM64 with WineD3D and Mesa’s
`kgsl_dri.so` path. The game process will not receive the explicit Freedreno
Vulkan ICD, because this arm is intentionally an OpenGL test.

## Run identity and fixed profile

- Run ID: `nova-game-geometry-wined3d-kgsl-20260810T`
- Device: Retroid Pocket Nova, adb serial `675a2365`
- Android: 13, product `kalama`
- Branch: `feat/nova-one-click-launcher`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Executable:
  `/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe`
- Compatibility tool: Proton 11.0 (ARM64),
  `compatibilitytools.d/proton-11-arm64`
- APK source commit: `92de348`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256:
  `9cf6aa48a53aca8baef8fb60d85056926550a330e780365e79f651ab1ff17f42`
- Presentation: direct Termux:X11 Android SurfaceView, Android `1280x960`,
  stretched X11 buffer `1280x800`
- Gamescope/AHardwareBuffer output: not used
- Steam client: hardware-backed Android display, software GL
  (`swrast`/`softpipe`) for stability
- Game renderer: `PROTON_USE_WINED3D=1`, Mesa `MESA_LOADER_DRIVER_OVERRIDE=kgsl`
- Game Vulkan ICD: unset
- Game logging: `PROTON_LOG=1`, run-scoped `PROTON_LOG_DIR`, `WINEDEBUG=-all`
- Timeout: 30 seconds
- Input/audio/networking: not tested

The final timestamp and evidence directory must be assigned immediately before
launch and recorded in the result. The placeholder in this predeclaration is
intentional so a stale run identity cannot be mistaken for a fresh one.

## Controlled variables

The Steam/X11 prerequisite remains the child-split software-GL profile:

```text
hardware_accel=1
cef_disable_gpu=0
steam_force_software_gl=1
steam_cef_env_split=1
```

Only the direct Geometry Wars environment changes from the earlier WineD3D
comparison:

```text
PROTON_USE_WINED3D=1
MESA_LOADER_DRIVER_OVERRIDE=kgsl
GALLIUM_DRIVER=unset
LIBGL_ALWAYS_SOFTWARE=unset
LIBGL_ALWAYS_INDIRECT=unset
VK_ICD_FILENAMES=unset
```

The Proton 11 ARM64 wrapper and AppID-8400 compatdata remain the installed
ones. The existing prefix registry and FEX configuration will be hashed before
launch and restored after the bounded run if Proton changes them. No game
files, Proton package, account state, or persistent launch options will be
removed or rewritten.

## Procedure and acceptance

1. Read [34](34-nova-runtime-harness-lifecycle.md), run the exact pre-launch
   X11/runtime cleanup, and verify a fresh process, mount, socket, and launcher
   state baseline.
2. Start the APK with the fixed software Steam profile and record fresh
   readiness, APK provenance, server log, and X11 tree evidence.
3. Invoke the quoted Geometry Wars executable through the private X11/chroot
   namespace and Proton 11 ARM64 `runinprefix` command.
4. Capture the exact command, status, process polls, Proton/Wine/FEX log,
   X11 tree/window, and repeated same-run Android/X11 frames.
5. Stop the verified game and Steam trees, restore any changed prefix metadata,
   remove only exact run-scoped logs/sockets, and verify no Nova/Steam/Wine/FEX,
   D-Bus, mount, or launcher residual remains.

A game pass requires a fresh Geometry Wars process and a same-run viewable
Geometry Wars window or frame that is not the Steam UI. A `wined3d`/`kgsl`
renderer log without a changed frame is only a renderer/startup boundary. A
FEX exception, WineD3D initialization failure, or unchanged Steam capture will
be documented at that first failed layer. No conclusion about DXVK, Vulkan
WSI, controller input, audio, networking, or the 4:3 game aspect ratio is
allowed from this run.

This predeclaration is committed and pushed before changing the direct game
environment or launching the device session.

References:

- [Valve Proton 11 runtime configuration](https://github.com/ValveSoftware/Proton/blob/proton_11.0/README.md)
- [Valve Proton 11 renderer selection](https://github.com/ValveSoftware/Proton/blob/proton_11.0/proton)
- [FEX configuration overview](https://wiki.fex-emu.com/index.php/Development%3AConfiguring_FEX)

