# Nova 198X Steam-applaunch Proton 11 ARM64 experiment — 2026-08-10

Status: predeclared; the game action has not been issued.

## Question

The Geometry Wars and Peggle Steam-mediated controls both reached Steam's
game runner but were assigned Proton Experimental and exited before producing
a game frame. AppID `1086010` (198X) is different: its retained Steam
compatibility mapping explicitly selects the locally registered
`proton11_arm64` tool. This run tests the actual Steam IPC launch with the
requested Proton 11.0 (ARM64) selection in effect.

This is separate from the earlier direct Proton 11 198X attempts and from the
two unforced `steam -applaunch` controls. A Steam-mediated result must be
based on a fresh AppID-1086010 process tree and a same-run frame.

## Fixed profile

```text
device=Retroid Pocket Nova
adb_serial=675a2365
rootfs=/data/local/tmp/nova-holo-rootfs
parent_run=steam-20260810T062807Z-198x-proton11
game_run=steam-game-20260810T062807Z-198x-1086010
appid=1086010
name=198X
installed_state=StateFlags 4
size_on_disk=524978714
executable=steamapps/common/198X/198X.exe
compat_mapping=proton11_arm64
compat_tool=Proton 11.0 (ARM64), installed
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
the request, capture the current AppID-1086010 compatibility mapping and a
fresh process/screen baseline. Record the exact `steam -applaunch 1086010`
command, stdout/stderr/exit status, the tool Steam actually places in the
tracked command line, fresh Proton/Wine/FEX/process evidence, and repeated
same-run screenshots.

## Acceptance and cleanup

Acceptance requires a real AppID-1086010 Steam-tracked game process and a
fresh 198X frame that is not the unchanged Steam UI. If Steam rejects the
mapping, chooses another tool, the runner exits, or the screen remains Steam,
record that exact boundary instead. No controller, audio, networking, or
hardware-rendering claim is implied by a process alone.

After capture, terminate only the verified AppID-1086010 game tree, run the
exact Nova/X11 and rootfs cleanup helpers, and verify that no matching game,
Steam/webhelper, Wine, FEX, Proton, D-Bus, Termux:X11, relay, mount, bridge
socket, or deleted run-log handle remains. Commit and push this result before
another experiment.
