# Nova FROG WSI Gamescope-nested PATH-corrected probe — 2026-08-10

## Question

This fresh run retries the nested FROG probe after the compositor successfully
created gamescope-0 but could not find gamescopereaper. The outer environment
now explicitly sets PATH=/usr/bin:/bin, while retaining XDG_RUNTIME_DIR=/tmp.
The child prints the Gamescope Wayland variables before running
vulkaninfo --summary.

The WSI question is unchanged: once the Vulkan child is genuinely spawned
under Gamescope, does FROG plus the installed Turnip ICD provide the surface
path needed by WineVulkan?

## Run identity and fixed artifacts

- Run ID: nova-frog-wsi-gamescope-nested-path-corrected-20260810T090539Z
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

The private command passes the outer environment through /usr/bin/env,
including XDG_RUNTIME_DIR and PATH, then starts Gamescope and its child. The
child inherits Gamescope's GAMESCOPE_WAYLAND_DISPLAY and WAYLAND_DISPLAY and
prints both values before the Vulkan probe.

## Lifecycle and acceptance

Read the Nova lifecycle contract immediately before launch. Force-stop the
APK and Termux:X11, run exact preflight cleanup, establish a fresh readiness
and mount/socket baseline, then launch only this run. Capture complete
Gamescope and child stdout/stderr, exit status, child environment, process
polls, and screenshots where applicable.

After capture, stop Gamescope and the Steam/X11 session with the exact cleanup
helpers. Verify no matching Gamescope, Xwayland, Steam, Wine/Proton, libei, or
uinput process remains. This declaration is committed and pushed before the
device run.

## Host wrapper failure before device invocation

The first host invocation after this declaration did not reach the device.
The zsh wrapper stored `adb -s 675a2365` in a scalar and expanded it as one
command name, producing `command not found: adb -s 675a2365`. Consequently the
one-click Activity was not launched, no nested Gamescope process was created,
and no WSI or child Vulkan evidence exists for that attempt. The generated
`am-start.txt`, readiness timeout, and empty nested probe outputs are retained
under the run directory as harness-failure artifacts. The next attempt uses a
zsh command array and a new run identity.
