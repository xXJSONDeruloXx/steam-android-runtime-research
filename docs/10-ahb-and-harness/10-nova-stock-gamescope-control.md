# Nova stock gamescope control

Test date: 2026-08-07
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno 740
ADB serial: `675a2365`
Holo gamescope package: `3.16.17-1-aarch64`

This is a negative control between the proven KGSL Turnip Vulkan path and a real
compositor. It runs the unmodified Holo gamescope binary in the same disposable
ARM64 glibc rootfs, with the checked-in KGSL Turnip library selected explicitly.
It does not modify Android partitions or the boot image.

## Reproduction

The package helper now accepts a space-separated `HOLO_PACKAGES` list. The gamescope
wrapper adds `gamescope` to the existing Vulkan package set and installs the resolved
closure through pacman inside the disposable rootfs:

```sh
android/nova-lab/fetch-holo-rootfs.sh
android/nova-lab/install-holo-gamescope.sh
android/nova-lab/deploy-gamescope-control.sh
```

The control deploys the already-tested KGSL Turnip library, runs `vulkaninfo --summary`,
then launches `/usr/bin/gamescope` with no child command. That exercises gamescope's
normal auto-selected standalone backend. A repeat can skip the package transfer:

```sh
INSTALL_HOLO_GAMESCOPE=0 android/nova-lab/deploy-gamescope-control.sh
```

The full report is saved at
`android/nova-lab/build/device-gamescope-control-report.txt`.

## Device evidence

The Vulkan prerequisite passed in the same run:

```text
vulkan_icd_file=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
GPU0:
        deviceName         = Turnip Adreno (TM) 740
        driverID            = DRIVER_ID_MESA_TURNIP
        driverInfo          = Mesa 25.2.7
vulkaninfo_status=0
```

Gamescope selected that device and confirmed modifier support, then stopped at the
DRM identity contract:

```text
[gamescope] [Info]  vulkan: selecting physical device 'Turnip Adreno (TM) 740': queue family 0 (general queue family 0)
[gamescope] [Info]  vulkan: physical device supports DRM format modifiers
[gamescope] [Error] vulkan: physical device doesn't support VK_EXT_physical_device_drm
Failed to initialize Vulkan
Failed to create backend.
offscreen_probe_status=1
probe_status=1
```

The checked-in control treats this expected failure as a passing negative-control
result. The important separation is:

```text
ARM64 glibc + KGSL Turnip + Vulkan device       pass
stock gamescope device initialization            blocked on VK_EXT_physical_device_drm
```

## Interpretation

This is not a missing shared-library or Vulkan-device failure. Stock gamescope's
`CVulkanDevice` requires `VK_EXT_physical_device_drm` so it can derive a DRM render
node and related device identity. The KGSL Turnip build intentionally targets the
Android KGSL ioctl path, and the Nova's Android display boundary is SurfaceControl/
AHardwareBuffer rather than a normal Linux DRM/KMS ownership model. A gamescope
variant therefore needs an Android-compatible backend/device path; merely copying
stock gamescope into the Holo rootfs cannot finish the display integration.

The existing two-buffer AHardwareBuffer loop already proves the lower-level ownership
and acquire/release-fence contract. The next experiment is a narrow gamescope-side
headless/backend seam that allows Vulkan composition without assuming DRM identity,
followed by importing the persistent AHardwareBuffer output rather than treating a
standalone `vkcube` or a stock DRM session as completion.

## What this does not prove

- no Wayland server or gamescope Android output backend is present yet;
- no Steam ARM64 client, SteamRT3C, Xwayland, input, audio, or lifecycle integration;
- no claim that skipping the DRM identity check is sufficient for the final compositor;
- no rootless Android presentation path.
