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

## Result

Status: completed; the independent CEF switch was exercised, but disabling CEF
GPU did not prevent the hardware Steam startup crash.

### Storage and asset boundary

The first install attempt returned `INSTALL_FAILED_INSUFFICIENT_STORAGE`.
After reclaiming clearly disposable device data, the APK installed with
`Success` and the device APK SHA matched the host. The first post-install
launch then exposed a separate packaging prerequisite: `prepareLauncherAssets`
failed with `ENOSPC`, leaving the copied root launcher truncated. Its logs are
retained under the run artifact directory’s `stale-assets/` subdirectory and
are not treated as a rendering result.

The storage cleanup preserved the Steam account, game directories, prefixes,
and `Proton 11.0 (ARM64)`. It removed old X11 capture/crash-dump directories,
old staging directories, `Proton 10.0`, `Proton Hotfix`,
`SteamLinuxRuntime_sniper`, `SteamLinuxRuntime_4`, and the unused `steamrt64`
runtime. The valid run began only after the APK-owned asset directory was
recreated and the device reported roughly 2 GiB of data headroom.

### Valid hardware/CEF-disabled run

The valid fresh session used stage token
`20260810T052555Z-5832`. The launcher and client selected exactly the intended
split:

```text
nova_launcher_hardware_accel=1
nova_launcher_vulkan_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
nova_launcher_cef_disable_gpu=1
nova_launcher_ready=pass display=:0 geometry=1280x960
client_mesa_shader_cache_owner_status=pass
client_mesa_driver=unset
client_gallium_driver=unset
client_libgl_always_software=unset
client_vk_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
client_cef_disable_gpu=1
client_flags_final=... -no-cef-sandbox -cef-disable-gpu -fullscreen -fulldesktopres
client_started=pass
client_status=139
```

The display boundary remained healthy: fresh Termux:X11 output loaded Android
Adreno EGL (`libEGL_adreno.so`, driver `0676.53`, EGL 1.5), completed XCB
setup, and exchanged 1280x1024 and 1280x960 shared buffers. Network API
compatibility, system/session D-Bus, cache ownership, and client installation
probes also passed.

Steam still segfaulted before a usable frame. Fresh stderr reported CrashID
`bp-b1566d88-bde2-4b47-a8fb-1439a2260809`, and the matching device minidump was
pulled before cleanup. The captured screen is an Android “Google Play services
keeps stopping” dialog, not Steam UI. This run therefore disproves “CEF GPU
alone is the hardware Steam startup root cause”; it does not test Proton or
Geometry Wars. Geometry Wars remains installed, but no game-launch result is
valid until Steam survives startup.

Fresh valid-run artifacts are retained at
`/tmp/gpu-20260810T051412Z-x11-steam-hardware-cef-disabled/`:

| Artifact | SHA-256 |
| --- | --- |
| `launcher.log` | `6422d5896a91350510327a2f05e5a0704ffd41059e78caec0eccc0d24796f15d` |
| `client.log` | `3d39c64e3d4e515a83d8cf20d6dc1834beddd1f04c2cf6b8293def25b2659360` |
| `server.log` | `4cec684204fe628bcdd78c20abe40fd1d6ddfd24d47a9ec69e997f08f2300bdd` |
| `client-stderr.log` | `07f0cd117ee75f749c3014426b989d6d4884eb391f31495363f868298fb2b3c5` |
| `client-stdout.log` | `e7a3de096b981f2fadf271a67881392867aa0bcceffb3e9f701aecbcf8c376fa` |
| `screen-00.png` | `a8e89ec799379c7c3f28c0a0d2840c67279ad75fc7bdb5e31a4d0c02e157ba62` |
| `logcat.txt` | `f702475f9f8211be67b8d7e4b7ffb13cbf00702e0fc1e585c73e3b7a455b82fe` |
| `device-crash_20260810052602_3.dmp` | `acee8c079512fb53d60d8bf9d162ce982a6a8f24ef72ee298e6e0ef3c15c8820` |
| `cleanup.log` | `c8d368faba3503cb6b7b2604b7b18a4bb5173c69aa85e0398b5d61c49e2d9022` |
| `runtime-cleanup.log` | `5a25a88e8c23ba7d4bf920acd659bfcef589f9133a1ec24683d6504cac6436ef` |

The exact X11 cleanup helper recorded `nova_x11_cleanup=pass`; the runtime
cleanup helper recorded `nova_runtime_cleanup=pass`. Post-cleanup checks found
no Gamescope, Xwayland, Steam, Termux:X11, matching socket, or rootfs mount.
The per-run launcher logs remain on the device and in `/tmp` for provenance.

The next useful experiment is no longer another game title. It should isolate
the Steam binary/runtime crash itself—e.g. a minimal direct Steam launch with
the same display and UID boundary but without `-gamepadui`/Steam Deck flags—or
revisit the known software profile as a control. Geometry Wars should begin
only after one of those profiles produces a fresh stable Steam library frame.
