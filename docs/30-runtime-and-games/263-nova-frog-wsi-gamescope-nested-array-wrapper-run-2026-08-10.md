# Nova FROG WSI Gamescope-nested array-wrapper probe — 2026-08-10

## Question

This fresh run repeats the PATH-corrected nested FROG probe after the previous
host wrapper failed before invoking `adb`. The device-side variables are
unchanged: Gamescope runs with `XDG_RUNTIME_DIR=/tmp` and `PATH=/usr/bin:/bin`,
then launches the Vulkan child through the installed `gamescopereaper` path.
The child prints the inherited `GAMESCOPE_WAYLAND_DISPLAY` and
`WAYLAND_DISPLAY` values before running `vulkaninfo --summary`.

The WSI question is whether the installed FROG layer, when genuinely running
inside Gamescope, can make the Turnip ICD provide the surface path needed by
WineVulkan.

## Run identity and fixed artifacts

- Run ID: nova-frog-wsi-gamescope-nested-array-wrapper-20260810T091111Z
- Device: Retroid Pocket Nova, serial 675a2365
- Rootfs: /data/local/tmp/nova-holo-rootfs
- Gamescope: /opt/nova-kgsl-driver/gamescope-headless
- Gamescope SHA-256:
  cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca
- Gamescope source commit: fb9f84ee247a1f02b1a132da60e94585db84bf61
- Libei marker: Successfully initialized libei for input emulation!
- Headless output/nested size: 64x64
- FROG layer: VK_LAYER_FROG_gamescope_wsi_aarch64
- ICD: /opt/nova-kgsl-driver/freedreno-kgsl.icd.json
- Runtime directory: XDG_RUNTIME_DIR=/tmp
- Executable search path: PATH=/usr/bin:/bin
- APK SHA-256: 3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a

The host wrapper uses a zsh command array for `adb -s 675a2365`, preserving
the exact device invocation. The remote command passes the outer environment
through `/usr/bin/env`, including `XDG_RUNTIME_DIR` and `PATH`, before starting
Gamescope and its child.

## Lifecycle and acceptance

Read the Nova lifecycle contract immediately before launch. Force-stop the APK
and Termux:X11, run exact preflight cleanup, establish a fresh readiness and
mount/socket baseline, and launch only this run. Capture complete Gamescope and
child stdout/stderr, exit status, child environment, process polls, and
screenshots where applicable.

After capture, stop Gamescope and the Steam/X11 session with the exact cleanup
helpers. Verify no matching Gamescope, Xwayland, Steam, Wine/Proton, libei, or
uinput process remains. This declaration is committed and pushed before the
device run.
