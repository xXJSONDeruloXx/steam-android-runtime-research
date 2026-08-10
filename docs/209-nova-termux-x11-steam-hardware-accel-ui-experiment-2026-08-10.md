# Nova Termux:X11 Steam hardware-acceleration UI experiment — 2026-08-10

Status: predeclared; no device session has been launched under this run yet.

## Question

The accepted Termux:X11 path reaches the signed-in Steam UI, but its default
profile intentionally forces `swrast`, `softpipe`, `LIBGL_ALWAYS_SOFTWARE=1`,
and `-cef-disable-gpu`. The Nova rootfs and KGSL sidecar can enumerate the
Adreno device through the explicit Turnip ICD, while the previous hardware UI
attempt changed the Vulkan/GL environment and CEF GPU mode together and crashed
before a usable Steam surface. This run tests the current opt-in hardware
profile with a fresh launcher identity.

The result is needed for the end-to-end objective: a visible Steam session with
hardware-accelerated graphics. It is a UI/profile gate only; it does not claim
working game rendering, input, audio, or product readiness unless those are
separately evidenced.

## Run identity

Run ID: `gpu-20260810T042803Z-x11-steam-hardware-rerun`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`;
- branch `feat/nova-one-click-launcher`, source commit `b36f5ab`;
- rootfs `/data/local/tmp/nova-holo-rootfs`;
- one-click launcher assets from the installed Nova Lab APK;
- Termux:X11 display `:0`, fullscreen/full-desktop-resolution flags,
  target geometry `1280x960`;
- explicit ICD `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`;
- hardware profile `NOVA_ANDROID_LAUNCHER_HARDWARE_ACCEL=1`;
- no physical or synthetic input and no audio bridge in this run.

The device-side run will invoke the existing root launcher directly with the
hardware profile. This does not change the product default, the Steam account,
or any game/prefix data.

## Provenance to capture

The result must record the exact current APK, Termux:X11 APK, ICD manifest,
ICD library, rootfs Steam executable, launcher log, X11 log, client log,
Steam stderr, fresh screen capture, and any crash/minidump path and hashes.
Readiness must come from the fresh run marker and current process/log baseline,
not from persistent Steam logs.

## Acceptance and cleanup

A UI-profile pass requires all of the following from this run:

1. `nova_launcher_ready=pass` and an active current Steam process;
2. the hardware variables are visible in the fresh client log, with software
   Mesa forcing variables unset and the explicit ICD selected;
3. fresh Steam/webhelper startup evidence and a same-run screenshot showing a
   stable Steam surface rather than the launcher screen or stale UI;
4. no hardware-profile crash before the visible UI boundary.

A failure still must identify the first failed layer and must not change the
known-good software default. Before launch and after capture, use the exact
Nova/X11 and rootfs cleanup helpers. Verify no matching Steam, Wine, FEX,
Gamescope, Termux:X11, relay, mount, socket, or run-state artifact remains.

This document is committed and pushed before starting the device session.
