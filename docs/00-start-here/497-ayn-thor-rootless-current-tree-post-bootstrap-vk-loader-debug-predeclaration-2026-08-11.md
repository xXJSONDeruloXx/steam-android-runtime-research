# AYN Thor rootless current-tree post-bootstrap Vulkan-loader diagnostic — predeclaration — 2026-08-11

Run identity: `thor-rootless-current-tree-post-bootstrap-vk-loader-debug-20260811T213100Z`;
sub-run: `R33-current-tree-post-bootstrap-loader-debug`.

Status: predeclared as the single next experiment after [doc
496](496-ayn-thor-rootless-current-tree-vk-loader-debug-result-2026-08-11.md).
It tests the rooted post-bootstrap handoff contract; it is not a provider,
`/dev/shm`, D-Bus, Proton, or compositor experiment.

## Question and one changed variable

R32b never called Vulkan. It used the normal updater path and stopped at
Steam's updater UI before creating SteamUI/webhelper. The rooted known-good
path completes the update once and then restarts the already-installed client
with `-nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui`.
Earlier rootless R30 evidence also crossed the client-build/SteamUI system
initialization boundary with that post-bootstrap flag.

R33 changes exactly one thing relative to R32b: add
`-nobootstrapperupdate` to the Steam flags. Keep the R32b selector and loader
diagnostic unchanged:

```text
unset VK_ICD_FILENAMES
export VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
export VK_LOADER_DEBUG=all
unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_DRIVER_PATH
```

Do not add `VK_LOADER_DRIVERS_SELECT`, Mesa variables,
`LIBGL_DRIVERS_PATH`, WSI tuning, software GL, `/dev/shm`, machine-id,
D-Bus, Runtime 4, Proton, FEX, Gamescope/AHardwareBuffer, SteamUI changes,
packaging changes, or a UID, PRoot, client-tree, rootfs, provider, resolver,
or X11 lifecycle change.

## Fixed Thor identity and scopes

```text
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
rootless_outer_uid=10138
rootless_guest_mode=PRoot -0
```

Use fresh state and evidence:

```text
/data/local/tmp/thor-rootless-current-tree-post-bootstrap-vk-loader-debug-20260811T213100Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r33-current-tree/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve and verify untouched:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

The app-owned Steam state, logs, X11 server, socket/listener, screenshots,
and readiness baselines must all be fresh. Do not read or copy authenticated
Steam state.

## Fixed artifacts

Require the reproducible current-tree fixture and the exact R32b inputs:

```text
archive_bytes=3457525760
archive_sha256=9a3507ce029c0aebe28ebd54ae03f79b56b1899e6ad4e530c88e9d33cbd0e7bb
tar_entries=21513
forbidden_filename_scan=empty
installed_manifest_sha256=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
steamrtarm64/steam_sha256=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so_sha256=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so_sha256=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper_sha256=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
package/beta_sha256=ef339938036ee25c4f533210a35791d5faf9f69dcbc72cce173263005500f9e4
holo_rootfs_bytes=384971555
holo_rootfs_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
holo_ui_audio_closure=161 packages
holo_manifest_sha256=f3f46d90ab246dd799cb22d75cbb219ff3c5d8e62f1ce6f53c3847c74238d83f
libvulkan_freedreno.so_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
freedreno-kgsl.icd.json_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
proot_sha256=6ffdff4117c571d07aa7e6f940001f050c97adb920660c984b72d4a537b4f60a
proot_loader_sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04
```

Before launch, run a read-only guest path check for
`/opt/nova-steam/home/.local/share/Steam/clientui/fonts/GoNotoKurrent-Regular.ttf`
and record its mode/hash. This is evidence only and is not an additional
launch variable.

## Fixed launch contract

Retain the R32b environment and direct TCP X11 contract:

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

The only command-line difference is:

```text
-gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox
-nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui
```

Keep the supervisor's app-UID PRoot `-0`, `/dev` and `/proc` binds, fresh
resolver, fresh temporary paths, and exact provider placement. Do not bind
`/dev/shm` or start D-Bus in R33.

## Evidence and decision

Capture before launch:

- archive, rootfs, provider, PRoot, selected-loader, and client-font hashes;
- outer UID/SELinux and inner PRoot identity;
- free space, exact scopes, and read-only `/dev/kgsl*` metadata;
- exact effective environment and command;
- fresh X11 PID/listener/`xprop` handshake and consent-dialog state.

Capture from the same run:

- updater/bootstrap handoff and client build;
- actual `VK_LOADER_DEBUG` lines, selector handling, ICD manifest open/parse,
  dependency resolution, Turnip/KGSL loading, and physical-device count;
- `vgui2_s`/SteamUI/webhelper milestones, `/dev/shm` and D-Bus messages if
  they appear naturally, but do not add either prerequisite;
- process/maps, X11 log, listener state, and a screenshot described by what is
  actually visible.

Classify the result as one of:

1. **Post-bootstrap reaches loader:** classify selector/provider,
   physical-device enumeration, SteamUI, and later prerequisites separately.
2. **Loader explicitly ignores the selector:** require the concrete elevated
   or virtual-root message before designing an identity experiment. Khronos
   documents that driver-file overrides are ignored for genuinely elevated
   Vulkan applications; R33 must determine whether that applies here rather
   than assume it.
3. **Updater handoff still stalls:** classify the post-bootstrap client/font
   path as the first boundary. Do not call it a Vulkan or KGSL result.
4. **`vgui2_s` returns:** treat it as a regression against the R28/R30
   current-tree baseline and compare layout, HOME, cwd, environment, and flags
   before changing anything else.

## Cleanup and authentication boundary

Use exact-scope cleanup on every exit. Verify the R33 device/app/helper scopes,
matching Steam/PRoot/webhelper/X11 processes, and port 6077 are gone; restore
Termux settings byte-for-byte; verify both rooted rollback paths; and record
post-cleanup free space.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents may be read, copied,
backed up, committed, or exported.

The Vulkan selector contract is grounded in the
[Khronos loader documentation](https://github.com/KhronosGroup/Vulkan-Loader/blob/main/docs/LoaderDriverInterface.md);
the sister repository remains comparison-only, not a component source.
