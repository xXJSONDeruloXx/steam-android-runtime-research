# Nova Geometry Wars Steam-applaunch Proton 11 run — 2026-08-10

## Scope

This is the missing Steam-mediated Geometry Wars comparison. The earlier
direct Proton 11 ARM64 run reached FEX/WineD3D but produced no game frame. The
earlier Steam `-applaunch 8400` run used Proton Experimental because AppID
8400 had no explicit mapping. This run keeps the known-good
hardware-backed Termux:X11 display and software-GL Steam client, but changes
the AppID-8400 compatibility mapping to the already-installed local
`proton11_arm64` wrapper before issuing the Steam IPC launch.

It does not change the game files, Proton package, prefix contents, or the
retained AppID-1086010 mapping for 198X. The temporary AppID-8400 mapping is
restored byte-for-byte from the pre-run Steam configuration after evidence
capture.

## Run identity and provenance

- Run ID: `steam-game-geometry-wars-proton11-20260810T072309Z`
- Run directory:
  `android/nova-lab/build/runs/steam-game-geometry-wars-proton11-20260810T072309Z`
- Device: Retroid Pocket Nova, serial `675a2365`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Executable:
  `/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe`
- Compatibility mapping under test: `8400 -> proton11_arm64`
- Compatibility tool: Proton 11.0 (ARM64), wrapper
  `/opt/nova-steam/home/.local/share/Steam/compatibilitytools.d/proton-11-arm64`
- APK: `android/nova-lab/build/nova-lab-debug.apk`
- Expected APK SHA-256 at predeclaration:
  `3d8f2c4b4d91a2979d28c37b840eb929577fa3b07a1f9ae79daa75b65776532a`
- Presentation: hardware-backed Termux:X11 Android SurfaceView, 1280×960
- Steam client: software GL (`swrast`, `softpipe`,
  `LIBGL_ALWAYS_SOFTWARE=1`) with the explicit Freedreno ICD retained
- Steam UI mode: minimal

## Controlled procedure

1. Read the Nova lifecycle contract and verify a fresh baseline: force-stop
   the APK/Termux:X11, run the exact X11 and rootfs cleanup helpers, and verify
   no matching process, mount, socket, or stale launcher state remains.
2. Pull and hash `config/config.vdf` before the mapping change. Confirm that
   AppID 1086010 remains mapped to `proton11_arm64` and record the pre-run
   AppID-8400 state (currently absent).
3. Insert only this temporary `CompatToolMapping` entry while Steam is stopped:

   ```text
   "8400"
   {
       "name"      "proton11_arm64"
       "config"    ""
       "priority"  "250"
   }
   ```

4. Start a fresh one-click launcher session with
   `hardware_accel=1`, `steam_force_software_gl=1`,
   `cef_disable_gpu=1`, and `steam_ui_mode=minimal`. Wait for a fresh
   `nova_launcher_ready=pass` and authenticated Steam UI baseline. Capture a
   same-run prelaunch screenshot and process snapshot.
5. Issue `steam -applaunch 8400` through the existing private X11/chroot
   namespace using the live session D-Bus address. Capture the exact command,
   return status, Steam compatibility/game-process logs, a 250-ms process
   poll for the first five seconds, and repeated 1280×960 screenshots.
6. Accept a game launch only if a fresh Geometry Wars frame appears and the
   Steam tracked command line names `proton-11-arm64`. A Proton process,
   Steam launch event, or wrapper exit without a changed game frame is only a
   startup-boundary result.
7. Terminate only the verified AppID-8400 process tree, restore the original
   `config.vdf` byte-for-byte, run the exact cleanup helpers, and verify no
   Steam, Wine, FEX, Proton, X11, launcher, mount, socket, or deleted-log
   handle remains.

This declaration is committed and pushed before changing the device mapping
or launching the game.

