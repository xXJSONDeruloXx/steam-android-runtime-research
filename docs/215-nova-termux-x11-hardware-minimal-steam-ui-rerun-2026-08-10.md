# Nova Termux:X11 hardware minimal Steam UI rerun — 2026-08-10

Status: predeclared; no device session has been launched under this run.

## Question

The hardware profile reaches Android Adreno EGL, XCB, and shared-buffer
readiness, but Steam's ARM64 client exits with `139` before a frame. The same
failure persists with CEF GPU disabled. The remaining high-value startup split
is whether the SteamOS/GamepadUI flags themselves trigger the crash.

This run keeps the hardware Freedreno ICD, cache ownership repair, D-Bus setup,
network compatibility shim, fullscreen/full-desktop presentation, and
`-cef-disable-gpu` unchanged. It changes only the Steam UI mode from the
product default `gamepadui` to `minimal`, removing
`-gamepadui -steamos3 -steampal -steamdeck`. The default application mode is
not changed by this experiment.

## Run identity

Run ID: `steam-20260810T053732Z-hardware-minimal-ui`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`;
- branch `feat/nova-one-click-launcher`, source commit `0264aa1`;
- rebuilt/installable Nova APK SHA-256:
  `4359373387dac3073a4f2238f81416ca466bfba9f2de4cbe3e9bf2ee197c55e3`;
- rootfs `/data/local/tmp/nova-holo-rootfs`;
- Termux:X11 display `:0`, fullscreen/full-desktop target `1280x960`;
- `hardware_accel=true`;
- explicit ICD `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`;
- `cef_disable_gpu=true`;
- `steam_ui_mode=minimal`;
- no audio bridge, game launch, or synthetic/physical input action.

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
  --ez cef_disable_gpu true --es steam_ui_mode minimal
```

Acceptance requires fresh logs for `hardware_accel=1`,
`cef_disable_gpu=1`, and `steam_ui_mode=minimal`; the Freedreno ICD with
software Mesa overrides unset; a final flag list containing neither
`-gamepadui` nor the SteamOS/GamepadUI flags; `client_started=pass`; and a
non-crash Steam process boundary. A stable same-run screenshot is required to
claim that Steam reached a visible UI. A client crash remains a startup
boundary result, not a game or input result.

After capture, run the exact X11 and rootfs cleanup helpers and verify no
matching process, mount, socket, deleted run-log handle, or temporary launcher
state remains. Commit and push the result before the next rendering, input,
audio, networking, or game experiment.
