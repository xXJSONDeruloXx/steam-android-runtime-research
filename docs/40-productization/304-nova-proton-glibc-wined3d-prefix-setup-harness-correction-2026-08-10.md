# Nova glibc Proton WineD3D prefix-setup control — harness correction — 2026-08-10

## Result

The first correctly scoped glibc WineD3D control did not reach Wine, FEX,
OpenGL, or the game. It did prove that invoking Proton with its normal
`run` action enters Proton's prefix setup path. The run then stopped because
the run-scoped copy of AppID 8400 compatdata had no Proton `tracked_files`
bookkeeping file.

This is a prefix-staging failure, not a renderer result. No conclusion about
WineD3D, software Mesa, FEX, 32-bit startup, or Geometry Wars is valid from
this run.

## Run identity and provenance

- Run ID:
  `nova-glibc-proton-wined3d-prefix-setup-20260810T141007Z`
- Device: Retroid Pocket Nova, adb serial `675a2365`, Android 13, `kalama`
- Rootfs: `/data/local/tmp/nova-holo-rootfs`
- AppID: `8400`, Geometry Wars: Retro Evolved
- Game executable:
  `/opt/nova-steam/home/.local/share/Steam/steamapps/common/Geometry Wars/GeometryWars.exe`
- Game executable SHA-256:
  `457340226810ea529310f17875d87201cc93635e5a375ea4b5fdb75361887129`
- Android APK:
  `android/nova-lab/build/nova-lab-debug.apk`
- Android APK SHA-256:
  `7f94e8bc85717147c2c62b4438fae26a826d1132cbbec4e103c9ddad79b84229`
- Durable wrapper:
  `android/nova-lab/device/nova-proton-glibc-geometry-wars.sh`
- Wrapper SHA-256:
  `b14ce1e9d761440abebee283c9900dd09ef69dda526df36e66a4c531b1ac5846`
- Repository HEAD at setup: `2bf744520714639b83e1b3d13b4f844af6731feb`
- Compatibility tool:
  `/opt/nova-steam/home/.local/share/Steam/compatibilitytools.d/proton-11-arm64/proton`
- Proton prefix version in the installed script: `11.0-100`
- Parent profile: one-click LauncherActivity, hardware acceleration enabled,
  CEF GPU disabled, software GL forced for the Steam client, `gamepadui`,
  fresh Termux:X11 `:0`, Android `1280x960`, stretched X11 `1280x800`

The host evidence directory is:

`android/nova-lab/build/runs/nova-glibc-proton-wined3d-prefix-setup-20260810T141007Z/`

Relevant evidence hashes:

- `game-output.txt`: `411d4d738023d3be376800402442b5f68d2a40acc53b38724e7c8d35c83edf40`
- `parent-launcher.log`: `67896a77971486e8507ace6b070748caccda26e39f6922617f98d946adc1f002`
- `steam-client.log`: `536f404c6b1a99afa41e93c9679267df43d23dc443bd9f844933949091c1215f`
- `screen-before.png`: `d9eafa862cba6cc040baf2dbfc7b6cfeb949984db26498f13d71f0545f91a88d`
- `parent-stop.txt`: `b774f18b2f350afebbc33b92db606573e46b73b9bc62a1e46baa394edafa32a7`

## What passed

The exact prior-session cleanup passed, the parent Steam/X11 session reached
fresh readiness, and the wrapper entered the intended private X11/chroot
namespace as uid 501. Its markers recorded:

```text
mount_private=pass path=/
x11_namespace_input=pass allowed_events=9 hidden_events=
nova_glibc_proton=pass mode=wined3d run_id=nova-glibc-proton-wined3d-prefix-setup-20260810T141007Z
nova_glibc_proton_setup=proton_run
nova_glibc_proton_wined3d=1
nova_glibc_proton_software_gl=swrast/softpipe
nova_glibc_proton_vk_icd=unset
```

The parent also supplied a fresh D-Bus session and X11 socket. The Steam
client log identified the Holo `steamrtarm64`/SteamRT3C ARM64 client runtime,
software Mesa (`swrast`/`softpipe`), and the expected Nova preload.

## First failing boundary

Proton's normal setup path began and reported:

```text
Proton: Upgrading prefix from None to 11.0-100 (.../compatdata/8400/)
```

It then failed before Wine started:

```text
FileNotFoundError: [Errno 2] No such file or directory:
'/tmp/nova-glibc-proton-wined3d-prefix-setup-20260810T141007Z/compatdata/8400/tracked_files'
```

The run-scoped copy was made from the current persistent compatdata. A
read-only device audit after the run found that the persistent source also
contains no `tracked_files`, `version`, or `config_info`; it currently has
`pfx`, `pfx.lock`, and `proton-fex-config.json`. The previous direct
`runinprefix` controls did not require this setup bookkeeping, which explains
why that omission had not surfaced earlier.

## Cleanup

The exact parent stop completed, the run-scoped device staging directory was
removed, the temporary wrapper was removed, and the final exact-scope process
audit was clean. The missing host `game-status.txt` is a harness bookkeeping
gap caused by the host shell variable `status` being read-only; the captured
game output is retained and is sufficient to classify this run as the Proton
setup failure above. Future controls use a different host variable for the
exit code.

## Correction for the next fresh run

Do not alter the persistent signed-in prefix and do not reuse this run ID. For
the next control, copy the same compatdata into a new exact run directory,
create an empty run-copy `compatdata/8400/tracked_files` owned by uid 501/gid
20, and invoke the same Proton `run` action. Proton's setup code reads this
file before updating built-in DLLs and appends its generated entries during
initialization; the correction is therefore limited to staging the missing
bookkeeping boundary, not to adding DLL overrides or changing the renderer.

The corrected run must capture the generated `tracked_files`, `version`, and
`config_info`, plus fresh Proton/Wine logs, before any WineD3D or DXVK result
is classified. It must use a new run identity and be documented and pushed
before the next glibc control.
