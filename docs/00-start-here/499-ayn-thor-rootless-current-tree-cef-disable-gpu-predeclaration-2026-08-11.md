# AYN Thor rootless current-tree CEF GPU-disable diagnostic — predeclaration — 2026-08-11

Run identity: `thor-rootless-current-tree-cef-disable-gpu-20260811T221304Z`;
sub-run: `R34-current-tree-cef-disable-gpu`.

Status: predeclared as the single next experiment after [doc
498](498-ayn-thor-rootless-current-tree-post-bootstrap-vk-loader-debug-result-2026-08-11.md).
It is a launch-flag A/B only. It is not a `/dev/shm`, D-Bus,
provider-complete, software-GL, Runtime 4, Proton, Gamescope/AHardwareBuffer,
or SteamUI patch experiment.

## Question and one changed variable

R33 proved that rootless can use the configured `VK_DRIVER_FILES` selector,
load the pinned Turnip ICD, and enumerate the Thor's Adreno 740. It then
crashed immediately after entering the Vulkan device-use path, before
SteamUI/webhelper. The rooted known-good path reached OOBE with
`-cef-disable-gpu` and software GL controls. SteamClientTermux also keeps
software CEF for the Steam interface while retaining Turnip for games.

The hypothesis for R34 is deliberately limited:

> Adding only `-cef-disable-gpu` may avoid the CEF/UI GPU-compositing path that
> is implicated by the rooted comparator and sibling prior art, allowing the
> same rootless client to reach native SteamUI. This is not proof that CEF is
> the R33 crash site; if the crash remains, the failure is elsewhere in the
> Vulkan device-use/Turnip/PRoot path or another unmeasured prerequisite.

R34 changes exactly one thing relative to R33:

```text
added Steam flag: -cef-disable-gpu
```

Keep every R33 environment variable and artifact fixed. In particular, do not
add `LIBGL_ALWAYS_SOFTWARE`, `MESA_LOADER_DRIVER_OVERRIDE`,
`GALLIUM_DRIVER`, `LIBGL_DRIVERS_PATH`, `TU_DEBUG`, WSI tuning,
`LD_PRELOAD`, `/dev/shm`, D-Bus, machine-id, Runtime 4, Proton, FEX,
Gamescope, an Android permission, a UID change, a PRoot change, or a
client/rootfs/provider/X11 lifecycle change.

## Fixed device, state, and scopes

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

Use fresh app-owned Steam state, logs, screenshots, X11 state, sockets, and
readiness baselines. Do not reuse R33's process, log tail, X11 server, port,
screenshot, or readiness result. Use these exact run scopes:

```text
/data/local/tmp/thor-rootless-current-tree-cef-disable-gpu-20260811T221304Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r34-current-tree/
/data/data/com.termux/files/home/.nova-rootless/
```

Preserve and verify untouched:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

No authenticated Steam home or Steam credential/session data may be read or
copied. Recreate only the sanitized public client and fresh app-owned state.

## Fixed artifacts

Require the same verified R33 fixture:

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
proot_loader_sha256=44ef39c1e1a18c09f6e4c4b5d6f8bba82d30596598bd155ec162d05c5122ff04a
```

Reverify the selected loader and the client font before launch. Keep
`/opt/nova-kgsl-driver/libvulkan_freedreno.so` and
`/opt/nova-kgsl-driver/freedreno-kgsl.icd.json` at the same guest paths and
hashes as R33.

## Fixed launch contract

Retain the R33 environment exactly:

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
unset VK_ICD_FILENAMES
VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
VK_LOADER_DEBUG=all
unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_DRIVER_PATH
```

Use the same Steam command with only the declared flag added:

```text
/opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -cef-disable-gpu -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui
```

Keep app-UID PRoot `-0`, the existing `/dev` and `/proc` binds, fresh
resolver, direct TCP Termux:X11 on display `127.0.0.1:77`, and the existing
supervisor. Do not add `-fullscreen` or `-fulldesktopres`; those belonged to
the rooted comparator and would add a second display variable.

## Evidence and decision

Capture before launch:

- branch, HEAD, device identity, app UID and SELinux identity;
- all fixed artifact and selected-loader hashes;
- fresh free space, exact scopes, and read-only `/dev/kgsl*` metadata;
- exact effective environment and command;
- fresh Termux:X11 PID, version/commit, port 6077, xprop handshake, and
  whether the Android log-consent dialog is shown.

Capture from this run:

- updater/client handoff and process lifetime;
- Vulkan loader/provider/device evidence;
- `vgui2_s`, SteamUI, and `steamwebhelper` milestones;
- any `/dev/shm` or D-Bus messages that occur naturally, without adding either
  prerequisite;
- process/maps, X11 log, listener state, and a screenshot described by what is
  actually visible.

Classify only the observed boundary:

1. If SteamUI/webhelper progresses beyond R33's crash, record that
   `-cef-disable-gpu` changed the boundary. Do not claim that software GL,
   `/dev/shm`, D-Bus, WSI, or OOBE is solved.
2. If the same signal-11 boundary remains, classify the flag as insufficient
   and keep the failure open between Steam's Vulkan device-use path, Turnip,
   PRoot, and a later unmeasured contract. Do not infer a rootless UID or
   SELinux cause without fresh denial/access evidence.
3. If the flag changes the loader/provider trace before device creation, record
   that as an interaction with the Steam graphics initialization path; do not
   retrofit additional variables into R34.
4. If updater or fixture infrastructure fails, classify the run invalid and do
   not draw a graphics conclusion.

## Cleanup and authentication boundary

Run the exact-scope cleanup helper before launch and on every exit. Terminate
only the verified R34 X11 PID, remove only the R34 device/app/helper scopes,
restore Termux settings byte-for-byte, verify no matching process or 6077
listener remains, and verify both rooted rollback paths. Do not broad-kill
Termux, clear package data, delete the rooted runtime, or remove
`/data/local/tmp/nova-active-runtime`.

No Steam authentication secret, session token, cookie, QR state, machine-auth
file, authenticated Steam home, or `steam.token` contents may be read, copied,
backed up, committed, or exported.
