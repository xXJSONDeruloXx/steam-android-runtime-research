# Nova Termux:X11 hardware Holo Mesa library-order experiment — 2026-08-10

Status: predeclared; no device session has been launched under this run.

## Question

The hardware Termux:X11 boundary passes, but the direct ARM64 Steam client
still segfaults before drawing. CEF, SteamOS/GamepadUI flags, semaphore
preload, and synthetic system-D-Bus setup have now been isolated without
changing that boundary. The direct client currently puts SteamRT's
`libEGL_mesa`, `libGL`, `libGLX`, and `libgbm` directory ahead of Holo's
`/usr/lib`. The older Gamescope launcher documents the opposite ordering as a
requirement: Holo Mesa must precede SteamRT Mesa to avoid a GLX null-backend
failure when Holo's KGSL stack is used.

This run enables only an opt-in Holo-first library ordering. It keeps the
hardware profile, explicit Freedreno ICD, CEF-disabled setting, minimal Steam
flags, semaphore shim, private session bus, disabled synthetic system bus,
network compatibility patch, and presentation path unchanged. The normal
launcher default remains SteamRT-first.

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
--ez steam_disable_system_dbus true
--ez steam_holo_mesa_first true
```

The launcher must log `nova_launcher_steam_holo_mesa_first=1`, and the client
must log `client_holo_mesa_first=1` and
`client_library_order=holo-mesa-first`. The device asset should contain the
same source marker before launch.

## Fixed run profile

```text
device=Retroid Pocket Nova
adb_serial=675a2365
rootfs=/data/local/tmp/nova-holo-rootfs
display=:0
presentation=Termux:X11 Android SurfaceView
target_geometry=1280x960
hardware_accel=true
vulkan_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
cef_disable_gpu=true
steam_ui_mode=minimal
steam_disable_preload=false
steam_disable_system_dbus=true
steam_holo_mesa_first=true
dbus_session=enabled
dbus_system=disabled
gamescope=not_used
game_launch=not_attempted
input_action=none
audio_bridge=false
```

Read `docs/34-nova-runtime-harness-lifecycle.md` immediately before launch.
Use a fresh launcher state, fresh Steam logs, and a same-run screenshot. Run
the exact X11 and rootfs cleanup helpers before launch and after evidence
capture. Do not reuse a prior status-139 log or screenshot as acceptance.

## Acceptance and interpretation

Acceptance requires the selected hardware/ICD/CEF/UI/preload/D-Bus/library
markers, `client_started=pass`, and retained client stderr/minidump output if
Steam crashes. A stable Steam frame is required before any game, input, audio,
or network claim can be attributed to this run. Preserve independent
Termux:X11 EGL/XCB/shared-buffer evidence even if Steam exits early.

* If Steam reaches a stable frame or changes the crash boundary, retain this
  as evidence that the direct client was selecting an incompatible Mesa/GL
  closure. Follow with a narrow runtime dependency audit before making
  Holo-first the default.
* If the client fails with a missing symbol or loader error, record that as a
  library-ordering incompatibility rather than adding more preload shims.
* If it reaches the same status-139 boundary, this documented ordering is not
  sufficient; move to another single Steam runtime/binary startup variable.

No game title should be launched from a run without a fresh stable Steam
frame. Commit and push this predeclaration before installing the APK or
launching the device session.
