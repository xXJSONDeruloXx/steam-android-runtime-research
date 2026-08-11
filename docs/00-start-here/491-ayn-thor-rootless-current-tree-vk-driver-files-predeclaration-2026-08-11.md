# AYN Thor rootless current-tree `VK_DRIVER_FILES` selector A/B — predeclaration — 2026-08-11

Run identity: `thor-rootless-current-tree-vk-driver-files-20260811T200332Z`;
sub-run: `R31-current-tree-selector-equivalence`.

Status: predeclared as a separately named selector experiment. This is **not**
the exact historical Thor R31 replication from [doc
475](475-ayn-thor-rootless-r31-vk-driver-files-replication-predeclaration-2026-08-11.md),
because the required `3447515136`-byte archive with SHA-256
`4c62a8e35144b653864c31d84e682814a82384c3746001293e019d98bde25288` remains
unavailable. It is a current-tree equivalence A/B built on the valid R36
result in [doc
490](490-ayn-thor-rootless-public-beta-equivalence-replay-result-2026-08-11.md).
Any result must retain that distinction.

## Question and controlled variable

R36 proved that the current sanitized public-beta tree crosses the rootless
`vgui2_s` boundary and reaches SteamUI/webhelper startup with both Vulkan
selectors unset. This run asks whether selecting the same pinned KGSL/Turnip
manifest through `VK_DRIVER_FILES` changes Vulkan provider discovery or
physical-device enumeration.

Relative to R36, the only effective guest-environment change is:

```text
unset VK_ICD_FILENAMES
export VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH
```

Do not add `LIBGL_DRIVERS_PATH`, `TU_DEBUG`, WSI variables, `/dev/shm`, a
machine-id, D-Bus, Runtime 4, Proton, FEX, Gamescope/AHardwareBuffer,
SteamUI changes, or packaging changes. The current public-tree archive is
only an immutable staging input; Steam HOME, state, logs, updater files,
temporary paths, X11, sockets, screenshots, and readiness are fresh.

## Device and scopes

```text
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
root=available (Magisk uid 0)

/data/local/tmp/thor-rootless-current-tree-vk-driver-files-20260811T200332Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r31-current-tree/
/data/data/com.termux/files/home/.nova-rootless/
```

The APK bridge may still use the default Termux helper scope because the
current `RootlessTermuxBridge` does not propagate a custom state path into the
Termux-sourced helper. Record and remove only the exact default PID/log files
created by this run.

Preserve the existing rooted control paths and do not use their mutable Steam
state as rootless HOME:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Current-tree provenance gate

The sanitized client tree is recreated from the preserved rooted public-beta
tree using the exclusions recorded in [doc
488](488-ayn-thor-rootless-exact-public-beta-recovery-gate-result-2026-08-11.md).
No authenticated home, `userdata`, `config`, logs, cookies, tokens, QR state,
or Steam library may be copied. Require these selected hashes before launch:

```text
archive_bytes=3457525760
archive_sha256=9a3507ce029c0aebe28ebd54ae03f79b56b1899e6ad4e530c88e9d33cbd0e7bb
package/beta_sha256=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
steamrtarm64/steam_sha256=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so_sha256=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so_sha256=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper_sha256=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
installed_manifest_sha256=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
```

The immutable Holo/PRoot/provider inputs remain:

```text
holo_rootfs_bytes=384971555
holo_rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_closure=161 packages
libvulkan_freedreno.so_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
```

## Fixed launch contract

Keep R36's app-UID PRoot `-0`, nested `/opt/nova-steam/home/.local/share/Steam`
layout, Holo ARM64 closure, `/dev` and `/proc` binds, resolver, fresh state,
direct TCP Termux:X11, `DISPLAY=127.0.0.1:77`, and flags fixed:

```text
HOME=/opt/nova-steam/home
USER=steam
LOGNAME=steam
LANG=C
LC_ALL=C
XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin
LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio
DISPLAY=127.0.0.1:77
```

The guest command must remain the R36 command except for the selector block:

```text
/bin/sh -c 'export HOME=/opt/nova-steam/home; export USER=steam; export LOGNAME=steam; export LANG=C; export LC_ALL=C; export XDG_RUNTIME_DIR=/tmp/nova-steam-runtime; export PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin; export LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio; unset VK_ICD_FILENAMES; export VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json; unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH; mkdir -p "$XDG_RUNTIME_DIR"; cd /opt/nova-steam/home/.local/share/Steam; exec /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -skipinitialbootstrap -no-child-update-ui'
```

## Evidence and decision

Before launch, capture selected hashes, fixture marker, app UID and SELinux
identity, free space, read-only `/dev/kgsl*` metadata, exact PRoot command,
effective environment, fresh X11 PID/listener/handshake, and the Android
device-log consent state. If the consent dialog appears, inspect it and
choose only one-time access; if absent, record `not-shown`.

Capture fresh Steam bootstrap/client, `steamsysinfo`, SteamUI system/HTML,
webhelper, X11, process/listener, screenshot, and cleanup evidence. Record
Vulkan provider discovery separately from physical-device enumeration and
separately from presentation/WSI.

Classify only as:

- `selector-pass-enumeration`: the configured ICD/driver is found and at least
  one Vulkan physical device enumerates, while the R36 `vgui2_s` boundary
  remains closed;
- `selector-nondiscriminating`: R36's Vulkan failure repeats without the R29
  crash, meaning this selector does not yet close the provider boundary;
- `selector-crash-boundary`: the R29 updater/X11 `SIGSEGV` returns; or
- `invalid`: any provenance, fixture, device, UID, scope, freshness,
  environment, lifecycle, or authentication violation.

If enumeration succeeds, do not claim Vulkan presentation or WSI success.
Do not choose a `/dev/shm` or D-Bus experiment until this result is written
and committed. If the selector is non-discriminating, stop at the loader
result and predeclare the next single provider/loader diagnostic separately.

## Cleanup and authentication boundary

After capture, stop only this app/X11 session, remove only the exact R31
current-tree app/device/helper scopes, restore any temporary Termux setting
byte-for-byte, verify no Steam/PRoot/webhelper/X11 process or port 6077
listener remains, and verify the rooted control paths are intact. Remove the
large sanitized staging archive after its hash is recorded. No Steam
authentication secret, session token, cookie, QR state, machine-auth file, or
authenticated Steam home may be read, copied, backed up, committed, or
exported.
