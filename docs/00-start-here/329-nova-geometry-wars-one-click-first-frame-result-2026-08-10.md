# Nova one-click Geometry Wars Proton 11 first-frame result — 2026-08-10

## Result

The fresh one-click parent session reached the authenticated Steam Big Picture
library, but Geometry Wars did not produce a first game frame. The corrected
game launch reached the real `GeometryWars.exe` through the Holo glibc Proton
11 ARM64 path, copied and initialized a run-scoped prefix, selected DXVK mode,
loaded native `d3d9.dll`, and selected the explicit Turnip ICD. It then entered
a repeated FEX/Wine null-address exception sequence and timed out at the
60-second game bound.

This is not a valid Win32-surface, swapchain, Gamescope, or Android
AHardwareBuffer failure. The fresh bounded evidence does not show
`winevulkan.dll`, a DXVK instance, `VK_KHR_win32_surface`, surface creation,
swapchain creation, or present. The furthest defensible classification is
**pre-WSI game/runtime startup after D3D9 dispatch: FEX/Wine exception storm**.

The earlier explicit native-override result remains the deeper Vulkan control:
it proved the chain through DXVK and WineVulkan to `VK_KHR_win32_surface`, then
failed at Vulkan instance creation in [250](../30-runtime-and-games/250-nova-geometry-wars-proton11-dxvk-nativeoverride-result-2026-08-10.md).
This one-click run did not reproduce that deeper boundary, so it must not be
used to claim that the Win32-to-X11 adapter is fixed or disproved.

## Run identity and provenance

- Run ID:
  `nova-game-geometry-wars-one-click-first-frame-20260810T161132Z`
- Source commit at predeclaration:
  `7bbe834a2b6b51440f928b4bee8f0dba6daa157b`
- Device: Retroid Pocket Nova, Android 13, `kalama`, adb serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Game executable:
  `/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe`
- GeometryWars.exe SHA-256:
  `457340226810ea529310f17875d87201cc93635e5a375ea4b5fdb75361887129`
- Proton tool:
  `/opt/nova-steam/home/.local/share/Steam/compatibilitytools.d/proton-11-arm64/proton`
- Proton tool SHA-256 on device:
  `b56de46d7619ebf6975a625e47c202c81baa375ca3576983e221bc9892b0633b`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256:
  `0d3020eb0ba8d0fa09b168f85ba088ad3cc08932a7ad36c76bad0ab4b69f5d97`
- Host game wrapper:
  `android/nova-lab/device/nova-proton-glibc-geometry-wars.sh`
- Host wrapper SHA-256:
  `f4ebb21105a8af5876a2ed11cf06a3b8db2d11ee4d0bd537d63ce5510cf80848`
- Corrected run launcher SHA-256:
  `635638307a514d12e999d9a18856043e4d0bd8a994c0e4b8795521abdeb3da1e`
- Holo runtime path:
  `steamrtarm64` with the installed SteamRT3C ARM64 platform tree
- Parent display: fresh Termux:X11 `:0`, Android `1280x960`, X11 `1280x800`
- Vulkan ICD:
  `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`
- Game WSI layer: disabled; `VK_IMPLICIT_LAYER_PATH` unset

The host evidence is retained under:

`android/nova-lab/build/runs/nova-game-geometry-wars-one-click-first-frame-20260810T161132Z/`

The full Proton trace was intentionally not retained on the device after
bounded extraction: `WINEDEBUG=+loaddll,+seh` grew the run-scoped log to
`31,728,656,384` bytes. The exact run tree was removed after preserving the
small selected excerpts, screenshots, process polls, prefix hashes, and
cleanup records.

## Lifecycle and parent-session gate

The Nova lifecycle contract in [34](34-nova-runtime-harness-lifecycle.md) was
read in full immediately before the device launch. The preflight found the
attached Nova and no matching active Nova session after the exact cleanup
helper. The visible APK `Start Steam` button was tapped; no diagnostic launch
extras were supplied.

The first readiness read matched an older marker from a previous session. It
was rejected rather than used as evidence. Fresh process and session checks
identified the current launcher session as `20260810T162228Z-30044`, with:

