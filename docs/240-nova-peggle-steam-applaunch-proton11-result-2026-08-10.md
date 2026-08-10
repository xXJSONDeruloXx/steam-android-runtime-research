# Nova Peggle Deluxe Steam-applaunch Proton 11 result — 2026-08-10

## Result summary

The explicit Steam-mediated Proton 11 ARM64 test for Peggle Deluxe is
complete. Steam selected the requested `proton11_arm64` wrapper for AppID
`3480` and launched the real Peggle executable, but the wrapper exited
immediately before a game window or frame appeared.

The one-click session and the known-good Steam desktop presentation remained
healthy throughout the request. This is another early Proton 11/FEX/Wine
startup-boundary result, not a new Gamescope/AHB or Steam UI failure.

## Run identity and provenance

- Run ID: `steam-game-peggle-proton11-20260810T073154Z`
- Run directory:
  `android/nova-lab/build/runs/steam-game-peggle-proton11-20260810T073154Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `3480`, Peggle Deluxe
- Executable:
  `/opt/nova-steam/home/.local/share/Steam/steamapps/common/Peggle Deluxe/Peggle.exe`
- Compatibility tool: Proton 11.0 (ARM64), local wrapper
  `compatibilitytools.d/proton-11-arm64`
- APK SHA-256:
  `3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a`
- Presentation: hardware-backed Termux:X11 Android SurfaceView, 1280×960
- Steam client: software GL (`swrast`, `softpipe`,
  `LIBGL_ALWAYS_SOFTWARE=1`), explicit Freedreno ICD retained
- Steam UI mode: minimal
- Temporary mapped config SHA-256:
  `3762bb8d7f92336a7091da4a7a7ec7e2bdb44699c8f350d8cf79247d39c01518`
- Pre-run/restored config SHA-256:
  `f28292d898bfb5844367a2227d6701dc6e49de66b5a3eac77adf269772d08d5b`

The run was predeclared and pushed in
[`docs/239-nova-peggle-steam-applaunch-proton11-run-2026-08-10.md`](239-nova-peggle-steam-applaunch-proton11-run-2026-08-10.md),
commit `34875e8`.

## Fresh Steam session

The one-click launcher started a fresh authenticated session with:

```text
nova_launcher_hardware_accel=1
nova_launcher_cef_disable_gpu=1
nova_launcher_steam_ui_mode=minimal
nova_launcher_steam_force_software_gl=1
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The session D-Bus bus was
`/tmp/nova-steam-runtime/dbus-session-1133/bus`. The prelaunch screenshot
was a live Steam desktop frame, SHA-256
`479d8653057361a7a249666ea0dda83fedc89bbce0812abc09a100ebdc5c6d2f`.

The exact request was sent through the existing private X11/chroot namespace:

```text
NOVA_X11_ALLOW_INPUT_EVENTS=9
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/launcher/nova-x11-private-namespace.sh
chroot-dev
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/launcher/nova-mount-private
/data/local/tmp/nova-holo-rootfs
/usr/bin/setpriv --reuid=501 --regid=20 --groups=1005
/usr/bin/env -i ...
/usr/bin/timeout 30
/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -applaunch 3480
```

The complete command, including all environment variables and library paths,
is retained in
`android/nova-lab/build/runs/steam-game-peggle-proton11-20260810T073154Z/steam-applaunch-command.txt`.
The request returned status `0` with Steam's expected
`Steam is already running, exiting (command line was forwarded)` response.

## Compatibility and game-process result

The AppID-3480 mapping was present in the mapped `config.vdf`, while the
pre-run mapping contained only the existing AppID-1086010 entry. The fresh
Steam log segment then recorded:

```text
StartSession: appID 3480 session 943883714114aada
Command prefix for tool 0 "Proton 11.0 (ARM64)" set to: ".../proton waitforexitandrun"
DEBUG: compat tool = proton11_arm64
OnAppLifetimeNotification: release session(s) for appID 3480
```

The same-run game-process log recorded the real launch tree:

```text
AppID 3480 adding PID 4348 as a tracked process ".../proton-11-arm64'/proton waitforexitandrun .../Peggle Deluxe/Peggle.exe'"
AppID 3480 adding PID 4349 as a tracked process
AppID 3480 adding PID 4352 as a tracked process
AppID 3480 no longer tracking PID 4352, exit code -1
AppID 3480 no longer tracking PID 4349, exit code -1
AppID 3480 no longer tracking PID 4348, exit code 0
Remove 3480 from running list
```

Steam's console log also reached `CreatingProcess`, `WaitingGameWindow`, and
`Completed`, but immediately removed the process. No persistent Wine/FEX game
process appeared in the 250-ms process poll, and all four same-run screenshots
remained the Steam desktop UI. The final screenshot shows the Store page and
Friends window rather than Peggle.

This closes the explicit Proton 11 mapping question for Peggle. Together with
the Geometry Wars result, it makes the early Proton 11/FEX/Wine startup
boundary reproducible across two small Windows games. It does not yet identify
the inner Proton failure or provide a game frame, controller path, audio path,
or game-session aspect-ratio result.

## Cleanup and state restoration

- `nova_x11_cleanup=pass`
- `nova_runtime_cleanup=pass`
- no matching Nova, Gamescope, Steam, webhelper, Proton, Wine, FEX, or
  Termux:X11 process after the settled check
- no Nova rootfs mount remained
- the temporary AppID-3480 mapping was removed by restoring `config.vdf`
  byte-for-byte; before and restored hashes are identical
- exact stale Steam singleton, Wine-server, and CEF shared-memory sockets
  from the stopped session were removed after confirming no corresponding
  process remained
- final rootfs sockets contain only the reusable baseline udev sockets:
  `/run/udev/control` and `/run/udev/io.systemd.Udev`

## Artifacts

- launcher log SHA-256 `7d8a523ab006a2f3b941941fdee3973e5b98e17763f23d24fbac77477bb8f94f`
- mapped config SHA-256 `3762bb8d7f92336a7091da4a7a7ec7e2bdb44699c8f350d8cf79247d39c01518`
- exact Steam request SHA-256 `c1233aa6ac4f36b0d68c929169e54920aff7fe4152f76dfe26e5db6c7e49f9db`
- AppID request status SHA-256 `8dbaf0dfc1ee87ad19ed5ac6b90f6d2af68963a7af1c13ee03ccdd2eb45501fd`
- compatibility log SHA-256 `b9432f55b89103e7e5a587adadd1b4f5c71aa796a522dcf90023396f5c886fde`
- game-process log SHA-256 `414b0791db2d3148edb1b4acd7608360368ac741ad182bc08bf31bc6039ef2f7`
- console log SHA-256 `68c87fc402f4b7a4d92b32e8d89eef3d889ae567f98165d43f8ccf8a6d8daa39`
- process poll SHA-256 `953ab9ec81398ca1057d3b3d7abe614d4dd2169327f85d2942a82df63d596d82`
- final process check SHA-256 `177124e01d6cb174d3d37e72749718d047af5804c9cbb6551df21021e8c1e4ce`
- final mounts check SHA-256 `27bac7946fcc80902b2d01bec45fdcc755b3711493b8cb87608f5ba0ec2e3924`
- final rootfs socket inventory SHA-256 `e85c24c031da253a5b3738ff85fd567af1680c23c4a30c705aaaf35b77eb6bb3`
- Peggle screenshots:
  - `game-screen-01.png`: `dc12df8eed16f57d93ec142d4c29998b148035d4c7b645f47d67065b9b1a29e8`
  - `game-screen-02.png`: `7009c624a31abbc031e996bad248eb79c93ee4e5da3c6faf5678cd5bb95af68f`
  - `game-screen-03.png`: `e32808ef21114b65e37032f956634fc237bf73bdbceb783a01ad1e9d4c741fde`
  - `game-screen-04.png`: `a75f3a4979ed6186fdaa93f24c1643d4152224534af48665582c301b0e8fe44e`
