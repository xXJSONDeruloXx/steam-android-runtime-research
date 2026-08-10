# Nova FROG WSI Gamescope socket-mode result — 2026-08-10

## Result

Changing only the live Gamescope and libei socket modes from `0755` to
`0777` allowed the Steam uid 501 child to connect through FROG. The FROG log
changed from the prior socket failure to:

    [Gamescope WSI] Application info:
      pApplicationName: vulkaninfo
    [Gamescope WSI] Executable name: vulkaninfo

There is no `Failed to connect to gamescope socket` line in this run. This is
a real FROG compositor-handshake pass and confirms socket write permission was
the immediate blocker. It is not yet a surface/rendering pass: the probe only
ran `vulkaninfo --summary`, which does not create a Vulkan surface or swapchain,
and the child still reports the Turnip instance's ten base/headless extensions.

## Run identity and artifacts

- Run ID: nova-frog-wsi-gamescope-socket-mode-20260810T092142Z
- Device: Retroid Pocket Nova, serial 675a2365
- APK SHA-256:
  3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a
- Gamescope SHA-256:
  cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca
- Gamescope source commit: fb9f84ee247a1f02b1a132da60e94585db84bf61
- FROG layer: VK_LAYER_FROG_gamescope_wsi_aarch64
- ICD: /opt/nova-kgsl-driver/freedreno-kgsl.icd.json
- Probe script SHA-256:
  581c68de2d22bfe039683b485102e450732e6f29f993439859d3a554fb2c7d38
- Nested command exit status: 0
- `nested.stdout` SHA-256:
  d951b9ed365a4f07748173d6a0d86bce1570882c180ed2d604c6d78862e149fd
- `nested.stderr` SHA-256:
  a83a859c7ddbf4000ec641df14cc7f31d2929d298fb6e6a65fbfe2d9312ea53f
- Preprobe screenshot SHA-256:
  c21f19c212d46c406e1c389bd3cefc1c6647d09ef4b41a5238458bbead473058
- Postprobe screenshot SHA-256:
  feb1dcc28b6a2bd3cb8d6ef30476549c77d953b550c4e9cb70b564c94382caee

The child recorded:

- before: `srwxr-xr-x 1 root root` for `/tmp/gamescope-0` and
  `/tmp/gamescope-0-ei`;
- after: `srwxrwxrwx 1 root root` for both sockets;
- `child_gamescope_wayland_display=gamescope-0`;
- empty `WAYLAND_DISPLAY`, as expected for this non-`--expose-wayland`
  Gamescope profile;
- `child_xdg_runtime_dir=/tmp`; and
- `uid=501(steam) gid=20 groups=20,1005`.

The same run records Gamescope's Turnip selection, `gamescope-0` compositor,
libei initialization, Xwayland startup, FROG application info, and the
absence of a FROG socket-connect error.

## Cleanup

- `nova_x11_cleanup=pass`.
- `nova_runtime_cleanup=pass` with no remaining exact-scope process.
- Final rootfs sockets are only the two baseline udev sockets:
  `/data/local/tmp/nova-holo-rootfs/run/udev/control` and
  `/data/local/tmp/nova-holo-rootfs/run/udev/io.systemd.Udev`.
- Final `/data/local/tmp/nova-steam-runtime` socket inventory is empty.
- The staged probe was removed from both the disposable rootfs and device
  staging path.
- No matching Gamescope, gamescopereaper, Xwayland, Steam, Wine/Proton,
  libei, or uinput process remains.

## Next step

Use this same permission adjustment with a surface-creating Vulkan probe or a
real Geometry Wars launch. The first meaningful rendering acceptance is FROG
surface creation plus a same-run non-Steam frame; only then should the mode
change be promoted into the one-click launcher/Gamescope path. If the surface
probe fails after the successful handshake, the remaining issue is in the
FROG-to-Turnip WSI implementation rather than socket discovery.
