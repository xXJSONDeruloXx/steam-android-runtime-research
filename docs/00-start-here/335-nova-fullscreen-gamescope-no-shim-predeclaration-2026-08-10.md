# Nova full-screen Gamescope/no-shim Steam predeclaration

Date: 2026-08-10

Status: predeclared; no device run has been counted yet

## Objective

Establish the next end-to-end presentation gate after the direct Termux:X11
provisioning result: native ARM64 Steam running inside the Nova headless
Gamescope/Xwayland session, rendered through the device-facing 1280×960
fullscreen AHardwareBuffer path, with the SteamOS host-update shim disabled.

This is an isolated Gamescope experiment. It does not modify the direct-X11
APK profile or reintroduce the removed OOBE completion/restart rewrites.

## Planned run identity

```text
run_id=nova-gamescope-fullscreen-no-shim-20260810T194812Z
run_profile=manual-long-lived
device=Retroid Pocket Nova / adb 675a2365
root=/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
legacy_root=/data/local/tmp/nova-holo-rootfs
```

The run will use a freshly rebuilt Gamescope artifact from the pinned local
`gamescope-valve` checkout and will record its source commit, patch fingerprint,
binary SHA-256, libei status, presentation mode, input mode, and output
geometry. The current Holo/SteamRT3C runtime and Turnip ICD stay unchanged.

## Variables held constant

- host updater path absent; no `steamos-update` no-op helper installed;
- direct ARM64 Steam client and SteamRT3C runtime;
- network compatibility helper only at its current narrow API boundary;
- `-gamepadui -steamos3 -steampal -steamdeck` client mode;
- 1280×960 output, fullscreen presentation, Xwayland, libei touch bridge,
  physical uinput relay, and the exact-scope cleanup helper;
- no Steam authentication export or copying of the logged-in data tree.

The first pass will use Gamescope hardware rendering and Steam's normal Mesa
selection. If the Steam client itself fails at Vulkan/WSI, that is recorded as
a client-facing presentation failure; it must not be “fixed” by silently
switching the acceptance run to software GL.

## Acceptance and evidence

The run passes only if fresh artifacts establish all of the following:

1. Gamescope starts with the declared artifact and stays alive.
2. The Android capture shows the current Steam frame at 1280×960, correlated
   with the same-run X11/SteamUI state rather than a stale screenshot.
3. Physical gamepad navigation and Android touch both produce a visible Steam
   UI change through the Gamescope input path.
4. Rootfs network access and Steam's current UI route remain live.
5. The audio bridge starts and records actual PCM activity, or the failure is
   classified at the device sink boundary.
6. Logs show whether Turnip/Vulkan initialization succeeds and where any WSI
   or compositor failure occurs.

OOBE progression to the login/QR surface is a separate gate after the first
   frame is proven. The run stops and cleans up if the display, process, or
   artifact identity is ambiguous.

## Teardown

The exact-root cleanup helper must run before launch, on bounded stop, and on
any interruption. The final record must show no matching Gamescope, Xwayland,
Steam, webhelper, libei, or uinput process; no exact X11 socket; no leaked
temporary mount/bridge socket; and clean app-owned runtime files.
