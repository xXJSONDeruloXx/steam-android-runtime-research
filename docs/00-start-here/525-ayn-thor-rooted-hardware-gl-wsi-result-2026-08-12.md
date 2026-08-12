# AYN Thor rooted hardware GL A/B and WSI boundary

Date: 2026-08-12
Status: hardware Steam/Vulkan UI path verified; game launch remains pending
because this runtime has no installed Geometry Wars payload or authenticated
Steam library
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

## Follow-up: X11-WSI rebuild and rooted hardware replay

The no-platform driver was rebuilt with X11 WSI enabled. The build used Mesa
source revision `461196a1c827769168304ff3f5b36360f16618ca` from
`https://gitlab.freedesktop.org/mesa/mesa.git`, with Meson reporting:

```text
Vulkan Drivers: freedreno
Platforms: x11 xcb
```

The build script now merges the Holo glibc sysroot with the existing aarch64
X11 sysroot and extracts the cached target `libxshmfence` package before
configuration. This matters because installing x11 development packages in
the arm64 build container does not add their target headers and libraries to
the Holo sysroot.

New artifacts:

```text
APK: android/nova-lab/build/nova-lab-debug.apk
APK SHA-256: 0dd5bc477d90ee25a9fc4e2d91a98ff93e91c1b9b3e62caaba86d92e0af88785
libvulkan_freedreno.so SHA-256: 2e5eb2f991b4991236ff67cd69745a921ec114654c635656f9d246038ed30bf5
freedreno-kgsl.icd.json SHA-256: 337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
```

Fresh rooted hardware run `20260812T172508Z-27832` used the rebuilt APK and
`steam_force_software_gl=0`. The direct client log recorded:

```text
client_hardware_accel=1
client_force_software_gl=0
client_libgl_drivers_path=/usr/lib/dri
client_tu_debug=noconform
client_mesa_vk_wsi_present_mode=mailbox
client_vk_driver_files=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
client_gl_mode=hardware
client_mesa_driver=kgsl
client_started=pass
```

Steam's own `GpuTopology` query reported `Turnip Adreno (TM) 740`,
`k_EGpuDriverId_MesaTurnip`, and driver version `25.2.7`. A same-run
mount-aware `vulkaninfo --summary` with `DISPLAY=:0` enumerated the same GPU
and exposed `VK_KHR_surface`, `VK_KHR_xcb_surface`, and
`VK_KHR_xlib_surface`. The fresh display was the Steam sign-in page, proving
the rooted hardware path reached usable Steam UI. CEF remained intentionally
software-rendered (`--disable-gpu`) under this profile.

The session was stopped with `nova_launcher_stop=pass`; final checks found no
matching Steam, webhelper, Termux:X11, relay, rootfs mount, or X11 socket.
Geometry Wars was not launched in this replay because the active runtime has
no `GeometryWars.exe`, Proton 11 ARM64 installation, or compatdata for AppID
8400. That is a separate game-payload/authentication prerequisite, not a
hardware-WSI failure.
