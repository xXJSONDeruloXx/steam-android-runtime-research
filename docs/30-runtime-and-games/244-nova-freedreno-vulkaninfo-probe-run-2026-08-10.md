# Nova explicit Freedreno Vulkan probe — 2026-08-10

## Question

The Geometry Wars direct comparison included the explicit Freedreno ICD but
did not emit a Vulkan enumeration line because the game reached the
D3D9/wined3d path first. The rootfs contains the standard `vulkaninfo` probe,
so this run isolates the ICD itself from Proton and the game executable.

The probe will run through the same private X11/chroot namespace and one-click
hardware-backed Termux:X11 session, with the explicit Freedreno ICD and the
same native driver library path. It will not launch Steam or modify any game
prefix.

## Run identity and fixed profile

- Run ID: `nova-vulkan-freedreno-20260810T075707Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- APK:
  `android/nova-lab/build/nova-lab-debug.apk`, SHA-256
  `3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a`
- Presentation namespace: hardware-backed Termux:X11, 1280×960, `DISPLAY=:0`
- Probe: `/usr/bin/vulkaninfo --summary`
- ICD:
  `VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`
- Driver library: `/opt/nova-kgsl-driver/libvulkan_freedreno.so`

Run directory:
`android/nova-lab/build/runs/nova-vulkan-freedreno-20260810T075707Z`

## Procedure and acceptance

Read the Nova lifecycle contract immediately before the run. Force-stop the
APK and Termux:X11, run the exact X11/rootfs cleanup helpers, verify no stale
process, mount, socket, or launcher state, and start a fresh one-click session
only to establish the private namespace and display. Record the launcher
artifact and fresh readiness marker.

Run `vulkaninfo --summary` as the Steam uid through the private namespace with
the explicit ICD, retaining the complete command, stdout, stderr, status, and
process poll. A passing result requires successful Vulkan instance/device
enumeration naming the Freedreno device; a command that only starts or emits
an ICD path is not sufficient. The probe must not be interpreted as Steam UI
or game rendering success.

After capture, stop the one-click session, run exact cleanup, remove only
run-scoped temporary state, and verify no matching process/mount/socket
remains. This declaration is committed and pushed before the device probe.
