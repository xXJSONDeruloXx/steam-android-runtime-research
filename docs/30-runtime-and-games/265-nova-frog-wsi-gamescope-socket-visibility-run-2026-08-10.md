# Nova FROG WSI Gamescope socket-visibility probe — 2026-08-10

## Question

The prior nested run reached Gamescope and loaded FROG, but FROG could not
connect to `gamescope-0`. Its own error proves the socket name was present,
while the child-side environment print was damaged by the remote `su -c`
quoting. This fresh run preserves the child shell's `$` and quote characters
and records, from inside the child namespace:

- `GAMESCOPE_WAYLAND_DISPLAY`;
- `WAYLAND_DISPLAY`;
- `XDG_RUNTIME_DIR` and `id`;
- the `/tmp/gamescope-*` directory/socket listing; and
- the FROG/Vulkan result.

The purpose is to distinguish a private-mount/socket visibility problem from a
Wayland connection or protocol problem. A successful headless
`vulkaninfo --summary` remains insufficient; the acceptance target is a
working Gamescope WSI path that can later create a real game surface.

## Run identity and fixed artifacts

- Run ID: nova-frog-wsi-gamescope-socket-visibility-20260810T091807Z
- Device: Retroid Pocket Nova, serial 675a2365
- Rootfs: /data/local/tmp/nova-holo-rootfs
- Gamescope: /opt/nova-kgsl-driver/gamescope-headless
- Gamescope SHA-256:
  cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca
- Gamescope source commit: fb9f84ee247a1f02b1a132da60e94585db84bf61
- APK SHA-256:
  3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a
- FROG layer: VK_LAYER_FROG_gamescope_wsi_aarch64
- ICD: /opt/nova-kgsl-driver/freedreno-kgsl.icd.json
- Headless output/nested size: 64x64
- Runtime directory: XDG_RUNTIME_DIR=/tmp
- Executable search path: PATH=/usr/bin:/bin

The host wrapper uses a zsh command array for the device selector. The remote
`su -mm 0 -c` payload escapes the child diagnostic's inner double quotes and
dollar signs so that expansion occurs only in the child shell. The child then
prints diagnostics and runs `/usr/bin/vulkaninfo --summary` under the explicit
FROG layer.

## Lifecycle and acceptance

Read the Nova lifecycle contract immediately before launch. Force-stop the APK
and Termux:X11, run exact preflight cleanup, establish fresh process,
mount/socket, and launcher-state baselines, and launch only this run. Capture
the complete nested stdout/stderr, command, status, child diagnostics, FROG
messages, launcher logs, and same-run screenshots.

After capture, force-stop the APK and Termux:X11, run both exact cleanup
helpers, and verify no matching Gamescope, gamescopereaper, Xwayland,
Steam/Wine/Proton, libei, or uinput process remains. Retain only the two
baseline rootfs udev sockets. This declaration is committed and pushed before
the device run.
