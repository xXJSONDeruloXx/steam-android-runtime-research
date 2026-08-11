# AYN Thor rootless exact public-beta client replay — predeclaration — 2026-08-11

Run identity: `thor-rootless-exact-public-beta-replay-20260811T185704Z`;
sub-run: `Thor-rootless-exact-public-beta-client-baseline`.

Status: predeclared after the stable-payload replay and rooted OOBE
comparison. This is a client-baseline restoration experiment, not R31 and not
a Vulkan/provider, `/dev/shm`, D-Bus, Runtime 4, Proton, Gamescope,
AHardwareBuffer, SteamUI-patch, or packaging experiment.

## Question and single variable

Doc 485 reproduced `vgui2_s` with the public stable ARM64 payload. Rootless
R28 and the rooted Thor comparator both use the different sanitized public-beta
client and cross that native SteamUI boundary. The narrow question is whether
Thor rootless can reproduce the known-good R28 boundary when only the client
payload is restored.

Only the sanitized public client tree changes relative to doc 485. Keep the
Holo rootfs, package closure, PRoot binary/loader, nested client layout, fresh
app-owned state, short temporary paths, inherited Android network, direct TCP
Termux:X11, provider-file presence, exact environment, and Steam flags fixed.

Do not import any rooted-only service or helper in this replay. In particular,
do not add `LD_PRELOAD`, software-GL variables, `VK_ICD_FILENAMES`,
`VK_DRIVER_FILES`, `/dev/shm`, a machine-id, D-Bus, an input/audio bridge,
Runtime 4, Proton, Gamescope, AHardwareBuffer, or a SteamUI patch.

## Exact client gate

The client must be the sanitized public-beta archive recovered and verified in
the project record:

```text
archive_bytes=3447515136
archive_sha256=4c62a8e35144b653864c31d84e682814a82384c3746001293e019d98bde25288
steamrtarm64/steam=6d6c94ef1c8a4d5710bdfac8281090e67b8ef0ea756925daca9ad82c1a024ddf
steamrtarm64/steamui.so=69d93a2eae6ff1c6030c2cadf30ca7612b3960a5c6c71bdeb7224ce416325171
steamrtarm64/vgui2_s.so=aba9a319c608c64545eb94ca8521349e2dde4d51f0e5e6e3b5bd77db4b10c87e
```

The Holo rootfs remains:

```text
bytes=384971555
sha256=7e3fb88454e1ac633b7488abb72d3ca0cc7d2578a38146fdd7d58b50fcbd60bf
closure=161 Holo UI/audio packages
```

The pinned provider files may remain staged for parity, but both selectors
must remain unset:

```text
unset VK_ICD_FILENAMES VK_DRIVER_FILES
unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH
```

## Thor scopes and fresh-state contract

Target device:

```text
model=AYN Thor
device=kalama
serial=d234a848
android_api=33
abi=arm64-v8a
app_uid=10138
```

Use fresh scopes, not doc 485 state:

```text
/data/local/tmp/thor-rootless-exact-public-beta-replay-20260811T185704Z/
/data/user/0/com.xjsonderulo.steamandroid.novalab/files/r35/
/data/data/com.termux/files/home/.nova-rootless-r35/
```

Only verified immutable payloads may be reused. Recreate Steam HOME,
Steam mutable state, logs, resolver, temporary directories, X11 process,
listener, screenshots, and readiness baselines. Do not read, copy, or search
authentication files. If the current APK bridge again uses its default
Termux helper scope, record that fact and remove only the exact files it
created.

## Exact guest command

Keep doc 485's rootless command unchanged apart from the selected client tree:

```text
export HOME=/opt/nova-steam/home
export USER=steam
export LOGNAME=steam
export LANG=C
export LC_ALL=C
export XDG_RUNTIME_DIR=/tmp/nova-steam-runtime
export PATH=/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/bin:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/bin:/usr/bin:/bin
export LD_LIBRARY_PATH=/opt/nova-steam/home/.local/share/Steam/steamrtarm64:/opt/nova-steam/home/.local/share/Steam/lib/aarch64-linux-gnu:/usr/lib:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu:/opt/nova-steam/home/.local/share/Steam/steam-runtime-steamrt-arm64/steamrt3c_platform_3c.0.20260714.251839/files/lib/aarch64-linux-gnu/pulseaudio
unset LD_PRELOAD MESA_LOADER_DRIVER_OVERRIDE GALLIUM_DRIVER LIBGL_ALWAYS_SOFTWARE VK_IMPLICIT_LAYER_PATH VK_ICD_FILENAMES VK_DRIVER_FILES
mkdir -p "$XDG_RUNTIME_DIR"
cd /opt/nova-steam/home/.local/share/Steam
exec /opt/nova-steam/home/.local/share/Steam/steamrtarm64/steam -gamepadui -steamos3 -steampal -steamdeck -no-cef-sandbox -skipinitialbootstrap -no-child-update-ui
```

Use fresh `DISPLAY=127.0.0.1:77`, a fresh Termux:X11 server and TCP 6077
listener, the app-UID PRoot `-0`, `/dev` and `/proc` bindings, and the same
resolver handling as doc 485. Handle the device-log consent gate only if it is
actually shown; verify its text and choose one-time access, never persistent
all-device-log access.

## Evidence and decision

Before launch, record exact archive/tree hashes, rootfs/provider hashes,
preflight, free space, effective environment, command, app UID/SELinux
identity, inner PRoot identity, X11 PID/listener, and fresh process baselines.
Capture Steam/bootstrap/update-UI/native SteamUI/webhelper logs, targeted
loader evidence, screenshot provenance, and read-only `/dev/kgsl*` metadata.

Classify in this order:

1. Any client/hash/device/scope/environment mismatch is invalid, not a
   negative result.
2. If `vgui2_s` remains, classify the R34 stable-to-R35 client change as
   insufficient and stop at a client-loader differential; do not infer
   Vulkan, WSI, `/dev/shm`, or D-Bus.
3. If `vgui2_s` remains absent and native SteamUI/webhelper starts, record the
   R28 baseline as restored. Any later Vulkan or webhelper failure is a
   separate boundary.
4. If a visible Steam OOBE frame appears, record it without retaining QR or
   other authentication-bearing screenshots.

After capture, terminate only the exact fresh X11/Steam/PRoot scope, restore
any authorized Termux preference edit, remove only the three R35 scopes and
exact helper PID/log files, verify no matching process or TCP 6077 listener,
and verify the preserved rooted runtime paths. The next selector experiment,
if this baseline passes, remains the existing Thor R31
`VK_DRIVER_FILES`-only predeclaration in [doc 475](475-ayn-thor-rootless-r31-vk-driver-files-replication-predeclaration-2026-08-11.md).

No Steam authentication secret, session token, cookie, QR state, or
authenticated Steam home may be read, copied, backed up, committed, or
exported.
