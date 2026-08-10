# Nova FROG WSI Gamescope socket-visibility result — 2026-08-10

## Result

The corrected child diagnostics show that the Gamescope socket is visible in
the child namespace, but it is not writable by the Steam uid:

    gamescope_wayland_display=gamescope-0
    wayland_display=
    xdg_runtime_dir=/tmp
    uid=501(steam) gid=20 groups=20,1005
    srwxr-xr-x 1 root root 0 ... /tmp/gamescope-0

FROG then reports:

    [Gamescope WSI] Failed to connect to gamescope socket: gamescope-0. Bypass layer will be unavailable.

This is no longer a namespace-visibility mystery. Gamescope creates the
socket as root with mode `0755`; pathname Unix-socket connection requires
write access, which uid 501 does not have. The result strongly identifies
socket ownership/mode as the next concrete unblocker. The child still reports
the ten-extension headless Vulkan instance and no WSI extension, so no game
surface or frame is accepted yet.

## Run identity and artifacts

- Run ID: nova-frog-wsi-gamescope-socket-visibility-20260810T091807Z
- Device: Retroid Pocket Nova, serial 675a2365
- APK SHA-256:
  3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a
- Gamescope SHA-256:
  cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca
- Gamescope source commit: fb9f84ee247a1f02b1a132da60e94585db84bf61
- FROG layer: VK_LAYER_FROG_gamescope_wsi_aarch64
- ICD: /opt/nova-kgsl-driver/freedreno-kgsl.icd.json
- Nested size: 64x64
- Nested command exit status: 0
- `nested.stdout` SHA-256:
  535b8d47c7498d5d23886a0bd19453cc1637f16ff65c3ee14cc11794a9d2238f
- `nested.stderr` SHA-256:
  7ba5636d8e8ec26a97669a8cb031c38c77d5e161d232b71b8503ac6638d653fa
- `child-script.txt` SHA-256:
  3443e8574fc08b8df69bb85ec449aaa453bd5292aa614a9e7a0c6b040e05d3c8
- Preprobe screenshot SHA-256:
  c21f19c212d46c406e1c389bd3cefc1c6647d09ef4b41a5238458bbead473058
- Postprobe screenshot SHA-256:
  51b1dd2819251f37234dfdae460f42de36ec0858c2aa9182c1a60c9ea013f954

## Supporting evidence

The same stderr shows:

- `Running compositor on wayland display 'gamescope-0'`;
- `Successfully initialized libei for input emulation!`;
- Xwayland started on `:1`;
- the child uid/gid and `XDG_RUNTIME_DIR=/tmp` above;
- `/tmp/gamescope-0-ei` with the same root-owned `0755` socket mode; and
- `Instance Extensions: count = 10` in child `vulkaninfo` output, with no
  `VK_KHR_surface`, `VK_KHR_wayland_surface`, or `VK_KHR_xcb_surface`.

The child command now preserves its variables through the nested remote shell;
the prior malformed diagnostic is superseded by this run.

## Cleanup

- `nova_x11_cleanup=pass`.
- `nova_runtime_cleanup=pass` with no remaining exact-scope process.
- Final rootfs sockets are only the two baseline udev sockets:
  `/data/local/tmp/nova-holo-rootfs/run/udev/control` and
  `/data/local/tmp/nova-holo-rootfs/run/udev/io.systemd.Udev`.
- Final `/data/local/tmp/nova-steam-runtime` socket inventory is empty.
- No matching Gamescope, gamescopereaper, Xwayland, Steam, Wine/Proton,
  libei, or uinput process remains.

## Next experiment

Predeclare a fresh permission-isolation run. Have a root wrapper wait for
`/tmp/gamescope-0`, change only the compositor socket mode to `0777` (and
record the before/after mode), then drop to uid 501 and run the same FROG
probe. If FROG connects, move the permission change into the Gamescope
launcher/source path; if it still fails, inspect the Wayland protocol or
driver WSI path next. Do not alter the Turnip ICD or claim success from
`vulkaninfo --summary` alone.
