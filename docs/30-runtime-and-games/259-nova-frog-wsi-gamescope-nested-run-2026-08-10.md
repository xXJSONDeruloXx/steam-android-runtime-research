# Nova FROG WSI Gamescope-nested probe — 2026-08-10

## Question

The direct Termux:X11 FROG run loaded the layer but did not set
`GAMESCOPE_WAYLAND_DISPLAY`, so the source-level Gamescope bypass branch was
not exercised. This bounded control launches the installed headless Gamescope
binary and runs a native child inside Gamescope's own Wayland namespace. The
Gamescope child should set `GAMESCOPE_WAYLAND_DISPLAY=gamescope-0`; the FROG
layer should then add its Wayland/XCB surface requests before the Turnip ICD
creates the instance.

This distinguishes “the layer is inactive outside Gamescope” from “Turnip
cannot satisfy the surface extensions that the layer requires.”

## Fixed run identity and command

- Run ID: `nova-frog-wsi-gamescope-nested-20260810T085551Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- Gamescope artifact:
  `/opt/nova-kgsl-driver/gamescope-headless`
- Gamescope host artifact:
  `android/nova-lab/build/gamescope-headless-libei-build-v2/src/gamescope`
- Gamescope SHA-256:
  `cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca`
- Gamescope source commit:
  `fb9f84ee247a1f02b1a132da60e94585db84bf61`
- Gamescope build marker: `Successfully initialized libei for input emulation!`
- Headless size: output and nested `64x64`
- FROG layer:
  `VK_LAYER_FROG_gamescope_wsi_aarch64`
- ICD:
  `VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`

Run one child command:

```text
GAMESCOPE_SCRIPT_PATH=/usr/share/gamescope/scripts
VK_INSTANCE_LAYERS=VK_LAYER_FROG_gamescope_wsi_aarch64
VK_LOADER_DEBUG=all
/opt/nova-kgsl-driver/gamescope-headless
  --backend headless --output-width 64 --output-height 64
  --nested-width 64 --nested-height 64 --
  /usr/bin/env ENABLE_GAMESCOPE_WSI=1
    VK_INSTANCE_LAYERS=VK_LAYER_FROG_gamescope_wsi_aarch64
    VK_LOADER_DEBUG=all
    VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
    /usr/bin/timeout 10 /usr/bin/vulkaninfo --summary
```

Capture the complete Gamescope/child stdout and stderr, exit status, process
polls, the child environment evidence, and a screenshot if the headless
session reaches the Android-facing display. A pass requires the nested child
to create a Vulkan instance with a usable surface path; a Turnip
`VK_ERROR_EXTENSION_NOT_PRESENT` result is a valid negative boundary.

The first host invocation of this run omitted `/usr/bin/env` between the
private chroot helper's rootfs argument and the Gamescope environment
assignments. The helper therefore returned exit status 127 before launching
Gamescope (`chroot: exec GAMESCOPE_SCRIPT_PATH=...: No such file or
directory`). No WSI evidence was collected from that attempt; exact cleanup
returned pass. The corrected retry must pass the assignments through
`/usr/bin/env` and use a new run identity.

## Lifecycle and acceptance

Read the Nova runtime lifecycle contract immediately before launch. Force-stop
the APK and Termux:X11, run the exact runtime and X11 cleanup helpers, verify
fresh process/mount/socket/launcher state, and use a new run directory. Stop
Gamescope after capture, run exact cleanup, and verify no matching Gamescope,
Xwayland, Steam, Wine/Proton, libei, or uinput process remains. Preserve only
this run's artifacts.

This declaration is committed and pushed before the nested probe.
