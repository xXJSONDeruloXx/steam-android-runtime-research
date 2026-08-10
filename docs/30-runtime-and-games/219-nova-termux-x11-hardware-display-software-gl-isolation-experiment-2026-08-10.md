# Nova Termux:X11 hardware display/software-GL isolation experiment — 2026-08-10

Status: predeclared; no device session has been launched under this run.

## Question

LLDB analysis of two independent hardware Steam status-139 minidumps shows
the crashing thread entering `libgallium-25.2.7-arch1.1.so` through
`libGLX_mesa.so.0.0.0`, while another worker is in
`libvulkan_freedreno.so`. The Android Termux:X11 surface itself continues to
load Adreno EGL, complete XCB setup, and exchange shared buffers. This run
separates those layers by forcing software GL only in the Steam client while
keeping the Termux:X11 Android display hardware-backed and retaining the
explicit Freedreno Vulkan ICD.

This is an opt-in diagnostic profile. It does not claim hardware-rendered
Steam UI or games if it succeeds. The normal hardware profile still leaves
the client GL environment unchanged.

## Source and artifact

Build and push the source change before installing or launching the device.
Record the final source commit, host APK SHA-256, and matching device APK
SHA-256 in the result. The intended launch extras are:

```text
--ez run_steam_session true
--ez hardware_accel true
--ez cef_disable_gpu true
--es steam_ui_mode minimal
--ez steam_disable_preload false
--ez steam_disable_system_dbus false
--ez steam_holo_mesa_first false
--ez steam_force_software_gl true
```

The launcher must log `nova_launcher_steam_force_software_gl=1`. The client
must log `client_force_software_gl=1`,
`client_gl_mode=software`, `client_mesa_driver=swrast`,
`client_gallium_driver=softpipe`, `client_libgl_always_software=1`, and the
explicit `client_vk_icd` path. The server remains the normal hardware Adreno
profile.

## Fixed run profile

```text
device=Retroid Pocket Nova
adb_serial=675a2365
rootfs=/data/local/tmp/nova-holo-rootfs
display=:0
presentation=Termux:X11 Android SurfaceView
target_geometry=1280x960
server_hardware_accel=true
steam_client_gl=software
steam_client_vulkan_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
cef_disable_gpu=true
steam_ui_mode=minimal
steam_disable_preload=false
steam_disable_system_dbus=false
steam_holo_mesa_first=false
audio_bridge=false
gamescope=not_used
game_launch=not_attempted
input_action=none
```

Read `docs/00-start-here/34-nova-runtime-harness-lifecycle.md` immediately before launch.
Use a fresh launcher state, fresh Steam logs, and a same-run screenshot. Run
the exact X11 and rootfs cleanup helpers before launch and after evidence
capture. Do not reuse a prior status-139 log or screenshot as acceptance.

## Acceptance and interpretation

Acceptance requires the selected hardware server, client software-GL,
explicit Vulkan ICD, CEF/UI/preload/D-Bus markers, `client_started=pass`, and
fresh client stderr/minidump output if Steam crashes. A stable Steam frame is
required before any game, input, audio, or network claim can be attributed to
this run. Retain the screenshot and independent Termux:X11 EGL/XCB/shared
buffer evidence either way.

* If Steam reaches a stable frame, this isolates the direct client GLX/Mesa
  path from the Android display transport. Record it as a diagnostic control;
  it is not evidence that games are hardware-rendered.
* If Steam still crashes in `libGLX_mesa` or `libgallium`, software GL does
  not avoid the loaded GLX path and the next step should be a matched runtime
  library/ABI audit.
* If Steam reaches a different Vulkan or library failure, retain that
  boundary and do not re-enable hardware GL without a separately declared
  comparison.

No game title should be launched from a run without a fresh stable Steam
frame. Commit and push this predeclaration before installing the APK or
launching the device session.

## Result

Status: completed as a rendering diagnostic; forcing software GL inside Steam
kept the ARM64 client alive and produced a stable logged-in desktop Steam UI
on the hardware-backed Termux:X11 surface.

The source commit was `5e848fc`. The rebuilt APK SHA-256 was
`809f5c09801efa2f5ca75534123fd1d64fd5521b01e24245b78b346ed92d334b`, and
the installed device APK reported the same hash. The run ID was
`steam-20260810T060728Z-hardware-client-software-gl`; its stage token was
`20260810T060756Z-22867`.

