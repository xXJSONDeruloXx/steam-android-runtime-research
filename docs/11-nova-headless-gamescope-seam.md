# Nova headless gamescope seam

Test date: 2026-08-07
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740
ADB serial: `675a2365`
Gamescope source: local `gamescope-valve` commit `fb9f84ee247a1f02b1a132da60e94585db84bf61`
Gamescope build: ARM64 Debian trixie container, gamescope `3.16.23-32-gfb9f84e+`

This is the first compositor-facing iteration after the stock control in
[doc 10](10-nova-stock-gamescope-control.md). It keeps gamescope's DRM-capable build
and launches its explicit `headless` backend. Two small checked-in patches define the
experiment:

- `gamescope-headless-no-drm-identity.patch` keeps the DRM-identity requirement for
  session-based backends, while allowing a non-session backend to continue.
- `gamescope-headless-composite.patch` replaces the headless connector's discarded
  `Present()` call with `vulkan_composite()` followed by a synchronous
  `vulkan_wait()`.

The synchronous wait is intentional for this milestone. It makes the completed
Gamescope output image and its lifetime visible before adding Android buffer ownership
and acquire/release fences.

The binary is staged only inside the disposable Holo rootfs at
`/data/local/tmp/nova-holo-rootfs/opt/nova-kgsl-driver`. Android partitions,
boot images, and the global root/SU policy were not changed.

## Reproduction

Use a disposable gamescope checkout and build the ARM64 binary in Docker:

```sh
GAMESCOPE_SOURCE=/path/to/gamescope \
  android/nova-lab/build-gamescope-headless.sh

android/nova-lab/build-wayland-shm-control.sh
```

With the Holo rootfs, package closure, and KGSL Turnip driver already prepared:

```sh
INSTALL_HOLO_GAMESCOPE=0 \
  android/nova-lab/deploy-gamescope-headless-composite-test.sh
```

The deploy test stages only disposable copies below
`/data/local/tmp/nova-holo-rootfs/opt/nova-kgsl-driver`. The full report is saved as
`android/nova-lab/build/device-gamescope-headless-composite-report.txt`.
`deploy-gamescope-headless-test.sh` remains the no-client startup control.

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

## Compositor-frame evidence

The first child that could exercise `Present()` was deliberately not `vkcube`.
The rootfs's Turnip ICD reports no `VK_KHR_surface`, `VK_KHR_wayland_surface`,
or `VK_KHR_xcb_surface` instance extension. The Gamescope WSI layer is present and
can force swapchain-related device extensions, but it cannot manufacture the missing
ICD surface implementation. The vkcube control therefore exits before creating a
surface; this is a recorded WSI boundary, not a compositor failure.

The positive control is the small ARM64 `wl_shm` client built by
`build-wayland-shm-control.sh`. It connects to Gamescope's private `gamescope-0`
socket, commits a 64x64 XDG toplevel with two CPU-backed shared-memory buffers, and
keeps the client alive for five seconds. On the Nova run it produced:

```text
vulkaninfo_status=0
wayland_connect=pass socket=gamescope-0
wayland_shm_frames=298
headless_composite_frame=1 layers=1 async=0
headless_composite_frame=2 layers=1 async=0
headless_composite_frame=3 layers=1 async=0
headless_composite_frame=60 layers=1 async=0
headless_composite_frame=120 layers=1 async=0
headless_composite_frame=180 layers=1 async=0
headless_composite_frame=240 layers=1 async=0
offscreen_probe_status=0
probe_status=0
```

This proves the full intermediate path `Wayland surface -> Gamescope layer list ->
Vulkan compositor submission -> completed headless output image` on the target device.
It does not yet prove that a Steam Vulkan swapchain can run, nor that the completed
Gamescope image is visible on Android.

The companion `android/nova-lab/device/gamescope-headless-vkcube-control.sh` is the
negative WSI control. It runs `vkcube --wsi wayland` with the Gamescope WSI layer
explicitly enabled and reproduces the ICD's missing `VK_KHR_surface` failure before
any compositor frame is submitted.

## Remaining boundary

This is not yet a Steam session or an Android output backend. The completed output is
still one of Gamescope's own three exportable Vulkan images; it is not imported into
the persistent Android AHardwareBuffer/SurfaceControl queue. The run also reports
expected headless limitations: no `CAP_SYS_NICE`, no DRM FD from the wlroots renderer,
and Xwayland glamor falling back to software. Those are useful next measurements, not
evidence that the Android presentation path works.

The next implementation step is to add an optional Android output connector to this
same `Present()` seam. It should import the already-proven two-buffer
AHardwareBuffer/DMA-BUF pool, render or copy into one imported buffer, and carry the
Vulkan acquire fence into SurfaceControl. Only after that connector has a continuous
Android screenshot should the control client be replaced by Steam Gamepad UI.
