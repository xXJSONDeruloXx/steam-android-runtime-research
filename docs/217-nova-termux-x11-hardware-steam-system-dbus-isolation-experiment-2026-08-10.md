# Nova Termux:X11 hardware Steam system-D-Bus isolation experiment — 2026-08-10

Status: predeclared; no device session has been launched under this run.

## Question

The hardware Termux:X11 display boundary passes, while Steam’s ARM64 client
still exits before a frame under CEF-enabled, CEF-disabled, and minimal
Steam-UI flag profiles. The no-preload split established that the System V
semaphore shim is required; the normal hardware profile therefore retains it.
The remaining direct-client setup starts both a synthetic rootfs system bus
and a private Steam session bus. This run disables only the synthetic system
bus while retaining the session bus, display path, Steam flags, CEF setting,
network compatibility patch, and semaphore shim.

This is an opt-in launcher extra. The default launcher continues to start both
buses, and the software profile is unchanged.

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
```

The launcher must log `nova_launcher_steam_disable_system_dbus=1`, and the
client must log `client_dbus_system_mode=0` while retaining
`client_dbus_session_mode=1` and `client_dbus_session_status=pass`.

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
dbus_session=enabled
dbus_system=disabled
audio_bridge=false
gamescope=not_used
game_launch=not_attempted
input_action=none
```

Read `docs/34-nova-runtime-harness-lifecycle.md` immediately before launch.
Use a fresh launcher state, fresh Steam logs, and a same-run screenshot. Run
the exact X11 and rootfs cleanup helpers before launch and after evidence
capture. Do not reuse a prior status-139 log, screenshot, or readiness token.

## Acceptance and interpretation

Acceptance requires the selected hardware/ICD/CEF/UI/preload markers,
`client_started=pass`, and retained client stderr/minidump output if Steam
crashes. A stable Steam frame is required before any game, input, audio, or
network claim can be attributed to this run. Preserve independent Termux:X11
EGL/XCB/shared-buffer evidence even if Steam exits early.

* If Steam reaches a stable frame or changes its crash boundary, record that
  as evidence that the synthetic system bus participates in startup. Follow
  with a separately declared service/network interpretation; do not call the
  empty system bus a finished NetworkManager implementation.
* If the client reports an expected missing system-bus or `NMClient` boundary
  but remains alive, this isolates the system-bus dependency from the later
  hardware crash.
* If it reaches the same status-139 boundary, the system bus is not the sole
  cause; move to Steam runtime library selection or another single startup
  layer.

No game title should be launched from a run without a fresh stable Steam
frame. Commit and push this predeclaration before installing the APK or
launching the device session.
