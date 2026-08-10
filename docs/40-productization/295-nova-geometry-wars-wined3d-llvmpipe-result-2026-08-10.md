# Nova Geometry Wars WineD3D/llvmpipe result — 2026-08-10

## Result

The forced WineD3D/OpenGL control did not produce a Geometry Wars frame. It
did reach the real executable and loaded `d3d9.dll`, `wined3d.dll`, and
`opengl32.dll`, but the direct process returned status `29` before a game
window was visible. No game process remained at the post-launch poll.

Unlike the earlier WineD3D/KGSL run, this attempt emitted no Mesa/Zink/GLX
renderer line at all. The rootfs DRI inventory has generic `swrast_dri.so` and
`zink_dri.so` symlinks, but no standalone `llvmpipe_dri.so` artifact was found
under the rootfs. The controlled conclusion is therefore that the current
rootfs/OpenGL provider did not establish a usable forced-llvmpipe renderer;
this is a GL-library/driver boundary, not a universal Proton or display
failure.

## Run identity and provenance

- Run ID: `nova-game-geometry-wined3d-llvmpipe-20260810T121554Z`
- Device: Retroid Pocket Nova, adb serial `675a2365`, Android 13, `kalama`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Compatibility tool: Proton 11 ARM64, wrapper SHA-256
  `b56de46d7619ebf6975a625e47c202c81baa375ca3576983e221bc9892b0633b`
- GeometryWars.exe SHA-256:
  `457340226810ea529310f17875d87201cc93635e5a375ea4b5fdb75361887129`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256:
  `7f94e8bc85717147c2c62b4438fae26a826d1132cbbec4e103c9ddad79b84229`
- APK behavior source: `e5fd23f`; repository head at run setup: `a86818e`
- Display: Termux:X11 `:0`, Android `1280x960`, stretched X11 `1280x800`
- Parent profile: `hardware_accel=1`, `cef_disable_gpu=0`,
  `steam_force_software_gl=1`, `steam_cef_env_split=1`
- Direct wrapper SHA-256:
  `7b736f24e97aa2cf9effe6b2ac4a6a688bf7abe3a49d488ccb4e2642af092097`

The direct game process added only:

```text
PROTON_USE_WINED3D=1
MESA_LOADER_DRIVER_OVERRIDE=llvmpipe
GALLIUM_DRIVER=llvmpipe
LIBGL_ALWAYS_SOFTWARE=1
LIBGL_ALWAYS_INDIRECT=0
```

`VK_ICD_FILENAMES`, `VK_IMPLICIT_LAYER_PATH`, and FROG activation were absent.

## Game evidence

The fresh Proton log recorded:

```text
Proton: 1779182345 proton-11.0-1-beta5-unstripped
Options: {'gamedrive', 'forcelgadd', 'wined3d'}
Load module GeometryWars.exe
Load module d3d9.dll
Load module wined3d.dll
Load module opengl32.dll
Load module winex11.drv
```

It contained no DXVK/Vulkan path and no positive llvmpipe/OpenGL/GLX renderer
selection. The log ended during Wine module/startup activity; the direct
wrapper returned `direct_game_status=29` and no Geometry Wars process was
present afterward.

Evidence directory:

`android/nova-lab/build/runs/nova-game-geometry-wined3d-llvmpipe-20260810T121554Z/`

- Proton log SHA-256:
  `357bd5884da4670582c857f3a73f9b9141bc26150cc872db45c9d543d249e699`
- Direct output SHA-256:
  `1619903f56f05254d534cdef3a73b870649bc159c8b5f57bca9e223eec`
- Pre-game screen SHA-256:
  `f3651a99ed70d4d5d539480f8c77cca00ac88d12d402503ba15bbd092a39df12`
- Post-game screen SHA-256:
  `2d7409a5c3f311850738c6a40ec28d9595864aa91ad4d90fc6372b66c14af4a3`

The post-game capture remained the signed-in Steam library with Geometry Wars
selected, not a game frame.

## Prefix protection and cleanup

The run took exact backups before launching. The pre-run hashes were:

```text
system.reg             5a7fba0513db2c05776d5b3de08140d2a897ca711842b74dbb475e6ad47ffa22
user.reg               1943c8d9f5b2da5e4bd9ef016c1c49f62d110a3882c67b94af60adcaa209217a
userdef.reg            a2e53741b4af39b5371308b9ab998988cbdd0ed69b377dc29c89d1a6cfa791e
proton-fex-config.json b01e8e9373cb00e1b1c0d73738883c6b620eaa645d060c52573ea196d5f372d0
```

`system.reg` and `user.reg` changed during startup, while `userdef.reg` and
the FEX configuration did not. The exact backups were copied back with owner
`501:20`; the normalized hash comparison returned `restore_compare=pass`.

Teardown returned:

```text
nova_x11_cleanup=pass
nova_runtime_cleanup=pass
exact_device_cleanup=pass
```

The final process audit was empty. The run-scoped wrapper, log, backups, and
rootfs `/tmp` directory were removed from the device.

## Decision and next step

Do not repeat the same llvmpipe environment. To make this alternate route
useful, the next experiment must stage or build an actual ARM64 Mesa software
GL provider (`llvmpipe`/`swrast`) and verify it with a small native GLX probe
before launching the game. In parallel, the DMA-BUF WSI result remains the
more promising hardware route: its next implementation question is a
Wine-facing Win32-surface adapter above the X11 layer.
