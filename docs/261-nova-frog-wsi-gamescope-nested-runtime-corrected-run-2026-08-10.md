# Nova FROG WSI Gamescope-nested runtime-corrected probe — 2026-08-10

## Question

This is the fresh retry after the nested Gamescope command reached Gamescope
but omitted XDG_RUNTIME_DIR. The only new harness variable is
XDG_RUNTIME_DIR=/tmp inside the disposable Holo rootfs, which is a
world-writable runtime directory suitable for Gamescope's headless Wayland
socket. The child still prints the two Gamescope Wayland variables before
running Vulkan.

The WSI acceptance question is unchanged: once the child is genuinely under
Gamescope, does the FROG layer plus the installed Turnip ICD create a usable
Vulkan instance/surface path?

## Run identity and fixed artifacts

- Run ID: `nova-frog-wsi-gamescope-nested-runtime-corrected-20260810T090232Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- Gamescope: `/opt/nova-kgsl-driver/gamescope-headless`
- Gamescope SHA-256:
  `cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca`
- Gamescope source commit:
  `fb9f84ee247a1f02b1a132da60e94585db84bf61`
- Libei marker: `Successfully initialized libei for input emulation!`
- Headless output/nested size: `64x64`
- FROG layer: `VK_LAYER_FROG_gamescope_wsi_aarch64`
- ICD: `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`
- Runtime directory: `XDG_RUNTIME_DIR=/tmp`

The corrected private command passes all assignments through
/usr/bin/env, including XDG_RUNTIME_DIR=/tmp, before the outer
Gamescope invocation. The child inherits Gamescope's
GAMESCOPE_WAYLAND_DISPLAY and WAYLAND_DISPLAY values and prints them
before vulkaninfo --summary.

## Lifecycle and acceptance

Read the Nova lifecycle contract immediately before launch. Force-stop the
APK and Termux:X11, run exact preflight cleanup, establish a fresh readiness
and mount/socket baseline, then launch only this run. Capture the complete
Gamescope/child stdout and stderr, exit status, child environment, process
polls, and screenshots where applicable.

After capture, stop Gamescope and the Steam/X11 session with the exact cleanup
helpers. Verify no matching Gamescope, Xwayland, Steam, Wine/Proton, libei, or
uinput process remains. This declaration is committed and pushed before the
device run.
