# Nova Proton 11 ARM64 Geometry Wars experiment — 2026-08-10

Status: predeclared; no device launch has been run under this experiment yet.

## Question

The installed Steam library has only 198X as a Windows game. Geometry Wars:
Retro Evolved is present in the signed-in user's cached library history as
AppID `8400`, with the executable `GeometryWars.exe`, but its app manifest and
game directory are absent from the Nova. It is a useful small-game comparison:
the title is substantially simpler than 198X and may reach a frame even if
198X's Unity startup does not.

This experiment will ask the signed-in Steam client to install AppID `8400`
through Steam's own `steam://install/8400` route, then test the installed
executable with the Steam-downloaded Proton 11.0 (ARM64) package. The game
download is an intentional device-state change requested for this comparison;
no existing game, prefix, account, or shader-cache data will be removed.

## Run identity

Run ID: `proton-arm64-20260810T033239Z-geometry-wars-install-and-launch`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`;
- branch `feat/nova-one-click-launcher`, source commit `5c2ee7d`;
- rootfs `/data/local/tmp/nova-holo-rootfs`;
- Steam AppID `8400`, expected name `Geometry Wars: Retro Evolved`;
- expected executable `steamapps/common/Geometry Wars/GeometryWars.exe`;
- Proton package AppID `4628740`, Steam directory `Proton 11.0 (ARM64)`;
- Termux:X11 display geometry `1280x960` through the existing one-click APK.

This document is committed and pushed before requesting the download or
changing the device's compatibility mapping.

## Controlled variables

The first game run will keep the successful Phase 8 prerequisite and change
only the game executable:

1. deploy the committed chroot-visible `proton11_arm64` wrapper around the
   Steam-owned Proton 11 ARM64 package;
2. create only the empty Wine key
   `HKLM\\Hardware\\Description\\System\\CentralProcessor\\0`, because
   Phase 8 proved that its absence aborts bundled FEX before the game loads;
3. run `GeometryWars.exe` directly through `proton runinprefix` using a fresh
   AppID-8400 compatdata path and run-specific Proton log directory;
4. do not set `VK_ICD_FILENAMES` in this first comparison, preserving the
   Phase 8 direct environment so a result is attributable to the game rather
   than to a simultaneous Vulkan-ICD change;
5. capture the fresh launcher readiness marker, process lifetime, Proton/Wine/
   FEX log, return status, and repeated same-run screenshots.

If Geometry Wars reaches the same Vulkan/llvmpipe boundary, the next separate
experiment may add the launcher's Freedreno ICD environment. If it reaches a
game frame, the result will establish a useful rendering baseline before that
ICD experiment. CPU-feature register values will not be invented in this run.

## Acceptance and cleanup

Installation success requires a new Steam-owned `appmanifest_8400.acf`, the
expected executable, and recorded package size/hash evidence. Launch success
requires a real `GeometryWars.exe` process and a same-run frame that is not
the unchanged Steam UI; a Proton log alone is only a startup-boundary result.

Before and after every bounded run, the exact Nova/X11 and rootfs cleanup
helpers will be used. The final checks must show no matching Steam, Wine, FEX,
Gamescope, Termux:X11, relay, mount, or rootfs temporary socket. The installed
Geometry Wars files and its AppID-8400 compatdata will be retained for follow-up
experiments; only the wrapper, temporary mapping, generated relay/state files,
and run-specific log/staging artifacts are disposable.
