# Nova Proton 11 ARM64 Peggle Deluxe experiment — 2026-08-10

Status: predeclared; no device launch has been run under this experiment yet.

## Question

Geometry Wars reached Proton 11 ARM64, FEX, Wine, and Direct3D 9 but crashed
before producing a frame. Peggle Deluxe is a much smaller, older 2D Windows
game in the same signed-in library. It is a useful control for determining
whether the failure is general to this 32-bit FEX path or specific to Geometry
Wars' executable/startup behavior.

This experiment will ask the signed-in Steam client to install AppID `3480`
through `steam://install/3480`, then run `peggle.exe` through the retained
Proton 11.0 (ARM64) wrapper. The download is an intentional device-state
change for the requested small-game comparison; no existing game, prefix,
account, or shader-cache data will be removed.

## Run identity

Run ID: `proton-arm64-20260810T041139Z-peggle-deluxe-install-and-launch`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`;
- branch `feat/nova-one-click-launcher`, source commit `640b314`;
- rootfs `/data/local/tmp/nova-holo-rootfs`;
- Steam AppID `3480`, expected name `Peggle Deluxe`;
- expected executable `steamapps/common/Peggle Deluxe/peggle.exe`;
- Proton package AppID `4628740`, Steam directory `Proton 11.0 (ARM64)`;
- Termux:X11 display geometry `1280x960` through the existing one-click APK.

This document is committed and pushed before requesting the download or
starting the bounded launch.

## Controlled variables

The run will retain the successful X11/Steam display path and the explicit
Proton 11 ARM64 wrapper:

1. install only AppID `3480` through Steam;
2. use a new AppID-3480 compatdata path, copying only the known-good Proton 11
   ARM64 198X prefix template if a default prefix again produces unusable
   relative kernel32 links;
3. add only the empty
   `HKLM\\Hardware\\Description\\System\\CentralProcessor\\0` section
   required by the earlier FEX startup boundary;
4. run `peggle.exe` directly through `proton runinprefix` without
   `VK_ICD_FILENAMES`;
5. capture fresh readiness, process lifetime, Proton/Wine/FEX log, return
   status, and same-run screenshots.

## Acceptance and cleanup

Installation success requires a new Steam-owned `appmanifest_3480.acf`, the
expected executable, and recorded package size/hash evidence. Launch success
requires a real `peggle.exe` process and a same-run frame that is not the
unchanged Steam UI; a Proton log alone is only a startup-boundary result.

Before and after the bounded run, use the exact Nova/X11 and rootfs cleanup
helpers. Final checks must show no matching Steam, Wine, FEX, Gamescope,
Termux:X11, relay, mount, or temporary socket. The installed Peggle files and
AppID-3480 compatdata will be retained for follow-up experiments; only
run-specific wrapper staging, generated launcher state, and direct logs are
disposable.
