# Nova Holo ARM64 glibc and Vulkan probe

Test date: 2026-08-07
Device: Retroid Pocket Nova, `kalama`, Snapdragon/Adreno
ADB serial: `675a2365`

This is the second executable milestone after the rooted Android bridge in
[the previous smoke test](07-nova-rooted-bridge-smoke-test.md). It stages one fixed Holo
ARM64 userspace in disposable device storage, enters it through the same root-owned
mount namespace, and checks the native Linux ABI and Vulkan boundary separately.

## Reproduction

The rootfs is not committed to the repository. The checked-in helper pins the Holo
preview snapshot and verifies its archive before extraction:

```sh
android/nova-lab/fetch-holo-rootfs.sh
android/nova-lab/install-holo-packages.sh
android/nova-lab/deploy-holo-probe.sh
```

The device-side rootfs used for this run was:

```text
base=https://holo-packages.steamos.cloud/holo-core-aarch64-preview/mash-20251118.3
archive=system.rootfs.zst
sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
device_path=/data/local/tmp/nova-holo-rootfs
```

The probe binds only disposable namespace views of `/dev`, `/proc`, `/sys`,
`/vendor`, `/system`, `/apex`, and `/linkerconfig`. Its cleanup trap removes those
mounts before returning. It does not modify Android partitions or the boot image.

## Userspace result

The base Holo rootfs was extended with a 17-package closure resolved from its current
core/extra aarch64 databases. The closure includes `vulkan-tools`,
`vulkan-freedreno`, `vulkan-icd-loader`, `vulkan-mesa-device-select`, `libdrm`, and
their X11/Wayland/SPIR-V dependencies. Package files are downloaded with SHA-256
verification by `fetch-holo-packages.py`, then installed by pacman inside the chroot.

The install initially exposed an environment bug: pacman's systemd hook could not find
`touch` because the chroot inherited Android's PATH. The installer now enters with
`env -i PATH=/usr/bin:/bin HOME=/tmp`; the rerun completed the post-transaction hook
without error.

The glibc boundary passed:

```text
ld.so (GNU libc) stable release version 2.42.
chroot.shell=ok
aarch64
glibc=ldd (GNU libc) 2.42
```

The driver shared object's dependencies also resolved under the Holo loader, including
`libdrm`, `libudev`, `libwayland-client`, X11/XCB, `libstdc++`, and glibc. This means
the next failure is not simply “an ARM64 ELF cannot start” or “the ICD has a missing
shared library.”

## Vulkan result

The standard Holo ICD was found and loaded far enough for `vulkaninfo` to enumerate
physical devices, but enumeration failed:

```text
rootfs.path./usr/bin/vulkaninfo=present
mount./data/local/tmp/nova-holo-rootfs/dev=pass
mount./data/local/tmp/nova-holo-rootfs/sys=pass
vulkaninfo.begin
ERROR: [Loader Message] Code 0 : setup_loader_term_phys_devs:  Failed to detect any valid GPUs in the current config
ERROR at .../vulkaninfo.h:247:vkEnumeratePhysicalDevices failed with ERROR_INITIALIZATION_FAILED
vulkaninfo_status=1
probe_status=1
```

The result is unchanged with the Mesa device-select implicit layer disabled and with
`VULKAN_LOADER_DEBUG=all`: the loader finds
`/usr/share/vulkan/icd.d/freedreno_icd.aarch64.json` pointing at
`/usr/lib/libvulkan_freedreno.so`, but no physical device is exposed to the driver.

The Android kernel evidence explains the immediate compatibility gap:

```text
/dev/kgsl-3d0                         major=479 minor=0
/sys/class/kgsl/kgsl-3d0/gpu_model   Adreno740v2
/sys/class/kgsl/kgsl-3d0/device      DRIVER=kgsl-3d
/sys/class/drm/renderD128/driver     /sys/bus/platform/drivers/msm_drm
```

The Nova exposes the Adreno GPU through Qualcomm's KGSL device, while the ordinary
Holo Turnip path is a DRM render-node path and sees the display controller's `msm_drm`
node. This is strong evidence for the previously identified requirement for a KGSL-
enabled Android Turnip/Mesa build; it is not yet proof that a particular Mesa build or
kernel ioctl will work on this Nova.

## What this proves

- A fixed ARM64 glibc rootfs can execute natively inside the rooted Android namespace.
- Holo package metadata and pacman can be used reproducibly without installing into
  Android's read-only system partitions.
- The standard Holo Vulkan userspace reaches driver enumeration, but does not bridge
  Nova's KGSL GPU into a Linux Vulkan physical device.
- The next work should target the KGSL-enabled Turnip/Mesa boundary before gamescope,
  Wayland, Steam, or FEX integration.

It does **not** yet prove that Steam can run, that a KGSL-enabled driver can initialize,
or that a Linux compositor can export frames to the Android app. The disposable Holo
rootfs and package staging directories remain under `/data/local/tmp` for the next
iteration and can be removed after the driver experiment.

## Next experiment

Build or obtain the smallest ARM64 KGSL-enabled Turnip probe compatible with the Nova's
Adreno 740v2 and Android 13 kernel. First acceptance is `vulkaninfo` exposing one
physical device from inside this exact chroot; second is an offscreen Vulkan clear or
`vkcube`-equivalent. Only after that should the lab add gamescope/Wayland and the
AHardwareBuffer/SurfaceControl exchange.
