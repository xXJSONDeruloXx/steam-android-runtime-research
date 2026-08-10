# Nova Geometry Wars WineD3D/KGSL result — 2026-08-10

## Decision

The missing `VK_KHR_swapchain` extension is a hard blocker for the current
DXVK/Turnip/X11 presentation route, but it is not a universal blocker for
every Proton rendering path. This experiment used Proton's OpenGL-based
WineD3D path and therefore bypassed DXVK. It reached a real Geometry Wars
process, but the Nova rootfs did not produce a usable Mesa GLX screen: Mesa
selected Zink, Zink failed Vulkan physical-device initialization, and GLX
then failed to create a DRI screen. No Geometry Wars frame was displayed.

That is useful progress rather than evidence that the whole approach is
blocked. The next rendering experiment should isolate the Mesa GLX/Zink
boundary and the FEX runtime warning. Gamescope/AHardwareBuffer work can stay
parked while this route is investigated.

## Why this experiment was valid

The official Proton 11 documentation supports:

```text
PROTON_USE_WINED3D=1 %command%
```

and describes it as selecting OpenGL-based WineD3D instead of Vulkan-based
DXVK for D3D 9/10/11. Proton's renderer selection code independently confirms
that `PROTON_USE_WINED3D=1` disables the DXVK/DXGI path. This was therefore a
reasonable alternate route after the earlier Geometry Wars run reached DXVK
but failed at Nova's Vulkan surface/swapchain boundary.

References:

