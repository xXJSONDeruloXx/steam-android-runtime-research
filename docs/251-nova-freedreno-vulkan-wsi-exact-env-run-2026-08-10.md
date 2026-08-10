# Nova Freedreno Vulkan WSI exact-environment probe — 2026-08-10

## Question

The native-override Geometry Wars run proved that DXVK and WineVulkan load,
but `DxvkInstance::createInstance` fails. The independent `vulkaninfo`
probe previously succeeded with the explicit Turnip ICD, but it did not use
the exact software-GL and library environment passed to Proton's 32-bit game
process.

This bounded probe compares native Vulkan enumeration under that exact
environment. It records the loader diagnostics and instance/WSI extension set,
with particular attention to `VK_KHR_surface`, `VK_KHR_xlib_surface`,
`VK_KHR_xcb_surface`, and the available platform WSI path.

## Run identity and fixed profile

- Run ID: `nova-vulkan-wsi-exact-env-20260810T082804Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- APK SHA-256:
  `3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a`
- Presentation namespace: hardware-backed Termux:X11, 1280×960,
  `DISPLAY=:0`
- Probe: `/usr/bin/vulkaninfo --summary` and
  `/usr/bin/vulkaninfo --show-formats`
- UID/GID: Steam uid 501, gid 20, supplementary group 1005
- ICD:
  `VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`
- Driver library: `/opt/nova-kgsl-driver/libvulkan_freedreno.so`
- Matching Proton environment: `MESA_LOADER_DRIVER_OVERRIDE=swrast`,
  `GALLIUM_DRIVER=softpipe`, `LIBGL_ALWAYS_SOFTWARE=1`, the same
  `LD_LIBRARY_PATH`, and `LD_PRELOAD=/opt/nova-kgsl-driver/libsysv-sem-shim.so`
- Loader diagnostics: `VK_LOADER_DEBUG=all`

Run directory:
`android/nova-lab/build/runs/nova-vulkan-wsi-exact-env-20260810T082804Z`

## Procedure and acceptance

Read the Nova lifecycle contract immediately before launch. Force-stop the
APK and Termux:X11, run the exact cleanup helpers, verify a fresh process,
mount, socket, and launcher-state baseline, and start a fresh one-click
session only to establish the private namespace and display. Record the
fresh D-Bus bus, launcher artifact, and readiness marker.

Run both Vulkan probes through the private `chroot-dev` namespace as Steam
uid 501 with the exact environment above. Record the complete command,
stdout, loader-debug stderr, status, process poll, and screenshots. A passing
native comparison requires successful enumeration and an explicit extension
inventory; a failure should identify whether the ICD, instance creation, or
WSI extension set differs from the earlier probe.

After capture, stop the one-click session, run exact cleanup, remove only the
run-scoped temporary state, and verify no matching process, mount, or socket
remains. This declaration is committed and pushed before the exact-environment
Vulkan probe.
