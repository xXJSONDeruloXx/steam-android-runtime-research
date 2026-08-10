# Nova CEF child-environment split result — 2026-08-10

## Decision

The child-environment split did not produce hardware-accelerated CEF
rendering, but it did prove that the software GL environment can be changed at
the `steamwebhelper` process boundary without breaking the direct Steam
client’s visible desktop. The fresh CEF reports changed from the previous
forced `ANGLE (Mesa, softpipe, ...)` result to Mesa `llvmpipe` and a
SwiftShader fallback. CEF still reported Vulkan disabled, the GPU process
continued to crash, and no Nova hardware renderer was selected.

This is a negative hardware-rendering result, not a display failure. Direct
Termux:X11 remained hardware-backed through Android Adreno EGL, and fresh
X11/Android captures showed the signed-in Steam Store and Friends window.

The earlier `VK_KHR_surface`/`VK_KHR_swapchain` finding must be scoped to the
DXVK/Turnip Vulkan presentation route. It is not a claim that every Windows
game is impossible. Proton officially supports `PROTON_USE_WINED3D=1`, which
selects OpenGL-based WineD3D instead of Vulkan-based DXVK for D3D9/D3D10/D3D11
games. The next game experiment therefore moves to Geometry Wars through
WineD3D/OpenGL rather than reopening the Gamescope-to-AHardwareBuffer path.

## Run identity and provenance

- Run ID: `nova-cef-child-env-split-20260810T103157Z`
- Device: Retroid Pocket Nova, adb serial `675a2365`
- Android: 13, product `kalama`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- Package: `com.xjsonderulo.steamandroid.novalab`
- Source commit at launch: `69855a0`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- APK SHA-256: `9cf6aa48a53aca8baef8fb60d85056926550a330e780365e79f651ab1ff17f42`
- Evidence directory:
  `android/nova-lab/build/runs/nova-cef-child-env-split-20260810T103157Z/`
- Presentation: direct Termux:X11, `:0`, X11 `1280x800` stretched into the
  Android `1280x960` surface
- Gamescope/AHardwareBuffer output: not used
- Game launch: none
- Input/audio: not tested

The exact launch profile was:

```text
hardware_accel=1
cef_disable_gpu=0
steam_force_software_gl=1
steam_cef_env_split=1
client_gl_mode=software
client_mesa_driver=swrast
client_gallium_driver=softpipe
client_libgl_always_software=1
client_vk_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
```

The APK contained the ARM64 `libnova-cef-env-split.so` preload. It filters
`MESA_LOADER_DRIVER_OVERRIDE`, `GALLIUM_DRIVER`, `LIBGL_ALWAYS_SOFTWARE`, and
`LIBGL_ALWAYS_INDIRECT` only when the target executable basename is exactly
`steamwebhelper`; it does not modify the persistent Steam installation.

## Presentation result

The launcher produced fresh readiness evidence:

```text
nova_launcher_hardware_accel=1
nova_launcher_cef_disable_gpu=0
nova_launcher_steam_force_software_gl=1
nova_launcher_steam_cef_env_split=1
nova_launcher_gamepad=pass input_allow=event9
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The fresh X11 tree had root `0x511`, `1280x800`, and a viewable Steam window:

```text
id=0x1c0003b parent=0x511 depth=1 map_state=viewable x=0 y=0 width=1280 height=800 name="Steam" res_name="steamwebhelper" res_class="steam"
```

Fresh frame artifacts:

| Artifact | SHA-256 |
| --- | --- |
| `x11-window-settled.ppm` | `b22cc713e323866e3ed5d11bba01116673196ace647036cdfe33c58450f32ffb` |
| `android-screen-settled.png` | `6a275b88112d435e615b42be5d8bc7e62ad8dda182769fddc9aac5265641c53b` |
| `android-screen-final-live.png` | `8858ee79e98b46b55a73bb874cd633ada525652698f38a5435c2a6151cfe43b` |

Visual inspection showed a signed-in Steam Store page with the Friends
window, both at the settled capture and after the additional live interval.
The Termux:X11 server log also recorded Android Adreno EGL initialization,
the `1280x960` Android surface, and the stretched `1280x800` shared buffer.

## CEF result

The direct client retained the expected software markers and remained alive:

```text
client_gl_mode=software
client_mesa_driver=swrast
client_gallium_driver=softpipe
client_libgl_always_software=1
client_vk_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
client_cef_env_split_status=enabled
client_started=pass
```

The client still logged the device Vulkan boundary twice:

```text
Vulkan missing requested extension 'VK_KHR_surface'.
Vulkan missing requested extension 'VK_KHR_xlib_surface'.
BInit - Unable to initialize Vulkan!
```

The fresh CEF report at `2026-08-10 10:32:27` contained these relevant
renderers:

```text
ANGLE (Google, Vulkan 1.3.0 (SwiftShader Device ...), ANGLE_SWIFTSHADER
ANGLE (Mesa, llvmpipe (LLVM 21.1.5 128 bits), OpenGL 4.5 ...)
GL implementation parts: (gl=egl-angle,angle=opengl)
Display type: ANGLE_OPENGL
gpu_compositing: enabled
vulkan: disabled_off
```

The same report family recorded repeated:

```text
GpuProcessHost: The GPU process crashed!
```

`steamwebhelper-maps.txt` showed that both `libnova-cef-env-split.so` and
`libsysv-sem-shim.so` were mapped into the fresh `steamwebhelper` process.
The preload’s direct environment trace was not captured, and Android denied
the `/proc/<pid>/environ` read even through the root shell. The process map
plus the renderer change supports that the child boundary was active, but it
does not prove the exact variable-removal call sequence. The acceptance bar
for hardware CEF was not met.

## Teardown and cleanup

The stop invocation returned status `137` after logging:

```text
nova_launcher_x11_stretch_restore=pass
Killed
stop_exit=137
```

It did not emit `nova_launcher_stop=pass`. The runtime helper did emit
`nova_runtime_cleanup=pass`, and the Termux:X11 preferences were restored
byte-for-byte:

```text
before 25530aa4ed8fda450e43638e2c7a00bb95d5cb1ff1c1ab18e717f32a4feb0895
after  25530aa4ed8fda450e43638e2c7a00bb95d5cb1ff1c1ab18e717f32a4feb0895
```

The stop helper’s own command ancestry appeared in the cleanup snapshots:
the exact `su -mm 0 -c ... stop` wrapper and the stop launcher were selected
by the runtime matcher. That explains the self-kill/`137` and is a real
lifecycle defect even though the final exact-scope process audit was clean.

The stop also left one run-scoped D-Bus session daemon alive. After pulling
all evidence, the exact process command was verified against this run’s
socket, the daemon was killed by its recorded PID, and only this exact
directory was removed:

```text
/data/local/tmp/nova-holo-rootfs/tmp/nova-steam-runtime/dbus-session-31976
```

A delayed final process audit then found no Nova/Steam/Gamescope/input-bridge
or run-scoped D-Bus process. This cleanup was recoverable and bounded, but the
launcher/runtime helper should absorb both cases before the one-click path is
called complete.

## Interpretation and next experiment

The local device evidence says the current Turnip Vulkan WSI path cannot
present an X11 game frame because the ICD does not advertise the surface/X11
surface/swapchain route used by the client. That is a route-specific boundary.
It does not rule out an OpenGL game window on the already-working Termux:X11
surface.

The official Proton runtime configuration documents:

```text
PROTON_USE_WINED3D=1 %command%
```

as the OpenGL WineD3D alternative to Vulkan DXVK, and also documents
`PROTON_NO_D3D11=1` for games that can fall back to D3D9. Geometry Wars is a
small D3D9 candidate, so the next bounded matrix will test `PROTON_USE_WINED3D=1`
first, with a separate `PROTON_USE_WINED3D=1 PROTON_NO_D3D11=1` arm only if
needed. The game process must not inherit an explicit Turnip ICD for the
WineD3D arm. A valid result requires a fresh viewable Geometry Wars window or
frame, not merely a Proton launch or renderer log.

References:

- [Valve Proton runtime configuration](https://github.com/ValveSoftware/Proton)
- [Valve Proton 11 source path](https://github.com/ValveSoftware/Proton/blob/proton_11.0/proton)
- [DXVK driver requirements](https://github.com/doitsujin/dxvk/wiki/Driver-support)

This result follows [34](34-nova-runtime-harness-lifecycle.md) and the
predeclaration in [281](281-nova-cef-child-environment-split-experiment-2026-08-10.md).