- [Valve Proton 11 README](https://github.com/ValveSoftware/Proton/blob/proton_11.0/README.md)
- [Valve Proton 11 renderer selection](https://github.com/ValveSoftware/Proton/blob/proton_11.0/proton)
- [FEX configuration overview](https://wiki.fex-emu.com/index.php/Development%3AConfiguring_FEX)

## Run identities

The first three attempts were discarded setup/transport runs. They are listed
so their failures cannot be confused with the authoritative game result.

| Run | Result |
| --- | --- |
| `nova-game-geometry-wined3d-kgsl-20260810T104552Z` | Steam client exited because the fresh rootfs baseline contained a stale `/run/dbus/system_bus_socket` and `/run/dbus/pid`. No game was launched. |
| `nova-game-geometry-wined3d-kgsl-20260810T104741Z` | The direct probe exited 127 because the rootfs could not resolve its `#!/usr/bin/env sh` shebang. No Proton/game process was launched. |
| `nova-game-geometry-wined3d-kgsl-retry-20260810T105306Z` | Proton reached the probe, but the run-scoped log directory was root-owned due to an invalid double-chroot setup. No game frame was produced. |
| `nova-game-geometry-wined3d-kgsl-retry2-20260810T105424Z` | **Authoritative run.** Proton launched Geometry Wars and WineD3D reached OpenGL module loading, then failed at Mesa Zink/GLX screen creation. |

The authoritative evidence is retained locally at:

```text
android/nova-lab/build/runs/nova-game-geometry-wined3d-kgsl-retry2-20260810T105424Z/
```

## Fixed device and artifact profile

- Device: Retroid Pocket Nova, adb serial `675a2365`
- Android: 13, product `kalama`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- Package: `com.xjsonderulo.steamandroid.novalab`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Executable:
  `/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe`
- Compatibility tool: Proton `proton-11.0-1-beta5-unstripped` from
  `compatibilitytools.d/proton-11-arm64`
- APK source commit at launch: `fc1c0d1`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256:
  `9cf6aa48a53aca8baef8fb60d85056926550a330e780365e79f651ab1ff17f42`
- Direct presentation: Termux:X11 display `:0`; Android surface `1280x960`;
  stretched X11 buffer `1280x800`
- Gamescope/AHardwareBuffer output: not used

The Steam parent used the already validated signed-in software-GL profile:

```text
hardware_accel=1
cef_disable_gpu=0
steam_force_software_gl=1
steam_cef_env_split=1
```

Fresh parent evidence reported `client_started=pass`, D-Bus session/system
success, and `client_gl_mode=software` with Mesa `swrast`/`softpipe`. The
launcher reported a fresh `display=:0 geometry=1280x960` readiness state and
the known input allowance for `event9`.

The direct game invocation used Proton 11 ARM64 with:

```text
PROTON_USE_WINED3D=1
MESA_LOADER_DRIVER_OVERRIDE=kgsl
VK_ICD_FILENAMES=unset
GALLIUM_DRIVER=unset
LIBGL_ALWAYS_SOFTWARE=unset
LIBGL_ALWAYS_INDIRECT=unset
```

The library path put the rootfs `/usr/lib` before the Steam runtime libraries.
The run used `PROTON_LOG=1`, a run-scoped `PROTON_LOG_DIR`, `WINEDEBUG=-all`,
and a 30-second timeout. No explicit Vulkan ICD was passed: this was an
OpenGL/WineD3D test, not another DXVK/Turnip test.

## Observed result

The direct command was:

```text
NOVA_X11_ALLOW_INPUT_EVENTS=9 \
  /data/user/0/com.xjsonderulo.steamandroid.novalab/files/launcher/nova-x11-private-namespace.sh \
  chroot-dev \
  /data/user/0/com.xjsonderulo.steamandroid.novalab/files/launcher/nova-mount-private \
  /data/local/tmp/nova-holo-rootfs \
  /usr/bin/bash \
  /tmp/direct-wined3d-kgsl-retry2-20260810T105424Z.sh
```

The command returned `adb_exit_status=29`, but the process evidence proves
that this was not a launch/quoting failure. The first process poll showed the
full Proton/Wine tree, including:

- Proton 11 ARM64 `runinprefix`
- the Proton Python wrapper
- `GeometryWars.exe`
- `wineserver`, `services.exe`, and Wine device processes

By the second poll the game process had exited and no direct game process was
left behind.

The pulled Proton log is:

```text
android/nova-lab/build/runs/nova-game-geometry-wined3d-kgsl-retry2-20260810T105424Z/proton-steam-8400.log
```

SHA-256:

```text
e90dc03ca7da48f89a2bb11f3ef8237c7950620635130497ad1128e94acd90fb
```

The important renderer sequence was:

```text
Proton: 1779182345 proton-11.0-1-beta5-unstripped
Options: {'forcelgadd', 'wined3d', 'gamedrive'}
D 24 Host CPU doesn't support atomics. Expect bad performance
D 24 Load module d3d9.dll ...
D 24 Load module wined3d.dll ...
D 24 Load module opengl32.dll ...
MESA: error: ZINK: vkEnumeratePhysicalDevices failed (VK_ERROR_INITIALIZATION_FAILED)
MESA: error: ZINK: failed to choose pdev
glx: failed to create drisw screen
```

The Zink/GLX failure sequence appeared twice. In other words, WineD3D did
load, but the requested `kgsl` OpenGL selection did not result in a usable
native GLX screen. Mesa fell into Zink, which still needed Vulkan device
initialization, and that initialization failed before a game surface could be
created. The FEX atomics message and repeated handled unaligned atomic events
are a separate runtime concern; this run does not yet prove they are the
first graphics failure.

## Frame and window evidence

The acceptance condition was a same-run Geometry Wars frame or viewable game
window, not merely a renderer log. It was not met.

- `android-screen-poll-1.png` SHA-256:
  `4bd085b23ea10922d0cc18924d6a00d0ed8f1d7f6b61cc58c018833038efb57f`
- `android-screen-poll-2.png` SHA-256:
  `36d2af46ded140fe52bc0f4bb08ef8ab429140ad8766b7e4e689615285d8fa56`
- `android-screen-after-game.png` SHA-256:
  `7b24ca1bb2d65207261458b9490e170b53dbf4bbc92d456ade04332506b38644`
- `x11-window-after-game.ppm` SHA-256:
  `f268a989b990b68ae97e2c95377b1862c6f9fa4deac9cb39c94b53c0b630b225`

All captures remained the signed-in Steam Store/Friends UI. The Friends
window showed the Geometry Wars title as Steam client state, not a Geometry
Wars game window. The X11 tree contained the viewable Steam window at
`1280x800` and the Friends List window, with no separate Geometry Wars frame.

## Restore and cleanup

The game changed `system.reg` and `user.reg` in the AppID-8400 prefix. Before
launch, their hashes were:

```text
system.reg  db3c4a5fe2daee62721d51cb2092a9684d0522dc2dfcda0bfcbddbf2f7bc12aa
user.reg    c3ecf12382e983010c65c4d9f159973a94ddd53ba1ca76f4de3431d75a10ed87
```

The known-good copies were restored after the run. The final hashes matched
those baseline values; `userdef.reg` and `proton-fex-config.json` also matched
their pre-run hashes. No game files, Proton package, account state, or
persistent launch option was removed.

The launcher stopped with the expected bounded-session `adb_exit_status=143`.
Its log recorded `nova_launcher_x11_stretch_restore=pass`; the launcher did
not emit its normal `nova_launcher_stop=pass` marker because the stop ancestry
also terminated the start wrapper. The exact runtime cleanup helper completed
with `nova_runtime_cleanup=pass`, and the settled final process audit found no
Nova, Steam, Wine, FEX, Geometry Wars, D-Bus, mount, bridge-socket, or launcher
residual. The X11 stretch preference hash returned to its known baseline.

## Follow-up

1. Keep the AHB/Gamescope investigation parked; this result does not justify
   treating `VK_KHR_swapchain` as a universal game blocker.
2. Run a separately predeclared WineD3D graphics experiment that forces Mesa
   `llvmpipe`/`swrast` without the prior Steam-client software-GL settings, so
   we can separate “WineD3D can create a GLX context” from “Nova's native
   KGSL GLX path works.”
3. In a separate run, inspect the rootfs Mesa driver files, GLX vendor data,
   and Zink selection to determine why `MESA_LOADER_DRIVER_OVERRIDE=kgsl` did
   not reach a usable KGSL GL screen. Do not call that path hardware success
   until a fresh game frame proves it.
4. Treat the FEX host-atomic warning as a second axis. First establish a
   working GL context, then compare the same game under an alternate FEX
   configuration/runtime so renderer and emulation failures are not conflated.
5. Once a real frame exists, test another small library title. A different
   game before this GLX boundary is fixed would mostly repeat startup failure,
   not answer whether the rendering route works.
