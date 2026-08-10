# Nova Peggle Deluxe Steam-applaunch experiment — 2026-08-10

Status: complete; Steam-mediated launch attempted and the result was
documented and cleaned up.

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
parent_run=steam-20260810T062152Z-peggle-deluxe-software-gl-retry
game_run=steam-game-20260810T062152Z-peggle-deluxe-3480
appid=3480
name=Peggle Deluxe
installed_state=StateFlags 4
size_on_disk=19463282
executable=steamapps/common/Peggle Deluxe/Peggle.exe
proton=Proton 11.0 (ARM64) installed and registered; Steam selected Experimental
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

## Launch result

The first preflight attempt at
`/tmp/steam-20260810T061938Z-peggle-deluxe-software-gl` did not start a new
session: Android reported that the existing launcher Activity was already the
top-most instance, and no game request was issued. The Activity was
force-stopped, the exact cleanup helpers were rerun, and the actual parent
session was started with the fresh stage token
`20260810T062238Z-31045`.

The exact Steam IPC command for the actual game action was:

```sh
adb -s 675a2365 shell 'su -mm 0 -c "NOVA_X11_ALLOW_INPUT_EVENTS=9 /data/user/0/com.xjsonderulo.steamandroid.novalab/files/launcher/nova-x11-private-namespace.sh chroot-dev /data/user/0/com.xjsonderulo.steamandroid.novalab/files/launcher/nova-mount-private /data/local/tmp/nova-holo-rootfs /usr/bin/setpriv --reuid=501 --regid=20 --groups=1005 /usr/bin/env -i PATH=/usr/bin:/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin HOME=/opt/nova-steam/home USER=steam LOGNAME=steam DISPLAY=:0 XDG_RUNTIME_DIR=/tmp/nova-steam-runtime LANG=C LC_ALL=C DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/nova-steam-runtime/dbus-session-31238/bus DBUS_SYSTEM_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket MESA_LOADER_DRIVER_OVERRIDE=swrast GALLIUM_DRIVER=softpipe LIBGL_ALWAYS_SOFTWARE=1 VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu LD_PRELOAD=/opt/nova-kgsl-driver/libsysv-sem-shim.so /usr/bin/timeout 30 /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -applaunch 3480"'
```

It exited `0` and printed `Steam is already running, exiting (command line was
forwarded)`. Steam then recorded this tracked launch at `2026-08-10
06:24:58`:

```text
AppID 3480 adding PID 402 as a tracked process "/opt/nova-steam/home/.local/share/Steam/linuxarm64/steam-launch-wrapper -- /opt/nova-steam/home/.local/share/Steam/steamrtarm64/reaper SteamLaunch AppId=3480 -- '/opt/nova-steam/home/.local/share/Steam/steamapps/common/SteamLinuxRuntime_4'/_v2-entry-point --verb=waitforexitandrun -- '/opt/nova-steam/home/.local/share/Steam/steamapps/common/Proton - Experimental'/proton waitforexitandrun  '/opt/nova-steam/home/.local/share/Steam/steamapps/common/Peggle Deluxe/Peggle.exe'"
AppID 3480 adding PID 403 as a tracked process
AppID 3480 adding PID 406 as a tracked process
AppID 3480 adding PID 407 as a tracked process
AppID 3480 no longer tracking PID 407, exit code -1
AppID 3480 no longer tracking PID 406, exit code -1
AppID 3480 no longer tracking PID 403, exit code -1
AppID 3480 no longer tracking PID 402, exit code 0
Remove 3480 from running list
```

Steam selected Proton Experimental again, even though Proton 11 ARM64 was
registered in the same client session. The wrapper and three child entries
exited immediately. Fresh 1280x960 frames before and after the request both
showed the authenticated Steam desktop UI; no Peggle frame appeared. This
does not establish game rendering, controller input, audio, networking, or
the desired Nova 4:3 game presentation.

Installed Peggle evidence from this run:

* `appmanifest_3480.acf`, 741 bytes, SHA-256
  `f183697bf34cdaa67647bd99cfbb117023ba621c2f6a04f1bb79c5cd093f71c9`;
* `Peggle.exe`, 4,709,400 bytes, SHA-256
  `d37a37e305e468dc48fd88eeb4e1056a086881e1be14f66f3590c99a88c44d4c`;
* source commit `5e848fc` and host/device APK SHA-256
  `809f5c09801efa2f5ca75534123fd1d64fd5521b01e24245b78b346ed92d334b`;
* `game-screen-01.png` SHA-256
  `7b7266dd63e24f850d1866a41659a514e67d1b4e78176b3ea0d8d75006757a88`;
* `game-screen-02.png` SHA-256
  `bd7838279fea455956313e2239837f989e8e6a6e0e19f751de5f8391148ef940`;
* `postlaunch-02-gameprocess_log.txt` SHA-256
  `3b9a2f76cdec4d7d72f0b16c4aa9c2ab50619b5e35f2241d6f29bc519fbde30f`;
* `postlaunch-02-compat_log.txt` SHA-256
  `816db02aab6a1f4468abb8d6f6d8baf4302765731ed40c5576f17639afa5dc3c`;
* final software-GL client log SHA-256
  `6f1816c04952c1adfd1bdb318d21b5f5865b01ea3f3113904e974aeec66d02a7`.

## Cleanup result

The exact X11 helper returned `nova_x11_cleanup=pass` and the exact runtime
helper returned `nova_runtime_cleanup=pass`. After the cleanup settled, no
matching game, Steam/webhelper, Wine, FEX, Proton, D-Bus, Termux:X11,
launcher, or Nova mount remained. The helper reported `socket_state=absent`.
One current-run Steam CEF shared-memory socket node was removed explicitly
after confirming that no corresponding process remained; the final scan found
only the reusable rootfs baseline `/run/udev/control` and
`/run/udev/io.systemd.Udev` sockets.

Cleanup evidence is retained under
`/tmp/steam-game-20260810T062152Z-peggle-deluxe-3480/`:

* `cleanup-status.txt`: both helpers returned `0`;
* `processes-after-cleanup.txt` SHA-256
  `3960f41f5abbaa8ebeb52434f40f7f49c52776082c08b35983dae13438bdb9f6`;
* `mounts-after-cleanup.txt` SHA-256
  `9443e441538b6fe77f33d816b564a776f28fb0abee2297ed7062890f3dc31626`;
* `sockets-after-stale-cleanup.txt` contains only the two baseline udev
  sockets.

The next Steam-mediated game test should explicitly force Proton 11 ARM64 if
the goal is to test that tool. The two small titles tested through the normal
client both selected Proton Experimental and exited before creating a game
surface, so more unforced 32-bit titles are unlikely to add much information.
