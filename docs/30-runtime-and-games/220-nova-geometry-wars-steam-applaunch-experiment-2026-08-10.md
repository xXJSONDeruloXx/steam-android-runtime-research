# Nova Geometry Wars Steam-applaunch experiment — 2026-08-10

Status: complete; Steam-mediated launch attempted and the result was
documented and cleaned up.

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
proton=Proton 11.0 (ARM64), installed and registered; not forced for this run
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

## Launch result

The parent session was alive and authenticated when the request was issued.
The exact command was:

```sh
adb -s 675a2365 shell 'su -mm 0 -c "NOVA_X11_ALLOW_INPUT_EVENTS=9 /data/user/0/com.xjsonderulo.steamandroid.novalab/files/launcher/nova-x11-private-namespace.sh chroot-dev /data/user/0/com.xjsonderulo.steamandroid.novalab/files/launcher/nova-mount-private /data/local/tmp/nova-holo-rootfs /usr/bin/setpriv --reuid=501 --regid=20 --groups=1005 /usr/bin/env -i PATH=/usr/bin:/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin HOME=/opt/nova-steam/home USER=steam LOGNAME=steam DISPLAY=:0 XDG_RUNTIME_DIR=/tmp/nova-steam-runtime LANG=C LC_ALL=C DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/nova-steam-runtime/dbus-session-23124/bus DBUS_SYSTEM_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket MESA_LOADER_DRIVER_OVERRIDE=swrast GALLIUM_DRIVER=softpipe LIBGL_ALWAYS_SOFTWARE=1 VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu LD_PRELOAD=/opt/nova-kgsl-driver/libsysv-sem-shim.so /usr/bin/timeout 30 /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -applaunch 8400"'
```

The command exited `0` and printed `Steam is already running, exiting
(command line was forwarded)`. Steam then recorded the AppID-8400 launch at
`2026-08-10 06:15:49`:

```text
AppID 8400 adding PID 27975 as a tracked process "/opt/nova-steam/home/.local/share/Steam/linuxarm64/steam-launch-wrapper -- /opt/nova-steam/home/.local/share/Steam/steamrtarm64/reaper SteamLaunch AppId=8400 -- '/opt/nova-steam/home/.local/share/Steam/steamapps/common/SteamLinuxRuntime_4'/_v2-entry-point --verb=waitforexitandrun -- '/opt/nova-steam/home/.local/share/Steam/steamapps/common/Proton - Experimental'/proton waitforexitandrun  '/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe'"
AppID 8400 no longer tracking PID 27978, exit code -1
AppID 8400 no longer tracking PID 27977, exit code -1
AppID 8400 no longer tracking PID 27976, exit code -1
AppID 8400 no longer tracking PID 27975, exit code 0
Remove 8400 from running list
```

This is a Steam-mediated launch, but it did not use Proton 11 ARM64: Steam
selected its existing Proton Experimental mapping for AppID 8400. The tracked
runner exited immediately, and no Geometry Wars process remained. Fresh
screens captured before and after the attempt both showed the authenticated
Steam desktop UI in the 1280x960 Termux:X11 output; no game frame appeared.
This therefore does not establish game rendering, controller input, audio, or
the desired Nova 4:3 game presentation.

The retained evidence is under
`/tmp/steam-game-20260810T060728Z-geometry-wars-8400/`:

* `game-screen-01.png` SHA-256
  `6554a7eaf5cafd08adfe241a3d7516156b5239127e9f867adb1c272897118cce`;
* `game-screen-02.png` SHA-256
  `b655549601700da973780a4c565963cca891b49f732fd32d24f69158bec50ef0`;
* `after-02-gameprocess_log.txt` SHA-256
  `f757306884241c875c586e4e6284212ca07f62b6d633e0f40d927e656c08911a`;
* `after-02-compat_log.txt` SHA-256
  `bb6121f0b285ab6426fd412729554a0964013b6c711f384a7937e7d1bb220b7f`;
* `after-02-content_log.txt` SHA-256
  `201fd4c155a493bfe3198dfb998c7a70dbdb9e01f69f681ad81d06167d580151`.

## Cleanup result

The exact X11 cleanup helper returned `nova_x11_cleanup=pass` and the exact
runtime cleanup helper returned `nova_runtime_cleanup=pass`. After the
cleanup scripts settled, no matching Gamescope, Steam, webhelper, Wine, FEX,
Proton, D-Bus, Termux:X11, or launcher process and no Nova mount remained.
The helper reported `socket_state=absent`; the final rootfs scan found only
the reusable baseline `/run/udev/control` and `/run/udev/io.systemd.Udev`
sockets. Six stale Steam CEF shared-memory socket nodes from earlier sessions
were removed explicitly after confirming that no corresponding process was
running.

Cleanup evidence:

* `cleanup-status.txt`: both helpers returned `0`;
* `processes-after-cleanup-final.txt` SHA-256
  `0b3cabe947e55328abbd515845ba82a7d1fcd914cbbe861b6a43ca728c553509`;
* `mounts-after-cleanup-final.txt` SHA-256
  `052219ce3d9bf6c82c79fdcc1b8a22c00f092b263672052c54655c007554f18d`;
* `sockets-after-stale-cleanup.txt` contains only the two baseline udev
  sockets.

The next game test must either explicitly force Proton 11 ARM64 for Geometry
Wars or use another installed title and record the selected compatibility tool
instead of assuming the available Proton tool is the one Steam will choose.

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