```text
nova_launcher_hardware_accel=1
nova_launcher_vulkan_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
nova_launcher_cef_disable_gpu=1
nova_launcher_steam_ui_mode=gamepadui
nova_launcher_steam_disable_preload=0
nova_launcher_steam_disable_system_dbus=0
nova_launcher_steam_holo_mesa_first=0
nova_launcher_steam_force_software_gl=1
nova_launcher_steam_cef_env_split=1
nova_launcher_audio_bridge=1
nova_launcher_gamepad=pass
nova_launcher_input_allow=event9
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The fresh parent screenshot shows the authenticated Steam Big Picture library
with Geometry Wars selected. Its SHA-256 is
`d5f93de8e3b1bc691fc8cc00195d7b43b9a4e916fec84e4792fdf57440408048`.

The baseline X11 tree showed a viewable `Steam Big Picture Mode` window
`0x1800035` at `1280x800`; its artifact SHA-256 is
`63d21a448d532e24219317224a33b6930dd34a50069b87c89d6b70b59dc17b2a`.

## Controlled game launch

The parent profile remained fixed. The only intended change was the direct
AppID-8400 game child, using the existing wrapper in `dxvk` mode and Proton's
normal `run` action:

```text
SteamAppId=8400
SteamGameId=8400
STEAM_COMPAT_CLIENT_INSTALL_PATH=/opt/nova-steam/home/.local/share/Steam
STEAM_COMPAT_DATA_PATH=/tmp/<run-id>/compatdata/8400
PROTON_USE_WINED3D=0
WINEDLLOVERRIDES=d3d11=n;d3d10core=n;d3d9=n;dxgi=n
VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
VK_IMPLICIT_LAYER_PATH=unset
MESA_LOADER_DRIVER_OVERRIDE=unset
GALLIUM_DRIVER=unset
LIBGL_ALWAYS_SOFTWARE=unset
PROTON_LOG=1
PROTON_LOG_DIR=/tmp/<run-id>/proton-log
DXVK_LOG_LEVEL=info
DXVK_LOG_PATH=/tmp/<run-id>/dxvk-log
VK_LOADER_DEBUG=error,warn,driver
WINEDEBUG=+loaddll,+seh
```

Two launch-wrapper corrections occurred before Proton was reached:

1. The first script did not quote the Geometry Wars path, so the space split
   the executable into `Wars/GeometryWars.exe`. No game process or prefix
   mutation resulted.
2. The second attempt passed the Android-visible run path into the chroot,
   where it did not exist. The corrected script staged the wrapper at the
   chroot-visible `/tmp/<run-id>/` path. No Proton process or prefix mutation
   resulted.

The authoritative retry recorded:

```text
mount_private=pass path=/
x11_namespace_input=pass allowed_events=9 hidden_events=
nova_glibc_proton=pass mode=dxvk run_id=nova-game-geometry-wars-one-click-first-frame-20260810T161132Z
nova_glibc_proton_setup=proton_run
nova_glibc_proton_renderer=dxvk
nova_glibc_proton_wined3d=0
nova_glibc_proton_software_gl=unset/unset
nova_glibc_proton_audio=enabled
nova_glibc_proton_winedlloverrides=d3d11=n;d3d10core=n;d3d9=n;dxgi=n
nova_glibc_proton_vk_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
nova_glibc_proton_wsi_layer=disabled
nova_glibc_proton_vk_implicit_layer_path=unset
Proton: Upgrading prefix from None to 11.0-100 (.../compatdata/8400/)
```

The copied run prefix generated Proton's `tracked_files`, `version`, and
`config_info` bookkeeping. The persistent AppID-8400 prefix was not the write
target. Its protected hashes before and after remained:

```text
system.reg   5a7fba0513db2c05776d5b3de08140d2a897ca711842b74dbb475e6ad47ffa22
user.reg     1943c8d9f5b2da5e4bd9ef016c1c49f62d110a3882c67b94af60adcaa209217a
userdef.reg  a2e53741b4af39b5371308fb9ab998988cbdd0ed69b377dc29c89d1a6cfa791e
proton-fex-config.json
             b01e8e9373cb00e1b1c0d73738883c6b620eaa645d060c52573ea196d5f372d0
