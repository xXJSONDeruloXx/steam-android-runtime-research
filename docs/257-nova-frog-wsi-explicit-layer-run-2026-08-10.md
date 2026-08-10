# Nova FROG Gamescope WSI explicit-layer probe — 2026-08-10

## Question

The exact-environment Vulkan probe found a healthy Turnip ICD but no native
X11, Win32, Android, or Wayland instance surface extension. The rootfs does
contain the FROG Gamescope WSI layer:

- manifest:
  `/usr/share/vulkan/implicit_layer.d/VkLayer_FROG_gamescope_wsi.aarch64.json`
- library:
  `/usr/lib/libVkLayer_FROG_gamescope_wsi_aarch64.so`
- manifest activation variable: `ENABLE_GAMESCOPE_WSI=1`
- layer name: `VK_LAYER_FROG_gamescope_wsi_aarch64`
- device library SHA-256:
  `6797355511b1d62d7d324b9f49e0119a48d2b5647489a4f55784cde37f03eb5a`

The library depends on XCB/X11-XCB and Wayland and contains the Gamescope
surface/present hooks, so it is the most direct remaining candidate for the
missing WSI bridge.

## Fixed run identity and comparison

- Run ID: `nova-frog-wsi-explicit-layer-20260810T084535Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- Presentation: fresh one-click Termux:X11 session, `DISPLAY=:0`,
  `1280x960`, hardware acceleration enabled
- UID/GID: Steam uid 501, gid 20, supplementary group 1005
- ICD: `VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`
- Loader: `VK_LOADER_DEBUG=all`
- Matching Proton variables: software GL overrides, the Proton
  `LD_LIBRARY_PATH`, and
  `LD_PRELOAD=/opt/nova-kgsl-driver/libsysv-sem-shim.so`

Run two variants in the same fresh session:

1. implicit activation: add `ENABLE_GAMESCOPE_WSI=1`
2. explicit activation: add
   `ENABLE_GAMESCOPE_WSI=1 VK_INSTANCE_LAYERS=VK_LAYER_FROG_gamescope_wsi_aarch64`

For each variant capture `vulkaninfo --summary` and
`vulkaninfo --show-formats`, complete stdout/stderr, exit status, process
polls, and a screenshot. The comparison is successful only if the FROG layer
adds a usable surface extension or otherwise lets a native WSI/surface probe
complete. Layer discovery alone is not a pass.

## Lifecycle and acceptance

Read the Nova runtime lifecycle contract immediately before launch. Force-stop
the APK, run the exact runtime and Termux:X11 cleanup helpers, verify a fresh
process/mount/socket/launcher-state baseline, and record the installed APK
identity and launcher flags. Stop the session after both variants, run exact
cleanup, remove only this run's temporary state, and verify no matching
Gamescope, Xwayland, Steam, Wine/Proton, libei, or uinput process remains.

The launcher readiness file is a literal `pass` marker, matching the
`nova_launcher_ready=pass` log line. The initial host-side poll for this run
incorrectly expected `1`; it timed out without running a Vulkan command.
Readiness was then verified from the fresh launcher log and the literal
`pass` file before continuing.

This declaration is committed and pushed before the device probe. Artifacts
will be retained under:

`android/nova-lab/build/runs/nova-frog-wsi-explicit-layer-20260810T084535Z`
