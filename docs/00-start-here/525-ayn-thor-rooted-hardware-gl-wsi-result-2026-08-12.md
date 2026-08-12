# AYN Thor rooted hardware GL A/B and WSI boundary

Date: 2026-08-12
Status: hardware GL not yet accepted; Vulkan offscreen enumeration passes and
the Steam hardware-GL client crashes before usable UI
Branch: `feat/rooted-games-hw-accel`
Source commit before this record: `c94be7b1e6a748b527c242b41eb306d1c72b0e1b`

## Scope and provenance

Device:

```text
serial: d234a848
model: AYN Thor
product/device: kalama
Android: 13
root: uid=0(root), context=u:r:magisk:s0
bootloader: unlocked
active rootfs: /data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
```

The APK was built from the branch above at:

```text
android/nova-lab/build/nova-lab-debug.apk
sha256: 728cad5847e6b339d8c84b7b8fe4675ece8b0334faf4e5d25844f0ef690ffa5c
```

The active rooted driver artifacts were verified against the built assets:

```text
libvulkan_freedreno.so
  a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json
  337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
```

The sibling prior-art checkout was clean at
`8d14c10195b34fe2714ba59df1680df27a852532`. Its working profile keeps CEF
software-rendered while selecting a private Turnip stack for Vulkan, and
supplies `LIBGL_DRIVERS_PATH`, `MESA_LOADER_DRIVER_OVERRIDE=kgsl`,
`TU_DEBUG=noconform`, and `MESA_VK_WSI_PRESENT_MODE=mailbox`.

## Runs

Both runs used the same rooted direct Termux:X11 path, `:0`, gamepadui,
`hardware_accel=1`, `cef_disable_gpu=1`, `steam_cef_env_split=1`, system D-Bus,
audio bridge, and `VULKAN_SELECTOR=driver-files`. The only A/B variable was
`steam_force_software_gl`.

Control run `20260812T164308Z-26225`:

```text
steam_force_software_gl=1
launcher_ready=pass
Steam reached the rooted sign-in/OOBE screen
Steam webhelper flags included --disable-gpu-compositing and --disable-gpu
GPU report: SwiftShader / disabled_software
```

Hardware run `20260812T164555Z-29048`:

```text
steam_force_software_gl=0
client_gl_mode=hardware
client_vk_driver_files=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
launcher_ready=pass
client_started=pass
client_status=139
Steam stderr: Segmentation fault
```

The Steam process exited before a usable UI. The launcher cleanup removed the
runtime and D-Bus processes; the X11 cleanup reported a stale server-parent
state after the child had already exited, so this run is not an acceptance
result.

## Isolated Vulkan probe

Using the same active rootfs, driver, rooted namespace, private X11 helper,
`VK_DRIVER_FILES`, and the sibling Mesa environment, the bundled SteamRT
`vulkaninfo --summary` enumerated:

```text
GPU0
apiVersion: 1.4.318
deviceName: Turnip Adreno (TM) 740
driverID: DRIVER_ID_MESA_TURNIP
driverInfo: Mesa 25.2.7
```

This proves the KGSL device, ICD, loader, and Turnip device enumeration path.
It does not prove X11 presentation or Steam UI hardware rendering.

## Cause boundary and next hypothesis

The checked-in Turnip build command currently passes:

```text
-Dplatforms=[]
```

That is an explicit no-platform build. The hardware Steam A/B therefore
exercises an offscreen-capable Vulkan driver, while the Steam/ANGLE path needs
X11 WSI extensions such as `VK_KHR_surface` and `VK_KHR_xcb_surface`. The next
artifact must be a separately hashed KGSL Turnip build with X11 WSI enabled,
plus the sibling's narrow Mesa environment, before another Steam hardware A/B.

Do not treat the current `ready=pass`, direct Vulkan enumeration, or the
software control as proof of hardware-accelerated Steam UI or game rendering.
