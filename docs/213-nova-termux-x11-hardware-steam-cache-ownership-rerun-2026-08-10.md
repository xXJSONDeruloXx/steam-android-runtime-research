# Nova Termux:X11 hardware Steam cache-ownership rerun — 2026-08-10

Status: predeclared; no device session has been launched under this run.

## Question

The clean hardware Steam run reached Termux:X11/Adreno EGL/XCB/shared-buffer
readiness but Steam segfaulted before a frame. Its fresh stderr also reported
that `/opt/nova-steam/home/.cache/mesa_shader_cache` could not be created.
Device inspection confirms that both `.cache` and `mesa_shader_cache` are
`root:root` mode `700`, while the client is intentionally launched as UID 501.

This rerun tests that concrete ownership boundary. It keeps hardware CEF
enabled and keeps the explicit Freedreno ICD and all presentation flags
unchanged; the only changed runtime behavior is that the client repairs the
ownership and mode of this disposable Mesa cache directory before Steam
starts. The software profile remains the default and the repair is scoped to
the cache path, not the Steam home or account data.

## Run identity

Run ID: `gpu-20260810T050644Z-x11-steam-hardware-cache-ownership`

Profile:

- Retroid Pocket Nova, Android 13, adb serial `675a2365`;
- branch `feat/nova-one-click-launcher`, source commit `efd2896`;
- rebuilt/installable Nova APK SHA-256:
  `e7cdae57222a366b3415b8f81eafc949203597f17241873997d1459a7a2db270`;
- rootfs `/data/local/tmp/nova-holo-rootfs`;
- Termux:X11 display `:0`, fullscreen/full-desktop target `1280x960`;
- hardware profile `hardware_accel=true`, explicit ICD
  `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`;
- CEF GPU remains enabled (no `-cef-disable-gpu`);
- no audio bridge or controlled input event in this bounded run.

This document is committed and pushed before installing the APK or launching
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
  --ez run_steam_session true --ez hardware_accel true
```

A successful hardware/UI result requires fresh launcher readiness, the client
log to record `client_mesa_shader_cache_owner_status=pass` and the explicit
ICD with software Mesa overrides unset, `client_started=pass`, a non-crash
Steam process boundary, and a same-run stable Steam screenshot. A cache repair
pass without a Steam frame is only a startup-boundary result. Capture fresh
Steam stderr/minidump evidence if it still fails.

After capture, run the exact X11 and rootfs cleanup helpers and verify no
matching process, mount, socket, or temporary launcher state remains. Commit
and push the result before the next CEF, input, audio, or game experiment.

## Result

Status: completed; the cache ownership repair passed, but it did not unblock
the hardware Steam client.

The fresh launcher session was
`20260810T050818Z-23720`. The expected hardware profile was selected:

```text
nova_launcher_hardware_accel=1
nova_launcher_vulkan_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
nova_launcher_ready=pass display=:0 geometry=1280x960
```

The client repaired the cache boundary and retained the hardware environment:

```text
client_runtime_owner_status=pass
client_mesa_shader_cache_owner_status=pass
client_mesa_shader_cache_dir=/opt/nova-steam/home/.cache/mesa_shader_cache
client_mesa_driver=unset
client_gallium_driver=unset
client_libgl_always_software=unset
client_vk_icd=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
client_started=pass
```

The hardware branch kept CEF GPU enabled: `client_flags_final` contained no
`-cef-disable-gpu`.

Post-run device inspection confirmed both cache directories are now owned by
`501:20` with mode `700`. The cache hypothesis is therefore disproved as the
root cause of the hardware startup failure.

The display boundary still passed. Fresh server output loaded Android Adreno
EGL (`libEGL_adreno.so`, driver `0676.53`, EGL 1.5), completed XCB setup, and
sent and received 1280x1024 and 1280x960 shared buffers. The Steam client then
exited with status `139` before producing a usable Steam frame. Fresh stderr
reported CrashID `bp-fad92c66-dc36-414e-a837-ce0e72260809`; no device minidump
was retained after cleanup. The captured screenshot is only the Nova launcher
showing `Nova launcher exited with status 143`, not Steam UI.

The client log also records successful network-compatibility, D-Bus, and
installation probes. This run did not exercise Proton or a game because the
Steam client failed before the library became available. In particular, it is
not evidence that Geometry Wars or another small title fails at game launch.

Fresh artifacts were retained at
`/tmp/gpu-20260810T050644Z-x11-steam-hardware-cache-ownership/`:

| Artifact | SHA-256 |
| --- | --- |
| `launcher.log` | `6a0aba61224939d9e6f8066bcc1bb25cbf5e046bbf40d1f3abf133c85e110ada` |
| `client.log` | `6074adccf8dad542811c438415e1c66d10ccb7813527941acb702cd3dc06c755` |
| `server.log` | `ae8e2184e4e9b2341dfc69734aa0f35958a2ae4b7f2273ae230a7c319980c48d` |
| `client-stderr.log` | `cce0da1d3837ddcb5263c9c0a447bb981cbbeac19e8083f7ce22f9199e97a784` |
| `client-stdout.log` | `e7a3de096b981f2fadf271a67881392867aa0bcceffb3e9f701aecbcf8c376fa` |
| `screen-00.png` | `294c8ea1524e5ba28b65293df3a0a8f6979d9e3ebb2615368c9d8bfa3f2979f5` |
| `logcat.txt` | `f3938fcd44d13d140a81f6b9e118720ec2adbfdb3dfacaeb8d93460811106dcc` |

The exact X11 cleanup helper and rootfs cleanup helper both returned `pass`,
and the post-cleanup process, socket, and mount checks were clear. The next
controlled experiment should add an independent CEF-GPU switch, preserving
the hardware ICD and environment while testing `-cef-disable-gpu`; it should
not be described as a game-launch result unless Steam first reaches the
library.
