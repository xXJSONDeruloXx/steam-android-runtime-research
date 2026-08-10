# Nova Geometry Wars Steam-applaunch Proton 11 result — 2026-08-10

## Result summary

The missing Steam-mediated Proton 11 comparison is complete. Steam did select
the requested Proton 11.0 (ARM64) wrapper for AppID 8400 and launched the real
Geometry Wars executable, but the wrapper exited immediately before a game
window or frame appeared.

This closes the compatibility-tool-selection question. It does not produce a
new rendering success, controller, audio, or game-presentation path.

## Run identity and provenance

- Run ID: `steam-game-geometry-wars-proton11-20260810T072309Z`
- Run directory:
  `android/nova-lab/build/runs/steam-game-geometry-wars-proton11-20260810T072309Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Executable: `steamapps/common/Geometry Wars/GeometryWars.exe`
- APK SHA-256:
  `3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a`
- Presentation: hardware-backed Termux:X11 Android SurfaceView, 1280×960
- Steam client: software GL (`swrast`, `softpipe`,
  `LIBGL_ALWAYS_SOFTWARE=1`), explicit Freedreno ICD retained
- Steam UI mode: minimal
- Temporary mapped config SHA-256:
  `59cd9c986abb5f0cd66d842c68e099383d476a2bb3c2ec4c63e14341621dc1ae`
- Pre-run/restored config SHA-256:
  `f28292d898bfb5844367a2227d6701dc6e49de66b5a3eac77adf269772d08d5b`

The run was predeclared and pushed in
[`docs/237-nova-geometry-wars-steam-applaunch-proton11-run-2026-08-10.md`](237-nova-geometry-wars-steam-applaunch-proton11-run-2026-08-10.md),
commit `c0ac96c`.

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
`/tmp/nova-steam-runtime/dbus-session-25770/bus`. The prelaunch screenshot
was a live Steam desktop frame, SHA-256
`290da090138f493e6832c94f86f12f9da85105fd553fa2ed7f1f77fbfb6de174`.

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
/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -applaunch 8400
```

The complete command, including all environment variables and library paths,
is retained in
`android/nova-lab/build/runs/steam-game-geometry-wars-proton11-20260810T072309Z/steam-applaunch-command.txt`.
The request returned status `0` with Steam's expected
`Steam is already running, exiting (command line was forwarded)` response.

## Compatibility and game-process result

Fresh compatibility logs show Steam loading the temporary mapping:

```text
Mapping AppID 8400 to tool "proton11_arm64" with priority 250
StartSession: appID 8400 session 2388e92d95081b02
Command prefix for tool 0 "Proton 11.0 (ARM64)" set to: ".../proton waitforexitandrun"
DEBUG: compat tool = proton11_arm64
```

The same-run process poll captured the actual launch tree:

```text
27309 ... pw-audio-namespace -- .../reaper SteamLaunch AppId=8400 -- .../proton-11-arm64/proton waitforexitandrun .../GeometryWars.exe
27310 ... reaper SteamLaunch AppId=8400 -- .../proton-11-arm64/proton waitforexitandrun .../GeometryWars.exe
27311 ... python3 .../proton-11-arm64/proton waitforexitandrun .../GeometryWars.exe
```

Steam then recorded:

```text
AppID 8400 no longer tracking PID 27311, exit code -1
AppID 8400 no longer tracking PID 27310, exit code -1
AppID 8400 no longer tracking PID 27309, exit code 0
Remove 8400 from running list
```

No persistent Wine/FEX game process remained. No fresh Geometry Wars frame
appeared. The four same-run screenshots all remained the Steam desktop UI;
the final screenshot visibly shows the Store page and Friends window rather
than the game.

This is a stronger negative result than the earlier unforced Steam launch:
Steam dispatch, the local Proton 11 ARM64 compatibility mapping, the wrapper,
the real executable path, and the initial Proton process tree are all proven.
The remaining failure is inside the very early Proton 11/FEX/Wine startup
after Steam dispatch, consistent with the earlier direct Geometry Wars
boundary. It is not a Gamescope/AHB presentation failure.

## Cleanup and state restoration

- `nova_x11_cleanup=pass`
- `nova_runtime_cleanup=pass`
- no matching Nova, Gamescope, Steam, webhelper, Proton, Wine, FEX, or
  Termux:X11 process after the settled check
- no Nova rootfs mount remained
- the temporary AppID-8400 mapping was removed by restoring `config.vdf`
  byte-for-byte; before and restored hashes are identical
- three stale Steam CEF shared-memory sockets from the stopped session were
  removed by exact path after confirming no corresponding process remained
- final rootfs sockets contain only the reusable baseline udev sockets:
  `/run/udev/control` and `/run/udev/io.systemd.Udev`

## Artifacts

- launcher log SHA-256 `beb8b1933349364587dc5bc13c10241570dcee6692c97ebf28c3132c90d1b81a`
- compatibility log SHA-256 `1c640228a1c19a113b01e5282f53f3df59a02df4bdfcaeffe1240fa5b7acd654`
- game-process log SHA-256 `e40d3e2bb1ce04e04fb84c66c34940f94937f4f31e186a5dd0a810bf83be01db`
- process poll SHA-256 `e5c5722fd3aefc4239036b4eedbf6f0628bdf83af480fa02c0eadc8bad5340d1`
- final process check SHA-256 `40f8910f70af63a3f42ec55c236ec986fba981927689b7b743aaf0be964fb7fc`
- final mounts check SHA-256 `afbd71dac2d0900b48d4d4811d6e5caa09599ac571fba10b045b5b2f25a0259c`
- final rootfs socket inventory SHA-256 `e85c24c031da253a5b3738ff85fd567af1680c23c4a30c705aaaf35b77eb6bb3`
- Geometry Wars screenshots:
  - `game-screen-01.png`: `f014d74976d68323c9cbe145b24e4d253a3a2d9d7c3b6b1919e94f13f0af9cd9`
  - `game-screen-02.png`: `afb20aed0f2f0673b957fe4e7a3b8fce72a1c3bbb5da64ea58bc7e91a8953672`
  - `game-screen-03.png`: `6652c1889e314453772bc272f93d56771ca2c2480b91eb9aad1fb947d7a50ba8`
  - `game-screen-04.png`: `6b1aa4caef3260c1f93dec333afbd7fb092de47fa84894e7dd951895ca62bcd0`
