# Nova Geometry Wars Proton 11 explicit Freedreno run — 2026-08-10

## Question

The fresh Steam-mediated Proton 11 runs for Geometry Wars and Peggle both
selected `proton11_arm64` but exited at the shared 32-bit FEX/Wine startup
boundary. Earlier direct runs reached Vulkan enumeration failure
(`res -3`) and fell back to llvmpipe, but deliberately did not pass the
launcher’s explicit Freedreno Vulkan ICD.

This bounded comparison asks whether that ICD changes Vulkan enumeration or
the Geometry Wars startup boundary. It retains the known-good hardware-backed
Termux:X11/software-GL Steam display and changes only the direct Proton
environment’s Vulkan ICD, while enabling a run-scoped Proton log as
observability.

## Run identity and fixed profile

- Run ID: `nova-game-geometry-freedreno-20260810T074337Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Executable:
  `/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe`
- Compatibility tool: `proton11_arm64`, wrapper
  `/opt/nova-steam/home/.local/share/Steam/compatibilitytools.d/proton-11-arm64`
- APK:
  `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a`
- Presentation: hardware-backed Termux:X11 Android SurfaceView, 1280×960
- Steam UI: software GL (`swrast`, `softpipe`,
  `LIBGL_ALWAYS_SOFTWARE=1`)
- Added Vulkan variable:
  `VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`

Run directory:
`android/nova-lab/build/runs/nova-game-geometry-freedreno-20260810T074337Z`

## Procedure and acceptance

Before launch, read the Nova lifecycle contract, force-stop the APK and
Termux:X11, run the exact X11/rootfs cleanup helpers, verify no matching
process, mount, socket, or launcher state, and start a fresh one-click
session. Snapshot the AppID-8400 prefix registry files before the direct
launch.

Invoke the installed Proton 11 wrapper with `runinprefix` and the existing
AppID-8400 compatdata. Set `PROTON_LOG=1` and a run-scoped
`PROTON_LOG_DIR` for evidence, retain the exact command and status, poll the
process tree, and capture repeated same-run screenshots. The only behavioral
change from the earlier direct comparison is the explicit Freedreno Vulkan
ICD; software GL variables remain in place so Vulkan and OpenGL attribution
stay separate.

Success requires both a changed Vulkan-enumeration result in the fresh Proton
log and a real Geometry Wars frame. A changed log without a frame is a
startup-boundary result only. After capture, stop the verified direct tree,
restore the three prefix registry files byte-for-byte, remove only exact
run-scoped logs and stale sockets, and verify clean process/mount/socket state.

This declaration is committed and pushed before changing the device
environment or launching the diagnostic run.
