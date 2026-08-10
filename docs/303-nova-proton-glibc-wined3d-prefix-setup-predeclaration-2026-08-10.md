# Nova glibc Proton WineD3D prefix-setup control — 2026-08-10

## Question

Run Geometry Wars through the Holo glibc Proton 11 ARM64 compatibility tool
with Proton's normal `run` action and a fresh run-scoped copy of the AppID 8400
compatdata. The prior WineD3D control used `runinprefix`; Proton's source
shows that `runinprefix` calls `init_session(False)` and therefore skips
`setup_prefix()`, which is responsible for the prefix DLL selection and
overrides. This control changes that one setup boundary and keeps Vulkan out
of the game process.

The controlled renderer is Proton's supported
`PROTON_USE_WINED3D=1` OpenGL path, with software Mesa variables recorded and
verified. It does not modify the WSI layer, Gamescope, AHardwareBuffer, or the
persistent signed-in prefix.

## Run identity and fixed artifacts

- Run ID:
  `nova-glibc-proton-wined3d-prefix-setup-20260810T141007Z`
- Device: Retroid Pocket Nova, adb serial `675a2365`, Android 13, `kalama`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Game executable:
  `/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe`
- Game executable SHA-256:
  `457340226810ea529310f17875d87201cc93635e5a375ea4b5fdb75361887129`
- Compatibility tool:
  `/opt/nova-steam/home/.local/share/Steam/compatibilitytools.d/proton-11-arm64`
- Proton display name: Proton 11.0 (ARM64)
- Proton prefix version observed in the installed script: `11.0-100`
- Holo Steam client runtime: `steamrtarm64` with the installed SteamRT3C
  ARM64 platform tree
- Installed runtime alternatives retained for a later pairing control:
  `SteamLinuxRuntime_4` and `SteamLinuxRuntime_4-arm64`
- Parent display: fresh Termux:X11 `:0`, Android `1280x960`, stretched X11
  `1280x800`
- Parent profile: one-click LauncherActivity, hardware acceleration enabled,
  CEF GPU disabled, software GL forced for the Steam client, gamepad UI
- WSI layer: not loaded by the game process
- Vulkan ICD: unset in the game process

The durable wrapper is
[`android/nova-lab/device/nova-proton-glibc-geometry-wars.sh`](../android/nova-lab/device/nova-proton-glibc-geometry-wars.sh).

## Controlled procedure

1. Read the Nova lifecycle contract in
   [`docs/34-nova-runtime-harness-lifecycle.md`](34-nova-runtime-harness-lifecycle.md).
   Stop any prior Nova session and verify a fresh process, socket, mount, and
   launcher-state baseline.
2. Start a fresh one-click Steam/X11 session with the fixed parent profile and
   capture fresh readiness, launcher, display, and D-Bus evidence.
3. Copy the persistent `steamapps/compatdata/8400` directory into
   `/data/local/tmp/nova-holo-rootfs/tmp/<run-id>/compatdata/8400`, make the
   copy owned by uid 501/gid 20, and never use the persistent prefix as the
   write target.
4. Launch the wrapper through the existing private X11/chroot namespace as
   uid 501. It invokes:

   ```text
   proton run GeometryWars.exe
   ```

   with `PROTON_USE_WINED3D=1`, `PROTON_LOG=1`, a run-scoped
   `PROTON_LOG_DIR`, `DXVK_LOG_LEVEL=info`, software Mesa variables
   `swrast/softpipe/LIBGL_ALWAYS_SOFTWARE=1`, and no Vulkan ICD or WSI-layer
   variables.
5. Capture the exact command, exit status, Proton log header, effective
   `WINEDLLOVERRIDES`, prefix `config_info`, Wined3D/OpenGL module sequence,
   fresh DXVK-log directory, process polls, and same-run screenshots.
6. Remove only the exact run-scoped copy/logs, stop the parent with the exact
   launcher path, and verify no matching process, socket, mount, or temporary
   staging remains.

## Acceptance and classification

This is a fair WineD3D control only if the fresh Proton log proves
`setup_prefix()` ran for the run-scoped `STEAM_COMPAT_DATA_PATH`, and the
effective prefix state shows Wined3D/OpenGL selection rather than stale native
DXVK overrides. A game frame is the rendering pass. Otherwise classify the
first failure as one of:

- Proton prefix setup;
- FEX/32-bit Wine startup;
- Wined3D/software-GL initialization; or
- game startup after Wined3D initialization.

An empty DXVK log directory is expected for this control and is evidence that
DXVK was bypassed, not a DXVK failure. The next Vulkan control will separately
use Proton's normal `run` setup with explicit native DXVK overrides and fresh
logs, then revisit the Win32-surface-to-X11 contract if the native path reaches
`winevulkan.dll` again.

This declaration is committed and pushed before the device run.
