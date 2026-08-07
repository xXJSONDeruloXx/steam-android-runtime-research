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

The base Holo rootfs was extended with an 18-package closure resolved from its current
core/extra aarch64 databases. The closure includes `vulkan-tools`,
`vulkan-freedreno`, `vulkan-headers`, `vulkan-icd-loader`, `vulkan-mesa-device-select`, `libdrm`, and
their X11/Wayland/SPIR-V dependencies. Package files are downloaded with SHA-256
verification by `fetch-holo-packages.py`, then installed by pacman inside the chroot.
The installer also extracts the Vulkan headers and loader package into the ignored
host rootfs so the checked-in ARM64 probe can be rebuilt against the same userspace;
the device copy is still installed by pacman.

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

## Vulkan result: stock Holo control

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

## KGSL Turnip result

Mesa 25.2.7 was built from the official `mesa-25.2.7` source tag with the minimal
configuration used by `android/nova-lab/build-kgsl-turnip.sh`:

```text
-Dvulkan-drivers=freedreno
-Dfreedreno-kmds=kgsl
-Dplatforms=[]
-Dgallium-drivers=[]
```

The resulting ARM64 glibc driver was staged at
`/opt/nova-kgsl-driver/libvulkan_freedreno.so` without replacing Holo's stock driver.
Its SHA-256 for this run was:

```text
37e18fc67fc5e08c01ba380d9c0a97398b0e8957d829d345e5f4ca40c98938b2
```

After restoring the disposable host staging and rerunning the same checked-in build,
the driver repeated the result with this current artifact hash:

```text
a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
```

The build script does not yet pin the Docker image or compiler package digests, so the
artifact hash is evidence for the tested binary, not a stable content-addressed
release identifier.

Selecting its ICD manifest changed the result from “no valid GPUs” to a real physical
device:

```text
vulkan_icd_file=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
GPU0:
        deviceName         = Turnip Adreno (TM) 740
        driverID           = DRIVER_ID_MESA_TURNIP
        driverInfo         = Mesa 25.2.7
vulkaninfo_status=0
```

The lab then ran a small native ARM64 C program compiled against the same Holo Vulkan
headers and loader. It created a device and queue, allocated host-visible memory,
submitted `vkCmdFillBuffer`, waited for a fence, and mapped the result:

```text
device=Turnip Adreno (TM) 740
fill_value=0xc0dec0de
offscreen_fill=pass
offscreen_probe_status=0
probe_status=0
```

The same probe then exercised the external-memory handoff needed by a compositor:

```text
extension.VK_KHR_external_memory=present
extension.VK_KHR_external_memory_fd=present
extension.VK_EXT_external_memory_dma_buf=present
dma_buf_fd_target=/dmabuf:
dma_buf_export=pass
imported_fill_value=0xc0dec0de
dma_buf_import=pass
```

The first Vulkan allocation was exported through `vkGetMemoryFdKHR` as a real Linux
DMA-BUF FD. A second Vulkan buffer imported that FD and read back the value written by
the GPU before export. This is still a same-process/same-driver interoperability test;
it does not yet prove Android `AHardwareBuffer` import, SurfaceControl, fences, or
cross-process lifetime management.

This is the first proof in this repository that a native Linux Vulkan command reaches
the Nova's Adreno GPU from the Android-rooted Holo namespace. It is still an offscreen
transfer-style boundary test; no display surface, Wayland compositor,
AHardwareBuffer import/export, or Steam process is involved.

## What this proves

- A fixed ARM64 glibc rootfs can execute natively inside the rooted Android namespace.
- Holo package metadata and pacman can be used reproducibly without installing into
  Android's read-only system partitions.
- The standard Holo Vulkan userspace is a useful failing control because it does not
  bridge Nova's KGSL GPU into a Linux Vulkan physical device.
- A KGSL-enabled Turnip build does bridge the GPU and can submit a verified command
  buffer from native ARM64 glibc.
- Vulkan external-memory extensions can export/import a real DMA-BUF while retaining
  GPU-written contents, so the Linux-side buffer handoff contract is now proven.
- The companion Android probe now proves the next lower-level boundary as well: an
  Android `AHardwareBuffer` handle can cross into Holo as DMA-BUF FDs and be written by
  Linux Turnip, with Android reading the result back. The visible compositor path,
  gamescope, Wayland, Steam, and FEX remain unproven.

It does **not** yet prove that Steam can run, that a KGSL-enabled driver can initialize,
or that a Linux compositor can export frames to the Android app. The disposable Holo
rootfs and package staging directories remain under `/data/local/tmp` for the next
iteration and can be removed after the driver experiment.

## Next experiment

The Linux-rendered RGBA image-memory handoff now passes through the Android companion
probe. The next acceptance target is to present that image through the existing
Android `Surface`, with explicit acquire/release fences and frame pacing. That should
become the smallest compositor-shaped loop before adding Wayland, gamescope, SteamRT3C,
the native ARM64 Steam client, input, and lifecycle management.
