# Nova Termux:X11 hardware Steam CEF-disabled rerun — 2026-08-10

Status: predeclared; no device session has been launched under this run.

## Question

The hardware profile has passed the Android Adreno EGL, XCB, and shared-buffer
boundary, but the ARM64 Steam client still segfaults before displaying Steam
UI. The shader-cache ownership repair also passed without changing that
outcome. The remaining controlled split is whether Steam’s CEF GPU startup
path is the crashing component.

This run keeps the hardware profile, explicit Freedreno ICD, fullscreen
presentation flags, D-Bus setup, network compatibility shim, and cache repair
unchanged while explicitly adding `-cef-disable-gpu`. It does not change the
software profile’s existing default, which already disables CEF GPU. A stable
Steam frame is required before treating any later library or game behavior as
a result of this run.

## Run identity

Run ID: `gpu-20260810T051412Z-x11-steam-hardware-cef-disabled`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`;
- branch `feat/nova-one-click-launcher`, source commit `e5793d0`;
- rebuilt/installable Nova APK SHA-256:
  `762740f33d011a4b35ed5111513d051cd44e24bf6272c1a2a8c76ac1ecedf77d`;
- rootfs `/data/local/tmp/nova-holo-rootfs`;
- Termux:X11 display `:0`, fullscreen/full-desktop target `1280x960`;
- hardware profile `hardware_accel=true`, explicit ICD
  `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`;
- independent CEF setting `cef_disable_gpu=true`;
- no audio bridge or controlled game-launch action in this bounded run.

The source change and APK build completed before this predeclaration. This
document must be committed and pushed before installing the APK or launching
the device session.

## Controlled baseline and acceptance

Before installation and launch, force-stop the Nova and Termux:X11 packages,
run the exact X11 and rootfs cleanup helpers, and verify no matching process,
mount, socket, or launcher state remains. Install only the rebuilt APK with
`adb install -r`; do not remove Steam, games, prefixes, account state, or
shader-cache contents.

Launch with:

```text
am start -W -n com.xjsonderulo.steamandroid.novalab/.LauncherActivity \
  --ez run_steam_session true --ez hardware_accel true \
  --ez cef_disable_gpu true
```

Acceptance requires fresh launcher readiness, explicit logs for
`hardware_accel=1` and `cef_disable_gpu=1`, the Freedreno ICD with software
Mesa overrides unset, `client_started=pass`, a non-crash Steam process
boundary, and a same-run stable Steam screenshot. If Steam reaches the
library, capture the exact screenshot and only then attempt one small library
title, beginning with Geometry Wars if its installed state is confirmed.

After capture, run the exact X11 and rootfs cleanup helpers and verify no
matching process, mount, socket, or temporary launcher state remains. Commit
and push the result before any game, input, audio, or networking experiment.
