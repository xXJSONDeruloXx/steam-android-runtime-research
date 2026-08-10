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

## Result

Status: completed; removing the SteamOS/GamepadUI flags did not prevent the
hardware Steam startup crash.

The valid fresh session used stage token `20260810T053845Z-24693`. The intended
profile was selected and logged by both launcher layers:

```text
nova_launcher_hardware_accel=1
nova_launcher_vulkan_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
nova_launcher_cef_disable_gpu=1
nova_launcher_steam_ui_mode=minimal
nova_launcher_ready=pass display=:0 geometry=1280x960
client_mesa_shader_cache_owner_status=pass
client_mesa_driver=unset
client_gallium_driver=unset
client_libgl_always_software=unset
client_vk_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
client_cef_disable_gpu=1
client_steam_ui_mode=minimal
client_flags_final=... -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui -no-cef-sandbox -cef-disable-gpu -fullscreen -fulldesktopres
client_started=pass
client_status=139
```

The final command line contains neither `-gamepadui` nor
`-steamos3 -steampal -steamdeck`, so the SteamOS/GamepadUI flag hypothesis is
disproved as the sole hardware crash cause. Fresh Termux:X11 output still
loaded Android Adreno EGL (driver `0676.53`, EGL 1.5), completed XCB setup,
and exchanged 1280x1024 and 1280x960 shared buffers. Network compatibility,
cache ownership, and both D-Bus probes also passed.

Steam nevertheless segfaulted before a usable frame. Fresh stderr reported
CrashID `bp-91943c39-bb65-459e-88a1-b398d2260809`; the matching device
minidump was pulled before cleanup. The same-run screenshot is only the Nova
launcher showing exit status `143`, not Steam UI. No Proton, game, input, or
audio result is attributable to this run.

Fresh artifacts are retained at
`/tmp/steam-20260810T053732Z-hardware-minimal-ui/`:

| Artifact | SHA-256 |
| --- | --- |
| `launcher.log` | `35526044cd8ff3f533395f5c48253f16289d7fe650965b00f0812029580e9fdb` |
| `client.log` | `35ed680f133dd0f0e34441c4f2193a2d8e3e1251f9fdabb64f78ad2041dee951` |
| `server.log` | `bb626114edc9c625d5511b3cfecb0e10dd2eba982baf74a05699a9e0c98618e3` |
| `client-stderr.log` | `2da79649dd291322116077a48cf094726696a950c780354d9e5dc6dd3b753a24` |
| `client-stdout.log` | `e7a3de096b981f2fadf271a67881392867aa0bcceffb3e9f701aecbcf8c376fa` |
| `screen-00.png` | `28b688ea56a43a456260dfb1bf0d49f0bbd04bdebb0abdaf5f8da0c7b2b541ed` |
| `logcat.txt` | `60abfe1cef7bfb6034475f939a86350342a405f48d620255fb8e0a3e2d3dab92` |
| `device-crash_20260810053851_3.dmp` | `6e3e861e36776afacd1726cda2a5de94b5c838e3fab640f933ca6ea19e9c2594` |
| `cleanup.log` | `abe10cca67843647059a9ef9f289723156150fae563e1b02512df694e145f0b9` |
| `runtime-cleanup.log` | `9415a03d5a1e57c6179928c8574a990bdeb5e0400fcdc89973b0f59eb852c3d5` |

The exact X11 and rootfs cleanup helpers both returned `pass`. Post-cleanup
checks found no Gamescope, Xwayland, Steam, Termux:X11, Nova-rootfs process,
matching socket, mount, or deleted run-log handle. The device crash-dump
directory was removed only after the minidump was retained on the host.

The hardware crash therefore survives both CEF and SteamOS/GamepadUI flag
isolation. The next controlled gate should move below Steam’s flag layer and
compare the ARM64 Steam binary/runtime startup itself, while preserving the
product default and the known-good software UI path.
