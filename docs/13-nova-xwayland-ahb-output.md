# Nova Xwayland to Android AHardwareBuffer output

Test date: 2026-08-07
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740
ADB serial: `675a2365`
Gamescope source: local `gamescope-valve`, commit `fb9f84ee247a1f02b1a132da60e94585db84bf61`

This is the next boundary after [doc 12](12-nova-gamescope-ahb-output.md). It
replaces the Wayland-SHM control client with an Xwayland session and an
animated native ARM64 X11 client, while retaining the same Android
AHardwareBuffer output and acquire/release-fence protocol.

## Reproduction

Install the Xwayland package closure into the disposable Holo rootfs and build
the small ARM64 X11 damage generator:

```sh
HOLO_PACKAGES='xorg-xwayland xorg-xmessage' \
  android/nova-lab/install-holo-packages.sh

android/nova-lab/build-x11-animate.sh
```

Run the bounded 960x540, 30-frame acceptance test:

```sh
INSTALL_HOLO_GAMESCOPE=0 \
  NOVA_AHB_FRAME_COUNT=30 NOVA_AHB_WIDTH=960 NOVA_AHB_HEIGHT=540 \
  NOVA_GAMESCOPE_X11_CLIENT=android/nova-lab/build/nova-x11-animate \
  NOVA_GAMESCOPE_AHB_SKIP_WAYLAND=1 \
  NOVA_GAMESCOPE_AHB_SKIP_WAYLAND_SHM=1 \
  NOVA_GAMESCOPE_AHB_XWAYLAND=1 \
  NOVA_GAMESCOPE_AHB_CONTROL=android/nova-lab/device/gamescope-headless-xwayland-ahb-control.sh \
  android/nova-lab/deploy-gamescope-headless-ahb-test.sh
```

The package install modifies only the disposable extracted rootfs. The test
stages the generated X11 client below
`/data/local/tmp/nova-holo-rootfs/opt/nova-kgsl-driver` and does not alter
Android partitions or the global root/SU policy.

## What the test proves

The ARM64 X11 client creates a mapped X window and changes its full-window
color every 16 ms. The Xwayland control script starts Gamescope with one
embedded Xwayland server, and the patched output connector stops submitting
after the requested AHardwareBuffer frame count. The device report contains:

```text
[wlserver] [xwayland/server.c:107] Starting Xwayland on :0
Xwayland glamor: GBM Wayland interfaces not available
Failed to initialize glamor, falling back to sw
[headless] Android AHardwareBuffer output imported: 2 x 960x540 RGBA
android_ahb_composite_frame=1 layers=1 async=0
android_ahb_composite_frame=2 layers=1 async=0
android_ahb_composite_frame=3 layers=1 async=0
android_ahb_target_reached=30
offscreen_probe_status=0
probe_status=0
```

The Android log records the complete downstream contract:

```text
ahb_double_buffer_size=960x540
surface_frame_complete=pass       # 30 occurrences
linux_acquire_fence=pass          # 30 occurrences
ahb_double_buffer_frames=30 releases=29
ahb_double_buffer=pass
```

The client log records `client_kind=animated_x11`, `client_status=0`, and
`nova_x11_frames=120`. The output report contains no
`Android output acquire fence handoff failed` lines: the new target guard
stops Gamescope cleanly when the Android app closes its bridge after frame 30.

This establishes the following measured path:

```text
native ARM64 X11 client
  -> Xwayland
  -> Gamescope layer list
  -> Vulkan composite into imported Android AHardwareBuffer
  -> Linux acquire fence
  -> Android SurfaceControl presentation
  -> Android release fence
  -> bounded two-buffer reuse
```

## Current constraint and next gate

Xwayland itself starts and the X11 client reaches the Android output, but
glamor cannot use GBM Wayland interfaces in this headless Holo rootfs, so the
server falls back to software rendering. This is a known performance and
compatibility constraint, not a failure of the buffer handoff.

The actual native ARM64 Steam process has now been launched through this path;
the loader, System V semaphore, and X11 authorization boundaries are recorded
in [doc 14](14-nova-steam-arm64-seed-and-startup.md). It reaches Steam's update
UI, but the rootfs has no default route/DNS and therefore no verified
`.installed` manifest. No login/Gamepad UI frame has been produced yet. The
next gate is an offline bootstrap validated by Steam itself, followed by
`steamwebhelper` and persistent Android output evidence.
