# Nova FROG WSI Gamescope-nested array-wrapper result — 2026-08-10

## Result

The corrected host wrapper reached the device and launched the complete
Gamescope-nested probe. Gamescope initialized Turnip, created its headless
Wayland compositor as `gamescope-0`, initialized libei, and started Xwayland.
The child launched with the FROG layer loaded and `vulkaninfo --summary`
completed, but FROG reported:

    [Gamescope WSI] Failed to connect to gamescope socket: gamescope-0. Bypass layer will be unavailable.

The child-visible Vulkan instance still exposed only the same ten non-WSI
extensions as the exact native probe. No `VK_KHR_surface`,
`VK_KHR_wayland_surface`, or `VK_KHR_xcb_surface` appeared. This does not
provide a usable FROG/WineVulkan surface path and does not change the
pre-frame Geometry Wars boundary.

## Run identity and artifacts

- Run ID: nova-frog-wsi-gamescope-nested-array-wrapper-20260810T091111Z
- Device: Retroid Pocket Nova, serial 675a2365
- APK SHA-256:
  3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a
- Gamescope SHA-256:
  cb79e7ff366009f816b69f86c11e19c4984589a3337d633f996aff0b0319fdca
- Gamescope source commit: fb9f84ee247a1f02b1a132da60e94585db84bf61
- FROG layer: VK_LAYER_FROG_gamescope_wsi_aarch64
- ICD: /opt/nova-kgsl-driver/freedreno-kgsl.icd.json
- Nested size: 64x64
- Outer runtime: `XDG_RUNTIME_DIR=/tmp`, `PATH=/usr/bin:/bin`
- Nested command exit status: 0
- `nested.stdout` SHA-256:
  535b8d47c7498d5d23886a0bd19453cc1637f16ff65c3ee14cc11794a9d2238f
- `nested.stderr` SHA-256:
  ee8af767ead0dd22efb7246ea63c393e753ba16cb4e607af1e87d85373e38588
- Preprobe screenshot SHA-256:
  9c92cb534f7c91dfe24be5a6072c83bccd756e177277f078315926485979db91
- Postprobe screenshot SHA-256:
  9603121147b875ad00728e9421532abd4ee7b9c0626529aa1ff867dc238291eb

## Layer and compositor evidence

Gamescope's stderr records:

- physical device `Turnip Adreno (TM) 740` selected;
- headless backend creation;
- `Running compositor on wayland display 'gamescope-0'`;
- `Successfully initialized libei for input emulation!`;
- Xwayland started on `:1`.

The child loader records insertion of
`/usr/lib/libVkLayer_FROG_gamescope_wsi_aarch64.so`. FROG also logs
`Forcing on VK_EXT_swapchain_maintenance1`, then the socket-connect failure
above. The child `vulkaninfo --summary` reports `Instance Extensions: count =
10`, including `VK_EXT_headless_surface` but no Wayland, XCB, or generic
surface extension.

The child-side environment print in this attempt is not accepted as evidence:
the nested `su -c` quoting expanded the diagnostic variables before the child
shell and rendered the line as `gamescope_wayland_display=nwayland_display=n`.
The FROG library's own socket error is authoritative that it saw the
`gamescope-0` name but could not connect. A follow-up run must preserve the
child variables and list `/tmp/gamescope-0` from inside the child namespace to
separate socket visibility/permissions from a Wayland protocol failure.

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

Predeclare a fresh child-environment/socket-visibility run with corrected
remote quoting. Have the child print both variables, `id`, `XDG_RUNTIME_DIR`,
and `ls -l /tmp/gamescope-*` before running Vulkan. Do not treat a successful
`vulkaninfo --summary` as a WSI pass; the required acceptance remains a
working child surface path and, ultimately, a real game frame.
