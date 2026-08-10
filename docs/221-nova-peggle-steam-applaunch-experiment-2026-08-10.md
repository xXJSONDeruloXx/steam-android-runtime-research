# Nova Peggle Deluxe Steam-applaunch experiment — 2026-08-10

Status: predeclared; the game action has not been issued.

## Question

The software-GL Steam-client profile now produces a live authenticated Steam
desktop UI on the hardware-backed Termux:X11 surface. Geometry Wars was then
requested through Steam IPC, but Steam selected Proton Experimental and its
runner exited before producing a game frame. Peggle Deluxe (AppID 3480) is a
smaller installed title and is a useful second Steam-mediated control.

This experiment asks the already-running client to launch AppID 3480 through
its normal `steam -applaunch` IPC. It is separate from the earlier direct
Proton 11 ARM64 Peggle run in document 208; that result must not be reused as
evidence for this Steam-mediated path.

## Fixed profile

```text
device=Retroid Pocket Nova
adb_serial=675a2365
rootfs=/data/local/tmp/nova-holo-rootfs
parent_run=steam-20260810T061938Z-peggle-deluxe-software-gl
game_run=steam-game-20260810T061938Z-peggle-deluxe-3480
appid=3480
name=Peggle Deluxe
installed_state=StateFlags 4
size_on_disk=19463282
executable=steamapps/common/Peggle Deluxe/Peggle.exe
proton=record the tool Steam actually selects; Proton 11.0 (ARM64) is installed
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

The parent must be a fresh one-click software-GL Steam-client session. Before
the game request, retain a fresh process snapshot and screenshot. Record the
exact `steam -applaunch 3480` command, stdout/stderr/exit status, fresh
AppID-3480 process evidence, Steam compatibility/gameprocess log lines, and a
same-run screenshot. Do not call a directly invoked Wine/FEX child a
Steam-mediated result.

## Acceptance and cleanup

Acceptance requires one of these explicit outcomes:

* a fresh Peggle window/frame is visible and its process has a verified
  AppID-3480 command line; or
* Steam returns a launch error, the game process fails to appear or exits, or
  the screen remains the Steam UI, with the exact boundary retained.

No controller, audio, networking, or hardware-rendering claim is implied by a
game process alone. After capture, terminate only the verified AppID-3480
game tree, then run the exact Nova/X11 and rootfs cleanup helpers for the
parent session. Verify no matching game, Steam/webhelper, Wine, FEX, Proton,
D-Bus, Termux:X11, relay, mount, bridge socket, or deleted run-log handle
remains. Commit and push this result before another experiment.
