# Nova Geometry Wars Proton 11 explicit Freedreno corrected run — 2026-08-10

## Scope

This is the corrected fresh execution of the explicit-Freedreno diagnostic
declared in
[`docs/241-nova-geometry-wars-proton11-freedreno-direct-run-2026-08-10.md`](241-nova-geometry-wars-proton11-freedreno-direct-run-2026-08-10.md).
The first attempt used an unquoted executable path and was discarded as an
argv/harness failure; it was documented and cleaned before this run.

The corrected command keeps the same one-click hardware-backed
Termux:X11/software-GL session, Proton 11 ARM64 wrapper, AppID-8400 prefix,
empty CPU registry section, and explicit Freedreno Vulkan ICD. The only
correction is quoting the `Geometry Wars/GeometryWars.exe` path as one
`runinprefix` argument.

## Run identity and fixed profile

- Run ID: `nova-game-geometry-freedreno-20260810T075005Z`
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
- Added Vulkan variable:
  `VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`
- Observability: `PROTON_LOG=1` with a run-scoped `PROTON_LOG_DIR`

Run directory:
`android/nova-lab/build/runs/nova-game-geometry-freedreno-20260810T075005Z`

## Procedure and acceptance

Read the Nova lifecycle contract immediately before the run. Force-stop the
APK and Termux:X11, run the exact cleanup helpers, verify a fresh process,
mount, socket, and launcher-state baseline, and start a fresh one-click
session. Snapshot `system.reg`, `user.reg`, and `userdef.reg` from the
AppID-8400 prefix.

Invoke the quoted executable through the private X11/chroot namespace and
`proton runinprefix`. Retain the complete command, status, Proton log,
process poll, and repeated same-run screenshots. Success requires a changed
Vulkan-enumeration result and a real Geometry Wars frame; a log change without
a frame remains a startup-boundary result.

After capture, stop the direct tree and one-click session, restore all three
prefix registry files byte-for-byte, remove only exact run-scoped logs and
stale sockets, and verify clean process/mount/socket state. This declaration
is committed and pushed before the corrected device launch.
