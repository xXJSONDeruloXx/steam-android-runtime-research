# Nova 198X Steam-applaunch Proton 11 ARM64 experiment — 2026-08-10

Status: complete; Steam-mediated Proton 11 launch attempted and the result
was documented and cleaned up.

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

## Launch result

The fresh parent session used stage token `20260810T062921Z-4185`. The final
Steam config retained the requested mapping:

```text
"1086010"
{
    "name"  "proton11_arm64"
    "config" ""
    "priority" "250"
}
```

The exact Steam IPC command was:

```sh
adb -s 675a2365 shell 'su -mm 0 -c "NOVA_X11_ALLOW_INPUT_EVENTS=9 /data/user/0/com.xjsonderulo.steamandroid.novalab/files/launcher/nova-x11-private-namespace.sh chroot-dev /data/user/0/com.xjsonderulo.steamandroid.novalab/files/launcher/nova-mount-private /data/local/tmp/nova-holo-rootfs /usr/bin/setpriv --reuid=501 --regid=20 --groups=1005 /usr/bin/env -i PATH=/usr/bin:/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin HOME=/opt/nova-steam/home USER=steam LOGNAME=steam DISPLAY=:0 XDG_RUNTIME_DIR=/tmp/nova-steam-runtime LANG=C LC_ALL=C DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/nova-steam-runtime/dbus-session-4421/bus DBUS_SYSTEM_BUS_ADDRESS=unix:path=/run/dbus/system_bus_socket MESA_LOADER_DRIVER_OVERRIDE=swrast GALLIUM_DRIVER=softpipe LIBGL_ALWAYS_SOFTWARE=1 VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu LD_PRELOAD=/opt/nova-kgsl-driver/libsysv-sem-shim.so /usr/bin/timeout 30 /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -applaunch 1086010"'
```

The command exited `0` and reported that the running Steam client forwarded
the request. Steam recorded `StartSession: appID 1086010` at `06:30:15`, then
selected the requested tool at `06:30:16`:

```text
AppID 1086010 adding PID 6059 as a tracked process "/opt/nova-steam/home/.local/share/Steam/linuxarm64/steam-launch-wrapper -- /opt/nova-steam/home/.local/share/Steam/steamrtarm64/reaper SteamLaunch AppId=1086010 -- '/opt/nova-steam/home/.local/share/Steam/compatibilitytools.d/proton-11-arm64'/proton waitforexitandrun  '/opt/nova-steam/home/.local/share/Steam/steamapps/common/198X/198X.exe'"
Command prefix for tool 0 "Proton 11.0 (ARM64)" set to: "'/opt/nova-steam/home/.local/share/Steam/compatibilitytools.d/proton-11-arm64'/proton waitforexitandrun "
DEBUG: compat tool = proton11_arm64
```

Steam added multiple descendants to the Proton 11 tracked tree (PIDs 6060
through 6095), including the AppID-1086010 tracked process tree, and then
released the session at `06:30:18`. The wrapper returned exit code `0`; the
descendants exited with `-1`. Neither of the fresh 1280x960 frames showed
198X; both remained the authenticated Steam desktop UI. This proves Steam
dispatch and Proton 11 selection, but not game startup or rendering.

Installed 198X evidence:

* `appmanifest_1086010.acf`, 753 bytes, SHA-256
  `50a55e7fe442406d6d981742a353de1bf1730833afd40380f1d6dcb6311a7026`;
* `198X.exe`, 650,752 bytes, SHA-256
  `ce03bffd959a5153fddf2af1565700ce7d29d7ca67028e86e097ae67f08c8730`;
* source tree commit `6c56df3`, launcher/APK source commit `5e848fc`, and
  host/device APK SHA-256
  `809f5c09801efa2f5ca75534123fd1d64fd5521b01e24245b78b346ed92d334b`;
* final `config.vdf` SHA-256
  `1b186421c1a9091fcc59460e93a94485da2b69f482e3200caa2dd17e8cf16170`;
* `game-screen-01.png` SHA-256
  `33a38788101c5cdd5c83b47ddab09e354d63efb68bf6c67934d451ecfdcefa0b`;
* `game-screen-02.png` SHA-256
  `d2f011e1af299af5967dbdacaab19c17e0a4810cb85f4540470c3c99ed36df56`;
* `postlaunch-02-gameprocess_log.txt` SHA-256
  `758da27176310600739e14340fe8fccc26cb0678fa5c3deebacab9a61f60d080`;
* `postlaunch-02-compat_log.txt` SHA-256
  `bd2981936394cdd74d4f6229570250f504e751642191e523779fedfa2a8a3a31`;
* final software-GL client log SHA-256
  `879f32c127da2b65fa856a6914808361d092f491450a94ea1e186d790a2d7ca7`.

## Cleanup result

The exact X11 helper returned `nova_x11_cleanup=pass` and the exact runtime
helper returned `nova_runtime_cleanup=pass`. After cleanup settled, no
matching 198X, Proton, FEX, Wine, Steam/webhelper, D-Bus, Termux:X11,
launcher, or Nova mount remained. The helper reported `socket_state=absent`.
One current-run Steam CEF shared-memory socket node was removed explicitly
after confirming that no corresponding process remained; the final rootfs
scan found only the reusable `/run/udev/control` and
`/run/udev/io.systemd.Udev` sockets.

Cleanup evidence is retained under
`/tmp/steam-game-20260810T062807Z-198x-1086010/`:

* `cleanup-status.txt`: both helpers returned `0`;
* `processes-after-cleanup.txt` SHA-256
  `d8d222a928cdd4e48fb07aaec328f8cfd991e8cfd6294ea112b63510d86b9afe`;
* `mounts-after-cleanup.txt` SHA-256
  `71a8bae66c7c88b49e6bf9956f0003e834426a454e1c6f2466a51fc520a12724`;
* `sockets-after-stale-cleanup.txt` contains only the two baseline udev
  sockets.

The next useful game-launch experiment is not another unforced small title:
the Steam client now demonstrably dispatches 198X through Proton 11 ARM64,
but that runtime exits before a frame. Further work should capture a
run-scoped Proton/FEX/Wine log from this Steam-mediated path or isolate the
known 32-bit exception/startup boundary before changing the display transport
again.
