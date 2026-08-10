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

Read `docs/34-nova-runtime-harness-lifecycle.md` immediately before launch.
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