```

The run copy changed as expected during Proton setup; it was deleted with the
run tree after evidence extraction.

## First-frame evidence

The bounded game wrapper returned status `124` after its 60-second lifetime.
Twelve display captures were taken from `16:30:03Z` through `16:30:32Z`.
Every Android capture remained the Steam library. The final X11 tree still
contained only the viewable `Steam Big Picture Mode` window at `1280x800`; the
only new game-shaped object was a viewable `1x1` unnamed window at `(-1,-1)`.
There was no viewable Geometry Wars window and no changed game-pixel region.

Selected evidence hashes:

- `android-game-01.png`:
  `05e6defe258f68117d072d695d3e56c5b0d21b5bd90c37245723929767cf0feb`
- `android-game-12.png`:
  `f6c42785f44cfbeb18d26bfd0ab35c58f52eff44360200829e614ddf57cf41ed`
- `x11-tree-game-01.txt`:
  `d37418aa3bc77d4de22d87ffd88365c6f896ff4427d36dba4b052540c90f812b`
- `x11-tree-game-12.txt`:
  `578cb518dd5b9934c3298f1993cc5077ae3c6691e0eb659bc3e6f4ac35840eca`
- `game-output-01.txt`:
  `45957aa98d4ebd6e5e7f364b6e7ef8d05213456f01803255f523000e5b54ab10`
- `game-output-12.txt`:
  `ff8994f67384c472715f09bd40fe8192bae7b5ea8235a105f9f4552c12aabc4a`

## Vulkan/WSI classification

The selected fresh Proton evidence records:

```text
Command: [.../Geometry Wars/GeometryWars.exe]
Options: {'gamedrive', 'forcelgadd'}
System/Effective WINEDLLOVERRIDES: d3d11=n;d3d10core=n;d3d9=n;dxgi=n
```

The bounded loader excerpt then records the explicit ICD search and Turnip
selection:

```text
DEBUG | DRIVER: Searching for ICD drivers named /opt/nova-kgsl-driver/libvulkan_freedreno.so
INFO | DRIVER: [0] Turnip Adreno (TM) 740
DRIVER | LAYER: Using "Turnip Adreno (TM) 740" with driver: "/opt/nova-kgsl-driver/libvulkan_freedreno.so"
...
D 120 Load module GeometryWars.exe ... native
D 120 Load module d3d9.dll ... native
```

The first repeated failure captured in the bounded Proton trace is:

```text
00e4:trace:seh:handle_syscall_fault code=c0000005 flags=0 addr=(nil) pc=0x77fef97c80 tid=00e4
00e4:trace:seh:handle_syscall_fault returning to user mode ip=0x6ffe72c8d4 ret=c0000005
```

The same sequence repeats through the tail of the extracted trace. The
selected bounded excerpts contain no fresh line proving `winevulkan.dll`, `vkGetInstanceProcAddr`,
`VK_KHR_win32_surface`, `vkCreateInstance`, `vkCreateSwapchainKHR`, or a
present. The run-scoped DXVK log directory was empty. Therefore:

- Vulkan ICD discovery/driver selection **passed far enough to identify
  Turnip**; this is not a “no ICD found” result.
- DXVK mode and native D3D9 dispatch were selected, but successful DXVK or
  WineVulkan instance initialization was **not proven** in this run.
- Win32-surface WSI and swapchain/present were **not reached or not
  observable**. This run cannot classify either as the first failure.
- The first defensible failing boundary is **pre-WSI game/runtime startup in
  the FEX/Wine exception path**, after executable/D3D9 dispatch and ICD
  selection.

The selected evidence hashes are:

- `proton-selected-log-evidence.txt`:
  `fbcbb1f97af8fa421210d60b7afd4d14ad6059a5b89cf355499b3c87985c4c05`
- `proton-early-selected.txt`:
  `3b7cb7f03f445009221b1bba6f01df1f2ab07ffb693165d55a2cee8d58827431`
- `proton-early-focus.txt`:
  `20fd4646604c9f9e824d46648d4bb1eb1beda77cf4df70034efc24d6d2349f14`
- `proton-log-tail.txt`:
  `46834970435971999528f8737fc2b62b202b7293428dc13208bb8a424012c3de`

## Cleanup and storage

The child `wineserver` and `winedevice.exe` processes were captured after the
timeout and terminated by their exact observed PIDs. The parent was then
stopped through the exact one-click path. The stop log emitted:

```text
nova_launcher_x11_stretch_restore=pass
nova_launcher_cleanup_exclude_pids=7500 7499 1032
nova_launcher_dbus_state=absent
nova_launcher_stop=pass
```

The outer stop command reported exit `137` after those pass markers; the
final targeted Nova-process audit was empty, and no live rootfs D-Bus socket or
APK-owned temporary file remained. The rootfs retained only unrelated stale
historical session log directories; those were not broadly deleted.

The following exact disposable paths were removed after evidence extraction:

```text
/data/local/tmp/nova-holo-rootfs/tmp/nova-game-geometry-wars-one-click-first-frame-20260810T161132Z
/data/local/tmp/nova-game-launch.sh-host
/data/local/tmp/nova-x11-capture-host
/data/local/tmp/nova-holo-rootfs/tmp/nova-x11-capture
/data/local/tmp/nova-holo-rootfs/tmp/nova-x11-capture-run/nova-game-geometry-wars-one-click-first-frame-20260810T161132Z-baseline.ppm
```

This reclaimed approximately 31 GB of run-scoped storage. No source,
persistent prefix, installed game, Proton tool, or application asset was
removed.

## Decision and next step

Do not advance to full OOBE packaging or embedded X11 on the basis of this
run. The parent Steam display path remains healthy, but the first-game-frame
gate is still closed and this run does not move the WSI boundary deeper.

The next useful experiment should be separately predeclared from this same
one-click parent, with the same game, prefix copy, ICD, Proton tool, and
rendering variables, but bounded logging (`+loaddll` without `+seh`) so the
diagnostic setting cannot create another multi-gigabyte exception trace. Its
sole question should be whether the game reaches the prior known DXVK/
WineVulkan/`VK_KHR_win32_surface` sequence. If it does, resume the narrow
Wine-facing Win32-surface investigation. If it repeats the pre-WSI exception
storm, investigate the FEX/Wine game startup boundary before changing
Gamescope, AHardwareBuffer, or Android packaging.
