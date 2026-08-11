# AYN Thor rootless current-tree Vulkan-loader diagnostic — predeclaration — 2026-08-11

Run identity: `thor-rootless-current-tree-vk-loader-debug-20260811T204834Z`;
sub-run: `R32-current-tree-loader-debug`.

Status: predeclared as the single next experiment after [doc
492](492-ayn-thor-rootless-current-tree-vk-driver-files-result-2026-08-11.md).
This is a diagnostic run, not a provider-success claim and not the historical
exact-client R31 replication.

## Question and one changed variable

The current-tree selector run ended before any Vulkan loader evidence. Static
inspection shows that both the Holo and SteamRT-first Linux loaders contain
`VK_DRIVER_FILES`, `VK_ICD_FILENAMES`, and `VK_LOADER_DEBUG`, but static strings
do not show whether the Steam process reached the loader or whether its
virtual-root identity caused the selector to be ignored.

R32 changes exactly one guest environment variable relative to the valid
current-tree selector fixture:

```text
export VK_LOADER_DEBUG=all
```

It retains:

```text
unset VK_ICD_FILENAMES
export VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH
```

`VK_LOADER_DEBUG` is observation-only. It must not be accompanied by
`VK_LOADER_DRIVERS_SELECT`, `VK_LOADER_DRIVERS_DISABLE`, Mesa overrides,
`LIBGL_DRIVERS_PATH`, WSI variables, software rendering, or a PRoot/UID
change.

## Fixed identity and scopes

Use the same verified Thor and current-tree fixture contract:

```text
device_model=AYN Thor
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
app_selinux=u:r:runas_app:s0:c138,c256,c512,c768
rootless_outer_uid=10138
rootless_guest_mode=PRoot -0
```

Use fresh scopes; do not reuse R31 state, logs, X11, sockets, screenshots, or
readiness:

```text
/data/local/tmp/thor-rootless-current-tree-vk-loader-debug-20260811T204834Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r32-current-tree/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve and verify before and after the run:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

Require the current-tree equivalence hashes and pinned provider hashes from
[doc 491](491-ayn-thor-rootless-current-tree-vk-driver-files-predeclaration-2026-08-11.md)
before launch. Do not recover or use authenticated Steam state.

## Fixed launch contract

Keep the R31 current-tree selector fixture unchanged except for
`VK_LOADER_DEBUG=all`:

```text
HOME=/opt/nova-steam/home
USER=steam
LOGNAME=steam
LANG=C
LC_ALL=C
XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
DISPLAY=127.0.0.1:77
PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin
LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio
VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
VK_LOADER_DEBUG=all
```

Keep app-UID PRoot `-0`, `/dev` and `/proc` binds, resolver, fresh app-owned
temporary paths, direct TCP Termux:X11, fresh port 6077, the same Steam flags,
and the same nested client layout. Do not add `/dev/shm`, machine-id, D-Bus,
Runtime 4, Proton, FEX, Gamescope/AHardwareBuffer, SteamUI changes, or
packaging changes.

## Required evidence

Capture before launch:

- current-tree, rootfs, provider, PRoot, and both loader hashes;
- outer UID/SELinux identity and inner PRoot identity;
- free space and exact fresh scopes;
- exact effective environment and command;
- fresh X11 PID, TCP listener, handshake, and consent-dialog state;
- read-only `/dev/kgsl*` metadata.

Capture from the same run:

- `VK_LOADER_DEBUG` output from the actual Steam process and any child that
  reaches Vulkan;
- whether the loader reports an elevated/super-user environment and ignores
  `VK_DRIVER_FILES`;
- whether it reads `/opt/nova-kgsl-driver/freedreno-kgsl.icd.json`;
- manifest parse errors, library open/dependency errors, or Turnip/KGSL
  errors;
- Steam bootstrap, `steamsysinfo`, SteamUI/webhelper, X11, process/map,
  listener, and screenshot evidence;
- physical-device enumeration separately from presentation/WSI.

`VK_LOADER_DEBUG=all` is the sole diagnostic change. A missing loader line is
itself evidence that the process terminated before the loader boundary; it is
not permission to add another variable in the same run.

## Decision tree

1. **Loader honors selector and opens the manifest:** record provider
   discovery, then classify physical-device enumeration and later SteamUI,
   `/dev/shm`, D-Bus, and WSI boundaries independently.
2. **Loader explicitly ignores the selector for elevated/super-user state:**
   record the concrete loader message. Do not change PRoot or UID in R32; the
   next experiment would need a separate predeclaration for that identity
   contract.
3. **Loader reports a parse, dependency, or provider-open failure:** classify
   the concrete loader boundary. Do not add Mesa variables or services in R32.
4. **No loader evidence and signal 35/early exit repeats:** classify the
   failure as an earlier PRoot/process boundary; do not call it KGSL denial.
5. **Vulkan enumerates:** record that separately from WSI/presentation and
   stop before `/dev/shm` or D-Bus changes are proposed.

## Cleanup and acceptance

Use exact-scope cleanup on every exit. Verify that the R32 device, app, and
Termux helper scopes are absent; no matching Steam/PRoot/webhelper/X11 process
or port-6077 listener remains; the Termux settings file is byte-for-byte
restored; and the rooted rollback paths remain present. Record post-cleanup
free space and retain only sanitized host evidence.

The run is invalid for any wrong device, hash, UID, selector, fixture, scope,
freshness, authentication exposure, `su`/root launch, PRoot change, or
undeclared subsystem change.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents may be read, copied,
backed up, committed, or exported.
