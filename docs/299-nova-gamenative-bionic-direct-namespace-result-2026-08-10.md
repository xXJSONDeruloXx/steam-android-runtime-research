# Nova GameNative Bionic direct-namespace result — 2026-08-10

## Result

The GameNative Bionic runtime boundary is real and the first gate passed:
GameNative Proton `11.0-1-arm64ec` started as `wine-11.0` through Android's
`/system/bin/linker64` with the official Bionic imagefs and the expected
`libandroid-sysvshm.so`, `libevshim.so`, and `libredirect-bionic.so` preload
chain.

The Geometry Wars launch did not reach Wine, DXVK, Vulkan, or the game frame in
this direct-namespace control. Two separate launch identities explain why:

1. running the direct Bionic process as root reached Wine, but Wine rejected
   the prefix because a root process is not the prefix owner; and
2. running as Android's non-root `shell` UID avoided the root check, but
   Android's linker namespace rejected the `/data/local/tmp` preload library
   path before the timeout binary could start.

This is useful progress rather than a rendering verdict. GameNative runs from
its application-private files directory, where its Bionic linker namespace can
load the imagefs and native libraries. The next control must reproduce that
namespace or use a private mount adapter that presents the Android system
trees while dropping to a non-root UID before invoking the Bionic linker.

## Run identity and provenance

- Run ID:
  `nova-game-gamenative-bionic-geometry-wars-20260810T131000Z`
- Device: Retroid Pocket Nova, adb serial `675a2365`, Android 13, `kalama`
- Persistent rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Fresh parent: one-click LauncherActivity, hardware acceleration enabled,
  CEF GPU enabled, software GL forced for Steam CEF, split CEF environment
- Display: Termux:X11 `:0`, Android `1280x960`, stretched X11 `1280x800`
- GameNative source revision:
  `4c3269c63851849fbe16e462733494755ce47524`
- WinNative source revision:
  `89daef3bc5693762868b2254054b47f4cdf27edf`
- GameNative Proton Wine revision:
  `147d88ee0c4eee8b356110dd0c53cc44b7515f73`
- Proton WCP SHA-256:
  `be248bf8baf354c4426f997605c6b78debbc93b091a3be3339c1bbc2176b596f`
- Bionic imagefs SHA-256:
  `368db62bfc58b72c97e5169bda9aa64d4246f07964c447e27c79a065e7e9c48b`
- Bionic imagefs: 183506500 bytes compressed, 841.6 MiB uncompressed
- `libredirect-bionic.so` SHA-256:
  `a6a0ee59bac93112f84bf75994def7607a278e8cb011a6e23414cb0107abc2cd`
- WSI layer SHA-256:
  `895a6dc9dc63e5778c0171fc56cdcb7e565a0f99c137c137073cb5ce8693b24a`
- WSI manifest SHA-256:
  `31758fb210e73e1ecd7460c9ec413e8eab6a7281b0ba847cd351af79f17f742a`

The run was predeclared in
[`docs/298-gamenative-bionic-runtime-predeclaration-2026-08-10.md`](298-gamenative-bionic-runtime-predeclaration-2026-08-10.md).

## Fresh display and Vulkan control

The parent session emitted:

```text
nova_launcher_gamepad=pass
nova_launcher_input_allow=event9
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The fresh native Vulkan probe returned status `0`. The exact WSI layer again
provided the X11 surface extensions and the bridge-level device swapchain:

```text
VK_KHR_xlib_surface                    : extension revision 1
GPU id = 0 (Turnip Adreno (TM) 740)
VK_KHR_swapchain  : extension revision 70
```

The loader also repeated the existing lower-level fact:

```text
vkCreateDevice extension VK_KHR_swapchain not available for devices associated with ICD /opt/nova-kgsl-driver/libvulkan_freedreno.so
```

This run therefore does not claim that the ICD-side swapchain problem is
fixed. It confirms that the GameNative Bionic ABI gate can be tested against
the same X11/WSI control.

Evidence:

- Native probe:
  `android/nova-lab/build/runs/nova-game-gamenative-bionic-geometry-wars-20260810T131000Z/native-probe.txt`
- Native probe SHA-256:
  `27adf1668a2d072ee297ed6f1e37ff5829899ef936ed36829d6cf0d59fec9260`
- Native probe status: `0`

## Bionic smoke gate

The corrected direct wrapper used Android's linker, the run-scoped imagefs,
the WCP, the known-good WSI layer, and this environment shape:

```text
DISPLAY=unix:/data/local/tmp/nova-holo-rootfs/tmp:0
HODLL=libwow64fex.dll
LD_LIBRARY_PATH=<imagefs>/usr/lib:/system/lib64:<WCP>/lib:<WCP>/lib/wine/aarch64-unix
LD_PRELOAD=<imagefs>/usr/lib/libandroid-sysvshm.so:<run>/libevshim.so:<imagefs>/usr/lib/libredirect-bionic.so
```

The smoke gate returned `0` and printed:

```text
gamenative_bionic=pass mode=smoke run_id=nova-game-gamenative-bionic-geometry-wars-20260810T131000Z
wine-11.0
```

Evidence:

- Wrapper source:
  [`android/nova-lab/device/nova-gamenative-bionic-geometry-wars.sh`](../android/nova-lab/device/nova-gamenative-bionic-geometry-wars.sh)
- Smoke output:
  `android/nova-lab/build/runs/nova-game-gamenative-bionic-geometry-wars-20260810T131000Z/bionic-smoke-output-5.txt`
- Smoke output SHA-256:
  `c5731b13a1e798c0fc387afc53675d5da705d8d302ee19c14733d09f8bc9acb7`
- Smoke status: `0`

The first smoke invocation also caught and corrected an omitted
`libredirect-bionic.so` staging file. The later smoke gate passed with the
complete preload chain; that staging correction is not treated as a runtime
failure.

## Game launch boundaries

### Root process

The first game attempt used the direct Bionic wrapper as root. Android's
linker and the preload chain initialized, but Wine stopped before creating a
Wine process tree:

```text
wine: '/data/local/tmp/nova-holo-rootfs/opt/nova-steam/home/.local/share/Steam/steamapps/compatdata/8400/pfx' is not owned by you
```

Status: `1`. Evidence:

- Output:
  `android/nova-lab/build/runs/nova-game-gamenative-bionic-geometry-wars-20260810T131000Z/bionic-game-output.txt`
- Output SHA-256:
  `5cc37316dbfe06be2701253a8b47fd8de729c737b20d1cd76fbde8e39fa56134`

### Non-root shell process

The second game attempt used Android UID 2000 and a run-scoped copy of the
371 MiB AppID 8400 prefix. It avoided Wine's root-owner check, but the Android
linker namespace could not load libraries staged below `/data/local/tmp`:

```text
CANNOT LINK EXECUTABLE "/system/bin/mkdir": library "<run>/imagefs/usr/lib/libandroid-sysvshm.so" not found: needed by main executable
CANNOT LINK EXECUTABLE "<run>/imagefs/usr/bin/timeout": library "<run>/imagefs/usr/lib/libandroid-sysvshm.so" not found: needed by main executable
```

Status: `1`. No Wine, DXVK, Vulkan, or Geometry Wars process was created.
Evidence:

- Output:
  `android/nova-lab/build/runs/nova-game-gamenative-bionic-geometry-wars-20260810T131000Z/bionic-game-output-shelluid.txt`
- Output SHA-256:
  `9057b790dc2fbbe9f0e27e6f617d8517311d1869c5ee68c1e31ec32a0afb445f`

The run-scoped prefix copy was discarded with the rest of the staging; the
persistent prefix was never chowned.

## Prefix, screen, and cleanup evidence

The persistent AppID 8400 files were identical before and after the direct
attempts:

```text
system.reg             5a7fba0513db2c05776d5b3de08140d2a897ca711842b74dbb475e6ad47ffa22
user.reg               1943c8d9f5b2da5e4bd9ef016c1c49f62d110a3882c67b94af60adcaa209217a
userdef.reg            a2e53741b4af39b5371308fb9ab998988cbdd0ed69b377dc29c89d1a6cfa791e
proton-fex-config.json b01e8e9373cb00e1b1c0d73738883c6b620eaa645d060c52573ea196d5f372d0
```

The before and after prefix evidence files have the same SHA-256:
`075f9d9214b590419927f0ba3ac131937ee3539e3eb07ee562c8564b2929ef11`.

The screen captures were collected at fresh run points and remained Steam
session evidence; there was no game process to produce a Geometry Wars frame:

- Fresh parent screen SHA-256:
  `e2a878ad13b3d50068093f10cd9ee0bd4af610072b2120cdf9348986386d5d15`
- Pre-game screen SHA-256:
  `024dc3e7bb07c707ad39294c00b82c2fb50131b8b3249fb62818aef99b3a55cc`
- After direct failures screen SHA-256:
  `8dc48da0b402e878116c53bc82fb462931a93def8c75ff1a97612ad6eff7171d`

The launcher’s exact root-side stop returned:

```text
nova_launcher_x11_stretch_restore=pass
nova_launcher_stop=pass
```

The exact run directory under
`/data/local/tmp/nova-holo-rootfs/tmp/` and all top-level staging files were
removed after evidence capture. No matching Nova, Steam, Gamescope, or Wine
process remained in the final audit.

## Decision and next control

Do not treat this result as a Proton or game-rendering failure. It closes only
the naive direct invocation as root/shell from `/data/local/tmp`.

The next predeclared control will keep the Bionic imagefs and Android linker,
but provide the process with a private namespace that binds the Android
`/system`, `/vendor`, `/apex`, `/product`, `/odm`, `/linkerconfig`, `/dev`, and
`/proc` trees into the existing rootfs, then uses the rootfs `setpriv` helper
to drop to UID 2000 before invoking `/system/bin/linker64`. That isolates the
linker namespace limitation while preserving Wine's non-root prefix check and
the X11 socket at the chroot's existing `/tmp/.X11-unix/X0` path.

If that adapter reaches DXVK, the next classification point is Vulkan/WSI;
if it reaches Wine but not DXVK, the evidence will identify the Wine/FEX or
prefix boundary instead.

