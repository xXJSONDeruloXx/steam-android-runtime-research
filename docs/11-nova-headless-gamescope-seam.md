# Nova headless gamescope seam

Test date: 2026-08-07
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740
ADB serial: `675a2365`
Gamescope source: local `gamescope-valve` commit `fb9f84ee247a1f02b1a132da60e94585db84bf61`
Gamescope build: ARM64 Debian trixie container, gamescope `3.16.23-32-gfb9f84e+`

This is the first compositor-facing iteration after the stock control in
[doc 10](10-nova-stock-gamescope-control.md). It keeps gamescope's DRM-capable build
and launches its explicit `headless` backend. The only behavior change is the
checked-in patch in
`android/nova-lab/patches/gamescope-headless-no-drm-identity.patch`: a session-based
backend still requires `VK_EXT_physical_device_drm`, while a non-session backend may
continue without DRM device identity.

The binary is staged only inside the disposable Holo rootfs at
`/data/local/tmp/nova-holo-rootfs/opt/nova-kgsl-driver`. Android partitions,
boot images, and the global root/SU policy were not changed.

## Reproduction

Use a disposable gamescope checkout and build the ARM64 binary in Docker:

```sh
GAMESCOPE_SOURCE=/path/to/gamescope \
  android/nova-lab/build-gamescope-headless.sh
```

With the Holo rootfs, package closure, and KGSL Turnip driver already prepared:

```sh
INSTALL_HOLO_GAMESCOPE=0 \
  android/nova-lab/deploy-gamescope-headless-test.sh
```

The first run installed the Holo gamescope closure and the later repeat used
`INSTALL_HOLO_GAMESCOPE=0`. The full report is saved as
`android/nova-lab/build/device-gamescope-headless-report.txt`.

## Device evidence

The same run retained the Vulkan prerequisite:

```text
GPU0:
        deviceName         = Turnip Adreno (TM) 740
        driverID            = DRIVER_ID_MESA_TURNIP
vulkaninfo_status=0
```

The patched binary then crossed the previous failure boundary:

```text
gamescope-headless version 3.16.23-32-gfb9f84e+
vulkan: selecting physical device 'Turnip Adreno (TM) 740': queue family 0 (general queue family 0)
vulkan: physical device supports DRM format modifiers
vulkan: physical device doesn't support VK_EXT_physical_device_drm; backend does not require DRM identity
wlserver: [backend/headless/backend.c:67] Creating headless backend
wlserver: Running compositor on wayland display 'gamescope-0'
offscreen_probe_status=0
probe_status=0
```

This proves that the KGSL Turnip Vulkan device can initialize gamescope's
non-session/headless compositor path on the Nova without a DRM render-node
identity. It also proves the Wayland server and Xwayland startup path can run in
the Holo rootfs far enough for the short-lived `/usr/bin/true` child to exit
cleanly.

## Remaining boundary

This is not yet a Steam session or an Android output backend. The headless backend
starts the compositor but its current `Present()` path does not export the
composited frame into the persistent Android AHardwareBuffer/SurfaceControl queue.
The run also reports expected headless limitations: no `CAP_SYS_NICE`, no DRM FD
from the wlroots renderer, and Xwayland glamor falling back to software. Those are
useful next measurements, not evidence that the Android presentation path works.

The next implementation step is therefore to replace the headless backend's
discarded presentation with the already-proven two-buffer AHardwareBuffer pool,
carry the Vulkan acquire fence into SurfaceControl, and then launch a trivial
Wayland/X client before attempting Steam Gamepad UI.
