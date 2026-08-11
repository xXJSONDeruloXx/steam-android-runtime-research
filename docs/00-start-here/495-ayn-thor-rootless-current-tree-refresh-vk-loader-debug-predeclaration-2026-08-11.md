# AYN Thor rootless current-tree refresh Vulkan-loader diagnostic — predeclaration — 2026-08-11

Run identity: `thor-rootless-current-tree-refresh-vk-loader-debug-20260811T210138Z`;
sub-run: `R32b-current-tree-loader-debug`.

Status: predeclared after the invalid fixture gate in [doc
494](494-ayn-thor-rootless-current-tree-vk-loader-debug-fixture-gate-result-2026-08-11.md).
This is the same loader diagnostic as doc 493, with the currently reproducible
current-tree fixture explicitly pinned. It is not a claim that the historical
exact R31 archive was recovered.

## Question and one changed variable

The valid Thor selector run ended before dynamic Vulkan-loader evidence. The
next run keeps the selector and adds exactly one observation variable:

```text
unset VK_ICD_FILENAMES
export VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
export VK_LOADER_DEBUG=all
unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH
```

`VK_LOADER_DEBUG=all` is the only guest-environment change relative to the
current-tree selector fixture. Do not add Mesa variables, WSI tuning,
`VK_LOADER_DRIVERS_SELECT`, `/dev/shm`, machine-id, D-Bus, Runtime 4, Proton,
FEX, Gamescope/AHardwareBuffer, SteamUI changes, packaging changes, or a
PRoot/UID change.

## Reproducible fixture gate

Require this current sanitized public-tree artifact before launch:

```text
archive_bytes=3457525760
archive_sha256=9a3507ce029c0aebe28ebd54ae03f79b56b1899e6ad4e530c88e9d33cbd0e7bb
tar_entries=21513
forbidden_filename_scan=empty
steamrtarm64/steam_sha256=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so_sha256=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so_sha256=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper_sha256=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
package/beta_sha256=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
installed_manifest_sha256=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
```

The immutable Holo/provider/PRoot inputs remain those pinned by [doc
491](491-ayn-thor-rootless-current-tree-vk-driver-files-predeclaration-2026-08-11.md):

```text
holo_rootfs_bytes=384971555
holo_rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_closure=161 packages
libvulkan_freedreno.so_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
proot_sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
```

## Device and fresh scopes

```text
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
rootless_outer_uid=10138
rootless_guest_mode=PRoot -0
/data/local/tmp/thor-rootless-current-tree-refresh-vk-loader-debug-20260811T210138Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r32b-current-tree/
/data/data/com.termux/files/home/.nova-rootless/
```

Recreate Steam HOME, mutable state, logs, resolver, temporary directories,
X11, port 6077, screenshots, and readiness baselines. Preserve and verify:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

## Fixed launch contract

Keep the current-tree selector fixture's Holo/PRoot/direct-TCP-X11 contract:

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

Use the same Steam flags:

```text
-gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -skipinitialbootstrap -no-child-update-ui
```

Keep app-UID PRoot `-0`, `/dev` and `/proc` binds, resolver, fresh app-owned
temporary paths, and no `/dev/shm`, D-Bus, machine-id, Runtime 4, Proton,
FEX, Gamescope/AHardwareBuffer, or privileged helper.

## Evidence and decision

Capture before launch:

- archive/tree, rootfs, provider, PRoot, and loader hashes;
- outer UID/SELinux and inner PRoot identity;
- free space, exact scopes, and read-only `/dev/kgsl*` metadata;
- exact effective environment and command;
- fresh X11 PID/listener/handshake and device-log consent state.

Capture from the same run:

- `VK_LOADER_DEBUG` output from the actual Steam process and children;
- whether the loader honors or ignores `VK_DRIVER_FILES` for the virtual-root
  guest;
- manifest open/parse, dependency, Turnip, KGSL, and physical-device results;
- bootstrap, SteamUI/webhelper, X11, process/map, listener, and screenshot
  evidence, with Vulkan enumeration separated from WSI/presentation.

Classify a loader message as the provider boundary it names. If no loader
message appears and the early signal-35 exit repeats, classify it as an
earlier PRoot/process boundary—not KGSL denial. Do not proceed to `/dev/shm`,
D-Bus, or a UID change until this result is documented.

## Cleanup and authentication boundary

Use exact-scope cleanup on every exit. Verify the R32b device/app/helper
scopes, matching Steam/PRoot/webhelper/X11 processes, and port 6077 are gone;
restore any temporary Termux setting byte-for-byte; verify the rooted rollback
paths; and record post-cleanup free space. No Steam authentication secret,
session token, cookie, QR state, machine-auth file, authenticated Steam home,
or `steam.token` contents may be read, copied, backed up, committed, or
exported.
