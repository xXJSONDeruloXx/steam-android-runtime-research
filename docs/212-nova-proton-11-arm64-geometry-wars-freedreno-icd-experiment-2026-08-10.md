# Nova Proton 11 ARM64 Geometry Wars Freedreno-ICD experiment — 2026-08-10

Status: predeclared; no device game run has been launched under this identity.

## Question

The prior Geometry Wars run reached Proton 11 ARM64, FEX, Wine, and Direct3D
9, but Vulkan physical-device enumeration returned `res -3`, wined3d selected
llvmpipe, and the game ended before a frame. The clean Steam hardware-profile
run separately showed that enabling the same Freedreno environment for Steam's
CEF/UI path currently segfaults before a usable Steam frame.

This run isolates the game-side Vulkan/GL environment. Steam and Termux:X11
will use the known-good software UI profile; only the direct Geometry Wars
process will receive the explicit Nova Freedreno ICD. A game frame would show
that the hardware game path can work even while the Steam CEF path remains
unresolved. A repeat of the prior llvmpipe/FEX failure remains a valid negative
result.

## Run identity

Run ID: `proton-arm64-20260810T044735Z-geometry-wars-freedreno-icd`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`;
- branch `feat/nova-one-click-launcher`, source commit `2bc1f5e`;
- rootfs `/data/local/tmp/nova-holo-rootfs`;
- Steam AppID `8400`, `GeometryWars.exe`, executable SHA-256
  `457340226810ea529310f17875d87201cc93635e5a375ea4b5fdb75361887129`;
- retained Proton 11 ARM64 wrapper
  `compatibilitytools.d/proton-11-arm64` and AppID-8400 compatdata;
- Termux:X11 display `:0`, target geometry `1280x960`;
- `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json` selected only for the
  direct game process.

This document is committed and pushed before the device run. The installed
Geometry Wars files, Proton package, account state, and existing prefix will
be retained. The direct run may update normal Proton/Wine startup metadata;
run-specific logs and temporary launcher state are disposable.

## Controlled variables

1. Run the exact X11 and rootfs cleanup helpers and verify a fresh process,
   mount, socket, and launcher-state baseline.
2. Start the one-click APK with the default software Steam profile so Steam
   establishes the known-good X11 presentation surface at `1280x960`.
3. Invoke the installed `GeometryWars.exe` directly through the retained
   chroot-visible Proton 11 ARM64 wrapper and the existing AppID-8400 prefix,
   preserving the prior direct-run environment except for
   `VK_ICD_FILENAMES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`.
4. Capture the direct command status, process lifetime, Proton/Wine/FEX log,
   Vulkan/renderer selection, and repeated same-run screenshots. A Proton log
   or zero wrapper return code without a real Geometry Wars frame is not a
   rendering pass.
5. Stop the session with the exact helpers and verify that the installed game,
   Proton wrapper, prefix, and Steam state remain present.

No CPU-feature registry values, game binary changes, CEF flags, Gamescope,
AHardwareBuffer, or input/audio changes are part of this run.

## Acceptance and cleanup

A display prerequisite requires fresh `nova_launcher_ready=pass` and X11
readiness. Game startup requires a real Geometry Wars/Wine process and Proton
evidence beyond the prior launch boundary. Game rendering requires a same-run
1280x960 screenshot that is not the unchanged Steam UI. The result will be
classified at the first failed layer.

Before and after the run, use the exact Nova/X11 and rootfs cleanup helpers.
Do not use broad process killing or remove installed game, prefix, Proton,
shader-cache, or account data. Commit and push the result before another
device experiment.