The launcher selected the intended split:

```text
nova_launcher_hardware_accel=1
nova_launcher_vulkan_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
nova_launcher_cef_disable_gpu=1
nova_launcher_steam_ui_mode=minimal
nova_launcher_steam_disable_preload=0
nova_launcher_steam_disable_system_dbus=0
nova_launcher_steam_holo_mesa_first=0
nova_launcher_steam_force_software_gl=1
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The client retained the explicit Freedreno Vulkan ICD and semaphore shim but
used software GL for its GLX path:

```text
client_hardware_accel=1
client_vk_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
client_force_software_gl=1
client_gl_mode=software
client_mesa_driver=swrast
client_gallium_driver=softpipe
client_libgl_always_software=1
client_preload=/opt/nova-kgsl-driver/libsysv-sem-shim.so
client_dbus_system_status=pass
client_dbus_session_status=pass
client_flags_final=... -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox -cef-disable-gpu -fullscreen -fulldesktopres
client_started=pass
```

Unlike every hardware-GL run, the client did not emit `client_status=139`.
The live process snapshot retained the ARM64 Steam client, multiple
`steamwebhelper` processes, both D-Bus daemons, and Termux:X11. Two captures
eight seconds apart were both rendered Steam frames with different hashes.
The visible UI was the authenticated desktop client with Store/Library and
Friends views, not the Nova launcher or a black surface. Current webhelper
records also show the active Steam browser windows and a 1280x960 available
screen; the desktop client remains letterboxed inside the 1280x960 surface
instead of presenting the desired 4:3 GamepadUI/game surface.

Termux:X11 independently continued to load Android Adreno EGL (`0676.53`,
EGL 1.5), complete XCB setup, and exchange 1280x1024 and 1280x960 shared
buffers. This is therefore a meaningful rendering unblock: the Android
display path is hardware-backed, while Steam's own GLX client path is the
part forced to software. It is not yet evidence of hardware-rendered Steam
games.

No game was launched during this acceptance capture. The Steam session was
intentionally left alive after the stable-frame evidence for a separately
documented small-game launch action; its exact cleanup will be recorded with
that action rather than reusing this result as a new readiness baseline.

Fresh artifacts are retained at
`/tmp/steam-20260810T060728Z-hardware-client-software-gl/`:

| Artifact | SHA-256 |
| --- | --- |
| `launcher.log` | `1dd8fe98f564f4ad7a157b65eb527977d2612d0078c17959e3cbde68291348db` |
| `client.log` | `1619903f56f05254d534cdef3a73b870320808649bc159c8b5f57bca9e223eec` |
| `client-runtime.log` | `b1a9dc12e328ef9b822f0ea09f8a08bdb78b0d6a2127604590912ec400284304` |
| `client-stderr.log` | `aa2c3bb07f8b73648eb598b2d25bc1bb8c6da6e66276c318cb62d1f3dc93bb29` |
| `server.log` | `1d5cad475fb68e5ea521a53985eeaffda0ccdfcaef2960ba45c988d2fd33260f` |
| `screen-live-01.png` | `0c22fe1c1c46850642725ed76b2af7e01e8aa64cac4076756d31991a17430c32` |
| `screen-live-02.png` | `f91445e3aafb722113680b038218f6962f132dcf20816ee6110735a7519b1992` |
| `process-snapshot.txt` | `98ae55e53817cd1820ee1dccea503688f00d7baee5244117d9c41c31d1213933` |
| `logcat.txt` | `fcacdda6f667ac3d2ba16d476fb66f0c8570281c4adb4ba2e8d4708a56d5c82d` |
| `current-webhelper-lines.txt` | `fe207ae91f2d937495b9cb55b9f50648d5d29f6b1abbdae847c25f5085c382ff` |
| `steam-steamwebhelper.log` | `55a152021fb2bb8bfa9124f98cf77112027bb680bace8365a8a8f5aefb10d5b6` |
| `steam-gameprocess_log.txt` | `ddb227143c914fdc07ce8939a1754b70c6e633ed7f7ab71e74bd45fc475` |

The next controlled action may use this live session to request one installed
small title, beginning with Geometry Wars, but it must keep the software-GL
diagnostic boundary explicit and must not be reported as a hardware-rendering
result.
