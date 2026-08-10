# Nova FROG WSI Gamescope-nested corrected probe — 2026-08-10

## Question

This is the corrected retry of the predeclared nested FROG probe. The prior
attempt stopped at the private chroot boundary because its environment
assignments were passed as the executable. This run passes them through
`/usr/bin/env` and records the child-side
`GAMESCOPE_WAYLAND_DISPLAY`/`WAYLAND_DISPLAY) values before Vulkan starts.

The target distinction remains:

- if the nested child reaches FROG's Gamescope path and Turnip accepts the
  required extensions, this is a viable WSI bridge candidate;
- if Turnip returns `VK_ERROR_EXTENSION_NOT_PRESENT`, the installed ICD
  lacks the surface implementation that FROG requires.

## Run identity and fixed artifacts

- Run ID: `nova-frog-wsi-gamescope-nested-corrected-20260810T085947Z`
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

The private namespace command is:

```text
NOVA_X11_ALLOW_INPUT_EVENTS=9
/data/.../nova-x11-private-namespace.sh chroot-dev
  /data/.../nova-mount-private /data/local/tmp/nova-holo-rootfs
  /usr/bin/env
    GAMESCOPE_SCRIPT_PATH=/usr/share/gamescope/scripts
    VK_INSTANCE_LAYERS=VK_LAYER_FROG_gamescope_wsi_aarch64
    VK_LOADER_DEBUG=all
    VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
    /usr/bin/timeout 30
      /opt/nova-kgsl-driver/gamescope-headless
      --backend headless --output-width 64 --output-height 64
      --nested-width 64 --nested-height 64 --
      /usr/bin/setpriv --reuid=501 --regid=20 --groups=1005
      /usr/bin/env ENABLE_GAMESCOPE_WSI=1
        VK_INSTANCE_LAYERS=VK_LAYER_FROG_gamescope_wsi_aarch64
        VK_LOADER_DEBUG=all
        VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
        /usr/bin/sh -c 'print Gamescope Wayland variables; exec
          /usr/bin/timeout 10 /usr/bin/vulkaninfo --summary'
```

The actual run records the complete unabridged command and replaces the
ellipsis paths with the installed app paths. Capture stdout, stderr, child
environment evidence, status, process polls, and screenshots where
applicable.

The first corrected invocation did pass environment assignments through
`/usr/bin/env` and entered Gamescope, but it omitted
`XDG_RUNTIME_DIR`. Gamescope then stopped before spawning the child with
`Unable to open wayland socket: No such file or directory`; no FROG child
WSI evidence was collected. Exact cleanup returned pass. The next fresh run
sets `XDG_RUNTIME_DIR=/tmp` inside the rootfs.

## Lifecycle and acceptance

Read the Nova lifecycle contract immediately before launch. Force-stop the
APK and Termux:X11, run exact preflight cleanup, establish a fresh readiness
and mount/socket baseline, then launch only this run. After capture, stop the
Gamescope/Steam session and run exact cleanup; verify no matching Gamescope,
Xwayland, Steam, Wine/Proton, libei, or uinput process remains.

This declaration is committed and pushed before the corrected device run.
