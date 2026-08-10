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
