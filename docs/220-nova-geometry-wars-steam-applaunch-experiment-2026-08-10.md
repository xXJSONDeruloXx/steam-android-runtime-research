# Nova Geometry Wars Steam-applaunch experiment — 2026-08-10

Status: predeclared; the game action has not been issued.

## Question

The client-software-GL split produced a live, logged-in Steam desktop UI on
the hardware-backed Termux:X11 surface. Geometry Wars: Retro Evolved (AppID
8400) is installed and has a Proton 11 ARM64 tool available. This action asks
the already-running Steam client to launch AppID 8400 through its normal
`steam -applaunch` IPC, so the result tests Steam-mediated game launch rather
than another independent Wine process.

The parent rendering run is
`steam-20260810T060728Z-hardware-client-software-gl`. The game action gets a
new run label and must retain the parent profile explicitly; a stable Steam
UI screenshot is not reused as the game result.

## Fixed profile

```text
device=Retroid Pocket Nova
adb_serial=675a2365
rootfs=/data/local/tmp/nova-holo-rootfs
parent_run=steam-20260810T060728Z-hardware-client-software-gl
game_run=steam-game-20260810T060728Z-geometry-wars-8400
appid=8400
name=Geometry Wars: Retro Evolved
installed_state=StateFlags 4
size_on_disk=66019943
proton=Proton 11.0 (ARM64), installed
presentation=Termux:X11 Android SurfaceView
target_geometry=1280x960
termux_x11_hardware=true
steam_client_gl=software,swrast,softpipe
steam_client_vulkan_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
steam_sysv_sem_preload=enabled
dbus_session=enabled
dbus_system=enabled
steam_ui_mode=minimal
```

The launch command must be recorded exactly, along with a pre-launch process
snapshot, the `steam -applaunch 8400` stdout/stderr/exit status, fresh game
process evidence, and a same-run screenshot. Do not call a directly invoked
Wine/FEX child a Steam launch result.

## Acceptance and cleanup

Acceptance requires one of the following explicit outcomes:

* a fresh Geometry Wars window/frame is visible and the game process has a
  verified AppID-8400 command line; or
* Steam returns a launch error, the game process fails to appear, or the
  screen remains the Steam UI/launcher, with the exact boundary retained.

No controller, audio, networking, or hardware-rendering claim is implied by a
game process alone. After capture, terminate only the verified AppID-8400
game tree, then run the exact X11 and rootfs cleanup helpers for the parent
Nova session. Verify no Wine/FEX/Proton child, Steam/webhelper, D-Bus,
Termux:X11, socket, mount, or deleted run-log handle remains. Commit and push
the result before another game or rendering experiment.
