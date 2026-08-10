# Nova Freedreno Vulkan WSI exact-environment retry — 2026-08-10

## Question

The native-override Geometry Wars run proved that DXVK and WineVulkan load,
but `DxvkInstance::createInstance` fails. A prior exact-environment Vulkan
probe was stopped by a launcher-state capture race before either probe ran.
This fresh run retries the comparison with a new identity and a bounded wait
for every launcher-state file before proceeding.

The probes compare native Vulkan enumeration under the same software-GL and
library environment passed to Proton's 32-bit game process, recording loader
diagnostics and the instance/WSI extension set.

## Run identity and fixed profile

- Run ID: `nova-vulkan-wsi-exact-env-retry-20260810T083310Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- APK SHA-256:
  `3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a`
- Presentation namespace: hardware-backed Termux:X11, 1280×960,
  `DISPLAY=:0`
- Probes: `/usr/bin/vulkaninfo --summary` and
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
`android/nova-lab/build/runs/nova-vulkan-wsi-exact-env-retry-20260810T083310Z`

## Procedure and acceptance

Read the Nova lifecycle contract immediately before launch. Force-stop the
APK and Termux:X11, run the exact cleanup helpers, verify a fresh process,
mount, socket, and launcher-state baseline, and start a fresh one-click
session only to establish the private namespace and display. Retry reads of
the launcher log, client log, server log, screenshot, and D-Bus bus until the
fresh readiness marker and bus are both present; record the resulting
artifacts.

Run both Vulkan probes through the private `chroot-dev` namespace as Steam
uid 501 with the exact environment above. Record the complete commands,
stdout, loader-debug stderr, statuses, process polls, and screenshots. A
passing native comparison requires successful enumeration and an explicit
extension inventory; a failure should identify whether the ICD, instance
creation, or WSI extension set differs from the earlier probe.

After capture, stop the one-click session, run exact cleanup, remove only the
run-scoped temporary state, and verify no matching process, mount, or socket
remains. This declaration is committed and pushed before the retry probe.

## Harness correction before execution

The first host launch on 2026-08-10T08:34Z reached fresh
`nova_launcher_ready=pass`, but the capture loop passed `su -c` as separate
`adb shell` arguments. Its remote `cat` therefore raced/flattened the state
read and the host script stopped before writing either Vulkan probe command.
No probe ran. The live session was stopped afterward; both exact cleanup
helpers returned `pass`, no matching process remained, and only the two
baseline udev sockets remained. The corrected retry uses one quoted remote
`su -c 'cat ...'` command for each state read and a new run identity.
