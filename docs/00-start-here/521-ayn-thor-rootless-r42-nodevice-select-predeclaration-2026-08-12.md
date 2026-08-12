# AYN Thor rootless R42 Mesa device-select isolation — predeclaration — 2026-08-12

Run identity: `thor-rootless-r42-nodevice-select-20260812T151500Z`
Sub-run: `R42-rootless-nodevice-select-layer-isolation`
Status: predeclared as the single next A/B after [doc 520](520-ayn-thor-rootless-r41-patched-proot-crash-trace-result-2026-08-12.md).

## Question and one controlled change

R41 retained the verified SteamClientTermux patched PRoot and reached the
same post-`vkCreateDevice` signal 11. Its Vulkan loader log shows the Holo
`VK_LAYER_MESA_device_select` implicit layer being loaded, followed by:

```text
Failed to find vkGetDeviceProcAddr in layer "libVkLayer_MESA_device_select.so"
vkCreateDevice layer callstack setup to:
```

The preserved layer manifest declares `NODEVICE_SELECT=1` as its disable
environment variable. R42 isolates only that observed layer interaction. It
does not assume that the layer is the cause.

The only changed guest variable relative to R41 is:

```text
export NODEVICE_SELECT=1
```

Keep R41’s outer `PROOT_CRASH_LOG=1` diagnostic, patched PRoot and loader,
client fixture, Holo rootfs, provider, SteamRT-first library ordering, direct
TCP Termux:X11, fresh app-owned state, and Steam flags fixed. Do not add any
other Mesa/WSI variable or sibling helper.

## Device and fresh scopes

```text
device_model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
app_selinux=u:r:runas_app:s0:c138,c256,c512,c768
rootless_guest_mode=PRoot -0
```

Use fresh scopes:

```text
/data/local/tmp/thor-rootless-r42-nodevice-select-20260812T151500Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r42/
/data/data/com.termux/files/home/.nova-rootless-r42/
```

Reuse only verified immutable payloads. Steam HOME, mutable Steam state,
logs, resolver, temporary directories, X11 PID/listener, screenshots, and
readiness baselines must be fresh. Preserve and verify untouched:

```text
/data/local/tmp/nova-runtimes/nova-holo-direct-x11-20260810-v4/rootfs
/data/local/tmp/nova-active-runtime
```

Use the current-tree public client fixture and R41 provenance exactly as
recorded in [doc 520](520-ayn-thor-rootless-r41-patched-proot-crash-trace-result-2026-08-12.md):

```text
public_client_archive_bytes=3757731328
public_client_archive_sha256=97c3140d75c551953c915fb8e06b4ec51c18b2cc32ec4af620ad64df62a77548
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
steamrtarm64/steamwebhelper=7a65e4f7c89dd2eeb0668f85ea0a06cf737507b7f3324407e5fc9a9a488c31d0
installed_manifest=4dfe9a40aad3b2362d00961f2f23785745d4e77e59552b7f148c54c20f79d5c7
holo_archive_sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
patched_proot_sha256=0378e0631dbf7a8bd0061b54fc167bb881c70a76109f567b682f7262a063166c
patched_loader_sha256=eab6b2135421a2e0268832cf171d877146a9e816d7b060ce425e5017d65f08a6
kgsl_driver_sha256=a5769c8573cc61e08fb6e49e2d32329c2330d00d4501baefe12c1fd23162b810
kgsl_icd_sha256=337c752f464fd36a1c9214e68daa9e3a0133f9172a9fd9917632fe2d19856d70
```

## Fixed launch contract

Keep the R41 launch contract exactly, including direct TCP Termux:X11 with a
fresh `:77` instance and TCP listener 6077, app-UID PRoot `-0`, `/dev` and
`/proc` bindings, resolver handling, app-owned `/tmp`, nested client layout,
and these Steam flags:

```text
-gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -cef-disable-gpu -nobootstrapperupdate -skipinitialbootstrap -no-child-update-ui
```

Effective guest environment:

```text
HOME=/opt/nova-steam/home
USER=steam
LOGNAME=steam
LANG=C
LC_ALL=C
XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
DISPLAY=127.0.0.1:77
PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin
LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio
VK_DRIVER_FILES=/opt/nova-kgsl-driver/freedreno-kgsl.icd.json
VK_LOADER_DEBUG=all
NODEVICE_SELECT=1
unset VK_ICD_FILENAMES LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH
```

The outer app-UID PRoot invocation must continue to use the patched PRoot and
loader directly with `PROOT_CRASH_LOG=1`. Do not add `NODEVICE_SELECT` to the
outer environment; it is the single guest Steam environment change.

Do not add `/dev/shm`, D-Bus, machine-id, software GL, `LD_PRELOAD`,
`MESA_LOADER_DRIVER_OVERRIDE`, `GALLIUM_DRIVER`, `LIBGL_ALWAYS_SOFTWARE`,
implicit-layer path changes, Runtime 4, Proton, FEX/DXVK, Gamescope,
AHardwareBuffer, SteamUI patches, input/audio helpers, UID/GID changes, or a
privileged Steam launch.

## Preflight and evidence

Before launch, verify the Thor serial, API, ABI, app UID, app SELinux identity,
free space, exact fresh scopes, immutable payload hashes, patched PRoot/loader
hashes, log-consent state, inner and outer identities, exact command and
environment, fresh Termux:X11 PID, TCP 6077 listener, and read-only
`/dev/kgsl*` metadata. Do not accept an unseen or ambiguous Android log
consent dialog through blind input; if it is absent, record
`log_access_consent=not-shown`.

Capture fresh supervisor and Steam/bootstrap logs, Vulkan loader evidence,
SteamUI/webhelper logs, Termux:X11 log, process/listener state, screenshot,
and the patched PRoot crash trace. Preserve the R41 classification order:

1. Wrong device, hash, scope, freshness, environment, authentication
   boundary, or conventional-layout mismatch invalidates the run.
2. If disabling the layer removes the crash and Steam progresses, record the
   layer interaction as the nearest causal boundary, while keeping Vulkan
   enumeration separate from presentation.
3. If the layer is absent and the same post-`vkCreateDevice` signal 11
   remains, classify the layer as not sufficient to explain the crash.
4. If the layer still loads despite `NODEVICE_SELECT=1`, classify the selector
   as ineffective and do not draw a causal conclusion.
5. Any later SteamUI, webhelper, `/dev/shm`, D-Bus, display, OOBE, or frame
   progress must be recorded separately; survival is not presentation proof.

Do not infer KGSL or SELinux denial from pathname visibility. Do not run a
device ioctl probe, chmod/chown a node, alter SELinux, or launch Steam through
`su`.

## Cleanup and authentication boundary

After capture, stop only the exact R42 Steam/PRoot/X11 processes, remove only
the three R42 scopes and run-specific helper files, verify no matching process
or TCP 6077 listener remains, and verify both preserved rooted rollback paths.
Never broad-kill Termux, clear app data, delete
`/data/local/tmp/nova-active-runtime`, or touch the preserved rooted runtime.

No Steam authentication secret, session token, cookie, QR state,
machine-auth file, authenticated Steam home, or `steam.token` contents may be
read, copied, backed up, committed, or exported.
